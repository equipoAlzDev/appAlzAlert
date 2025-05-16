import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'bluetooth_service.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    _bluetoothService.initBluetooth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conexión Bluetooth"),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          ValueListenableBuilder<Map<String, dynamic>>(
            valueListenable: _bluetoothService.statusNotifier,
            builder: (context, status, _) {
              if (status['status'] == "Conectado a al dispositivo") {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _bluetoothService.disconnectDevice,
                  tooltip: "Desconectar",
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: _bluetoothService.statusNotifier,
              builder: (context, status, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      status['status'] == "Buscando dispositivo..." ||
                              status['status'] == "Conectando..."
                          ? const CircularProgressIndicator()
                          : Icon(
                            status['status'] == "Conectado a al dispositivo"
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            size: 80,
                            color: status['color'],
                          ),
                );
              },
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: _bluetoothService.statusNotifier,
              builder: (context, status, _) {
                return Text(
                  status['status'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: status['color'],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: _bluetoothService.statusNotifier,
              builder: (context, status, _) {
                if (status['status'] == "Conectado a al dispositivo") {
                  return Text(
                    "Dispositivo: ${_bluetoothService.deviceName}",
                    style: const TextStyle(fontSize: 16),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 40),
            ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: _bluetoothService.statusNotifier,
              builder: (context, status, _) {
                return ElevatedButton(
                  onPressed:
                      status['status'] == "Conectado a al dispositivo"
                          ? null
                          : () => _bluetoothService.initBluetooth(),
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
                    status['status'] == "Conectado a al dispositivo"
                        ? "Conectado"
                        : "Buscar dispositivo",
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // No es necesario limpiar aquí, ya que BluetoothService es un singleton
    super.dispose();
  }
}
