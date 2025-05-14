import 'dart:async';

import 'package:AlzAlert/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  bool _isScanning = false;
  String _connectionStatus = "Desconectado";
  Color _statusColor = Colors.red;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      bool isBluetoothOn = await FlutterBluePlus.isOn;
      if (!isBluetoothOn) {
        await FlutterBluePlus.turnOn();
        isBluetoothOn = await FlutterBluePlus.isOn;
        if (!isBluetoothOn) {
          _updateStatus("No se pudo encender Bluetooth", Colors.orange);
          return;
        }
        await _checkPermissions();
      } else {
        await _checkPermissions();
      }
    } catch (e) {
      _updateStatus("Error inicializando Bluetooth", Colors.red);
      debugPrint("Error initBluetooth: $e");
    }
  }

  Future<void> _checkPermissions() async {
    try {
      if (await _requestPermissions()) {
        await _scanDevices();
      } else {
        _updateStatus("Permisos denegados", Colors.orange);
      }
    } catch (e) {
      _updateStatus("Error en permisos", Colors.red);
      debugPrint("Error checkPermissions: $e");
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        _updateStatus("Bluetooth no soportado", Colors.orange);
        return false;
      }

      var permissions =
          await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.locationWhenInUse,
          ].request();

      return permissions[Permission.bluetoothScan]?.isGranted == true &&
          permissions[Permission.bluetoothConnect]?.isGranted == true &&
          permissions[Permission.locationWhenInUse]?.isGranted == true;
    } catch (e) {
      debugPrint("Error requestPermissions: $e");
      return false;
    }
  }

  Future<void> _scanDevices() async {
    if (_isScanning) return;

    try {
      _updateStatus("Buscando dispositivo...", Colors.blue);
      _isScanning = true;

      await FlutterBluePlus.stopScan();

      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          if (result.device.name == "ESP32_BLUETOOTH" &&
              _connectedDevice == null) {
            _connectToDevice(result.device);
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      await Future.delayed(const Duration(seconds: 12));

      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      if (_connectedDevice == null) {
        _updateStatus("Dispositivo no encontrado", Colors.red);
      }
    } catch (e) {
      _updateStatus("Error en escaneo", Colors.red);
      debugPrint("Error _scanDevices: $e");
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _updateStatus("Conectando...", Colors.blue);

      await _connectionSubscription?.cancel();

      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );

      _connectionSubscription = device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.connected) {
          _updateStatus("Conectado al dispositivo", Colors.green);
          _connectedDevice = device;
          await _discoverServices(device);
          _startLocationTimer();
        } else if (state == BluetoothConnectionState.disconnected) {
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

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
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
      debugPrint("Dato enviado exitosamente: $data");
      // Solo mostrar "Enviado: ..." para datos que no sean coordenadas
      if (!data.startsWith("LAT:") || !data.contains(",LON:")) {
        _updateStatus("Enviado: $data", Colors.green);
      }
    } catch (e) {
      debugPrint("Error _sendData: $e");
      _updateStatus("Error enviando datos", Colors.red);
    }
  }

  Future<void> _sendLocation() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateStatus("Servicio de ubicación desactivado", Colors.orange);
        return;
      }

      // Obtener la ubicación
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Formatear latitud y longitud
      String locationData =
          "LAT:${position.latitude},LON:${position.longitude}";
      await _sendData(locationData);
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
      _updateStatus("Error obteniendo ubicación", Colors.red);
    }
  }

  void _startLocationTimer() {
    _stopLocationTimer();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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

  Future<void> _disconnectDevice() async {
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
    if (mounted) {
      setState(() {
        _connectionStatus = status;
        _statusColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conexión Bluetooth"),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _disconnectDevice,
              tooltip: "Desconectar",
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  _isScanning
                      ? const CircularProgressIndicator()
                      : Icon(
                        _connectedDevice != null
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        size: 80,
                        color: _statusColor,
                      ),
            ),
            const SizedBox(height: 20),
            Text(
              _connectionStatus,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _statusColor,
              ),
            ),
            const SizedBox(height: 20),
            if (_connectedDevice != null)
              Text(
                "Dispositivo: ${_connectedDevice!.name.isNotEmpty ? _connectedDevice!.name : 'Dispositivo Desconocido'}",
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _connectedDevice != null ? null : _scanDevices,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _connectedDevice != null ? "Conectado" : "Buscar dispositivo",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _stopLocationTimer();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
