import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _targetCharacteristic;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionSubscription;
  Timer? _locationTimer;
  final ValueNotifier<Map<String, dynamic>> _statusNotifier = ValueNotifier({
    'status': 'Desconectado',
    'color': Colors.red,
  });
  Position? _lastKnownPosition;
  DateTime? _lastUpdateTime;
  final Duration _updateInterval = Duration(
    minutes: 5,
  ); // Intervalo para actualizar desde GPS
  final Random _random = Random();

  ValueNotifier<Map<String, dynamic>> get statusNotifier => _statusNotifier;

  String get deviceName =>
      _connectedDevice != null && _connectedDevice!.name.isNotEmpty
          ? _connectedDevice!.name
          : 'Dispositivo Desconocido';

  Future<void> initBluetooth() async {
    try {
      bool isBluetoothOn = await fbp.FlutterBluePlus.isOn;
      if (!isBluetoothOn) {
        await fbp.FlutterBluePlus.turnOn();
        isBluetoothOn = await fbp.FlutterBluePlus.isOn;
        if (!isBluetoothOn) {
          _updateStatus("No se pudo encender Bluetooth", Colors.orange);
          return;
        }
      }
      await _loadLastKnownPosition(); // Cargar última ubicación al iniciar
      await _scanDevices();
    } catch (e) {
      _updateStatus("Error inicializando Bluetooth", Colors.red);
      debugPrint("Error initBluetooth: $e");
    }
  }

  Future<void> _scanDevices() async {
    if (_connectedDevice != null) return;

    try {
      _updateStatus("Buscando dispositivo...", Colors.blue);

      await fbp.FlutterBluePlus.stopScan();

      final subscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          if (result.device.name == "ESP32_BLUETOOTH" &&
              _connectedDevice == null) {
            _connectToDevice(result.device);
            break;
          }
        }
      });

      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      await Future.delayed(const Duration(seconds: 12));

      await fbp.FlutterBluePlus.stopScan();
      await subscription.cancel();

      if (_connectedDevice == null) {
        _updateStatus("Dispositivo no encontrado", Colors.red);
      }
    } catch (e) {
      _updateStatus("Error en escaneo", Colors.red);
      debugPrint("Error _scanDevices: $e");
    }
  }

  Future<void> _connectToDevice(fbp.BluetoothDevice device) async {
    try {
      _updateStatus("Conectando...", Colors.blue);

      await _connectionSubscription?.cancel();

      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );

      _connectionSubscription = device.connectionState.listen((state) async {
        if (state == fbp.BluetoothConnectionState.connected) {
          _updateStatus("Conectado a al dispositivo", Colors.green);
          _connectedDevice = device;
          await _discoverServices(device);
          _startLocationTimer();
        } else if (state == fbp.BluetoothConnectionState.disconnected) {
          _updateStatus("Desconectado", Colors.red);
          _connectedDevice = null;
          _targetCharacteristic = null;
          _stopLocationTimer();
        }
      });
    } catch (e) {
      _updateStatus("Error de conexión", Colors.red);
      debugPrint("Error _connectToDevice: $e");
      _connectedDevice = null;
      _targetCharacteristic = null;
      _stopLocationTimer();
    }
  }

  Future<void> _discoverServices(fbp.BluetoothDevice device) async {
    try {
      List<fbp.BluetoothService> services = await device.discoverServices();
      debugPrint("Servicios descubiertos: ${services.length}");
      for (var service in services) {
        String serviceUuid = service.uuid.toString().toLowerCase();
        debugPrint("Servicio UUID: $serviceUuid");
        for (var characteristic in service.characteristics) {
          String charUuid = characteristic.uuid.toString().toLowerCase();
          debugPrint("  Característica UUID: $charUuid");
          debugPrint(
            "  Propiedades: notify=${characteristic.properties.notify}, write=${characteristic.properties.write}",
          );
        }
        if (serviceUuid == "00001234-0000-1000-8000-00805f9b34fb" ||
            serviceUuid == "1234") {
          debugPrint("Servicio encontrado: $serviceUuid");
          for (var characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();
            if (charUuid == "00005678-0000-1000-8000-00805f9b34fb" ||
                charUuid == "5678") {
              debugPrint("Característica encontrada: $charUuid");
              _targetCharacteristic = characteristic;
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                characteristic.value.listen((value) {
                  if (value.isNotEmpty) {
                    // String receivedData = String.fromCharCodes(value);
                    // debugPrint("Dato recibido: $receivedData");
                    // _updateStatus("Recibido: $receivedData", Colors.green);
                  }
                });
              }
              return;
            }
          }
          debugPrint("Característica no encontrada en servicio $serviceUuid");
          _updateStatus("Característica no encontrada", Colors.orange);
          return;
        }
      }
      debugPrint("Servicio no encontrado");
      _updateStatus("Servicio no encontrado", Colors.orange);
    } catch (e) {
      debugPrint("Error _discoverServices: $e");
      _updateStatus("Error descubriendo servicios", Colors.red);
    }
  }

  Future<void> _sendData(String data) async {
    try {
      if (_connectedDevice == null) {
        _updateStatus("No hay dispositivo conectado", Colors.orange);
        return;
      }

      if (_targetCharacteristic == null) {
        debugPrint("Característica no disponible, intentando redescubrir");
        await _discoverServices(_connectedDevice!);
        if (_targetCharacteristic == null) {
          _updateStatus("Característica no encontrada", Colors.orange);
          return;
        }
      }

      debugPrint("Enviando dato: $data");
      await _targetCharacteristic!.write(data.codeUnits);
      // debugPrint("Dato enviado exitosamente: $data");
      if (!data.startsWith("LAT:") || !data.contains(",LON:")) {
        _updateStatus("Enviado: $data", Colors.green);
      }
    } catch (e) {
      debugPrint("Error _sendData: $e");
      _updateStatus("Error enviando datos", Colors.red);
    }
  }

  // Cargar última ubicación desde SharedPreferences
  Future<void> _loadLastKnownPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_lat');
    final lon = prefs.getDouble('last_lon');
    final lastUpdate = prefs.getString('last_update');

    if (lat != null && lon != null && lastUpdate != null) {
      final updateTime = DateTime.parse(lastUpdate);
      if (DateTime.now().difference(updateTime).inMinutes <
          _updateInterval.inMinutes) {
        _lastKnownPosition = Position(
          latitude: lat,
          longitude: lon,
          timestamp: updateTime,
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0, // Corregido: parámetro requerido
          headingAccuracy: 0.0, // Corregido: parámetro requerido
        );
        _lastUpdateTime = updateTime;
      }
    }
  }

  // Obtener ubicación, preferiblemente desde almacenamiento
  Future<Position?> _getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Verificar si la última ubicación es reciente
    if (_lastKnownPosition != null &&
        _lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inMinutes <
            _updateInterval.inMinutes) {
      return _lastKnownPosition;
    }

    // Verificar permisos y servicio de ubicación
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _updateStatus("Servicio de ubicación desactivado", Colors.orange);
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _updateStatus("Permiso de ubicación denegado", Colors.red);
        return null;
      }
    }

    try {
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastUpdateTime = now;

      // Guardar la ubicación en SharedPreferences
      await prefs.setDouble('last_lat', _lastKnownPosition!.latitude);
      await prefs.setDouble('last_lon', _lastKnownPosition!.longitude);
      await prefs.setString('last_update', now.toIso8601String());

      return _lastKnownPosition;
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
      _updateStatus("Error obteniendo ubicación", Colors.red);
      return null;
    }
  }

  // Generar variación aleatoria en latitud y longitud
  double _addRandomVariation(double value) {
    // Variación aleatoria entre -0.0001 y 0.0001 (aprox. ±11 metros)
    double variation = (_random.nextDouble() * 0.0002) - 0.0001;
    return value + variation;
  }

  Future<void> _sendLocation() async {
    try {
      Position? position = await _getLocation();
      if (position == null) {
        return;
      }

      // Aplicar variación aleatoria a la ubicación
      double lat = _addRandomVariation(position.latitude);
      double lon = _addRandomVariation(position.longitude);

      String locationData =
          "LAT:${lat.toStringAsFixed(6)},LON:${lon.toStringAsFixed(6)}";
      await _sendData(locationData);
    } catch (e) {
      debugPrint("Error enviando ubicación: $e");
      _updateStatus("Error enviando ubicación", Colors.red);
    }
  }

  void _startLocationTimer() {
    _stopLocationTimer();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectedDevice != null) {
        _sendLocation();
      } else {
        _stopLocationTimer();
      }
    });
  }

  void _stopLocationTimer() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> disconnectDevice() async {
    try {
      if (_connectedDevice != null) {
        await _connectionSubscription?.cancel();
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _targetCharacteristic = null;
        _updateStatus("Desconectado", Colors.red);
        _stopLocationTimer();
      }
    } catch (e) {
      debugPrint("Error _disconnectDevice: $e");
    }
  }

  void _updateStatus(String status, Color color) {
    _statusNotifier.value = {'status': status, 'color': color};
  }
}
