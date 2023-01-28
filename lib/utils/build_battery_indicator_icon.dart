import 'package:flutter/material.dart';
import 'package:get/get.dart';

double calculatePercentageGlobal({
  required double widgetWidthValueInPX,
  required double currentValue,
  required double maxValue,
}) {
  double batteryIndicatorWidth = widgetWidthValueInPX;
  batteryIndicatorWidth = currentValue / maxValue * batteryIndicatorWidth;
  return batteryIndicatorWidth;
}

double calculatePercentage({required num batteryLevel}) {
  double batteryIndicatorWidth = 20; //Value in pixels
  batteryIndicatorWidth = batteryLevel / 100 * batteryIndicatorWidth;
  return batteryIndicatorWidth;
}

