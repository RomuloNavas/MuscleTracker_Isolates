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

Widget buildBatteryIndicatorIcon({required int batteryLevel}) {
  return SizedBox(
    width: 26,
    height: 15.0,
    child: Stack(
      children: [
        Container(
          width: 24.0,
          height: 15.0,
          decoration: BoxDecoration(
            border: Border.all(
                strokeAlign: StrokeAlign.inside,
                color: Get.isDarkMode ? const Color(0xffeeeeee) : Colors.black),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.centerLeft, // where to position the child
          child: Container(
            margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
            width: calculatePercentage(batteryLevel: batteryLevel),
            height: 10.0,
            decoration: BoxDecoration(
              color: batteryLevel > 30
                  ? const Color(0xff4bb34b)
                  : const Color(0xffff3a2e),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0 + (15 / 2 / 2),
          child: Container(
            width: 3,
            height: 15 / 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Get.isDarkMode ? const Color(0xffeeeeee) : Colors.black,
            ),
          ),
        ),
      ],
    ),
  );
}
