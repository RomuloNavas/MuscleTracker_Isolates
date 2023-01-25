import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';

Color buildColorFromCallibriColorType(CallibriColorType callibriColorType) {
  late Color color;
  switch (callibriColorType) {
    case CallibriColorType.white:
      color = Colors.grey;
      break;
    case CallibriColorType.red:
      color = Colors.red;
      break;
    case CallibriColorType.blue:
      color = Colors.blue;
      break;
    case CallibriColorType.yellow:
      color = Colors.yellow;
      break;
    default:
      color = Colors.grey;
  }
  return color;
}

Color buildColorFromSensorName({required String rawSensorNameAndColor}) {
  String sensorColor =
      buildColorNameFromSensor(rawSensorNameAndColor: rawSensorNameAndColor);
  late Color color;
  switch (sensorColor) {
    case 'white':
      color = Colors.grey;
      break;
    case 'red':
      color = Colors.red;
      break;
    case 'blue':
      color = Colors.blue;
      break;
    case 'yellow':
      color = Colors.yellow;
      break;
    default:
      color = Colors.grey;
  }
  return color;
}

/// Provide any string that contains the sensor's color, returns just the color:
///
/// `Callibri_Blue` -> blue
///
/// `CallibriColorType_Blue` -> blue
///
/// `Callibri Blue` -> blue
///
/// `Callibri.Blue` -> blue
///
String buildColorNameFromSensor({required String rawSensorNameAndColor}) {
  String sensorColor = 'empty';

  rawSensorNameAndColor = rawSensorNameAndColor.toLowerCase();
  if (rawSensorNameAndColor.contains('yellow')) {
    sensorColor = 'yellow';
  }
  if (rawSensorNameAndColor.contains('blue')) {
    sensorColor = 'blue';
  }
  if (rawSensorNameAndColor.contains('red')) {
    sensorColor = 'red';
  }
  if (rawSensorNameAndColor.contains('white')) {
    sensorColor = 'white';
  }
  return sensorColor;
}

String buildCallibriNameFromSensor({required String rawSensorNameAndColor}) {
  String callibriName =
      'callibri ${buildColorNameFromSensor(rawSensorNameAndColor: rawSensorNameAndColor)}';
  return callibriName;
}
