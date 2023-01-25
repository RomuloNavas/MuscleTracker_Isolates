import 'dart:async';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchController {
  late final Scanner _scanner;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isAllPermissionGranted = false;
  bool get isAllPermissionGranted => _isAllPermissionGranted;

  Stream<List<SensorInfo>> get foundSensorsStream => _scanner.sensorsStream;

  Future<void> init() async {
    await requestPermission();
    _scanner = await Scanner.create([SensorFamily.leCallibri]);
  }

  Future<void> requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    _isAllPermissionGranted = statuses.values.every((status) => status == PermissionStatus.granted);
  }

  Future<List<SensorInfo>> getSensors() async {
    final list = await _scanner.getSensors();

    return list;
  }

  void toggleSearch() {
    if (_isScanning) {
      stopScanner();
      return;
    }

    startScanner();
  }

  void startScanner() {
    if (_isScanning) return;
    _scanner.start();
    _isScanning = true;
  }

  void stopScanner() {
    if (!_isScanning) return;
    _scanner.stop();
    _isScanning = false;
  }

  void dispose() {
    _scanner.stop();
    _scanner.dispose();
  }
}
