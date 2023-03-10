import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

class GetxControllerServices extends GetxController {
  bool? isBluetoothEnable;

  Future<bool> areRequiredServicesEnabled() async {
    bool isLocationEnabled = await Location.instance.serviceEnabled();
    bool? isBluetoothEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    return isLocationEnabled && isBluetoothEnabled == true;
  }

  Future<void> requestServices() async {
    await requestBluetooth();
    Timer(const Duration(milliseconds: 1250), requestGPS);
  }

  Future<void> requestBluetooth() async {
    try {
      if (isBluetoothEnable == false || isBluetoothEnable == null) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }
    } catch (e) {
      throw ErrorDescription('Error enabling Bluetooth $e');
    }
  }

  void requestGPS() async {
    PermissionStatus? hasPermission;
    try {
      hasPermission = await Location.instance.hasPermission();
      if (hasPermission == PermissionStatus.denied ||
          hasPermission == PermissionStatus.deniedForever) {
        try {
          await Location.instance.requestPermission();
        } catch (e) {
          log(e.toString());
        }
      }
    } catch (e) {
      log(e.toString(), name: 'services_manager - requestGPS');
    }
    if (hasPermission == PermissionStatus.granted ||
        hasPermission == PermissionStatus.grantedLimited) {
      try {
        bool isLocationEnabled = await Location.instance.serviceEnabled();
        if (isLocationEnabled == false) {
          try {
            await Geolocator.openLocationSettings();
          } catch (e) {
            log('Error by opening location settings');
          }
        }
      } catch (e) {
        log('Error by asking for permissions');
      }
    }
  }
}
