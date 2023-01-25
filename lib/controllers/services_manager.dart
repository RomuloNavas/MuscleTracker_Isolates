import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

class GetxControllerServices extends GetxController {
  bool? isBluetoothEnable;

  Future<bool?> checkIfBluetoothIsEnabled() async {
    final currentBluetoothStatus =
        isBluetoothEnable = await FlutterBluetoothSerial.instance.isEnabled;
    return currentBluetoothStatus;
  }

  void requestBluetoothAndGPS() {
    requestBluetooth();
    Timer(const Duration(seconds: 3), requestGPS);
  }

  void requestBluetooth() async {
    try {
      if (isBluetoothEnable == false || isBluetoothEnable == null) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }
    } catch (e) {
      throw ErrorDescription('Error enabling Bluetooth $e');
    }
  }

  void requestGPS() async {
    try {
      await Location.instance.requestPermission();
      await Location.instance.requestService();
    } catch (e) {
      await Geolocator.openLocationSettings();
      // throw ErrorDescription('Error enabling the GPS $e');
    }
  }
}
