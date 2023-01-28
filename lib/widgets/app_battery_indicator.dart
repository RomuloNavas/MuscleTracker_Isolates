import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/build_battery_indicator_icon.dart';

enum AppBatteryIndicatorLabelPosition { left, top, inside }

class AppBatteryIndicator extends StatelessWidget {
  final AppBatteryIndicatorLabelPosition appBatteryIndicatorLabelPosition;
  final int batteryLevel;
  const AppBatteryIndicator(
      {required this.batteryLevel,
      required this.appBatteryIndicatorLabelPosition,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (appBatteryIndicatorLabelPosition ==
            AppBatteryIndicatorLabelPosition.top)
          Text(
            '$batteryLevel%',
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        Row(
          children: [
            if (appBatteryIndicatorLabelPosition ==
                AppBatteryIndicatorLabelPosition.left)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '$batteryLevel%',
                  style: Get.isDarkMode
                      ? AppTheme.appDarkTheme.textTheme.caption
                      : AppTheme.appTheme.textTheme.caption,
                ),
              ),
            SizedBox(
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
                          color: Get.isDarkMode
                              ? const Color(0xffeeeeee)
                              : Colors.black),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment:
                        Alignment.centerLeft, // where to position the child
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                      width: calculatePercentage(batteryLevel: batteryLevel),
                      height: 10.0,
                      decoration: BoxDecoration(
                        color: batteryLevel > 30
                            ? appBatteryIndicatorLabelPosition ==
                                    AppBatteryIndicatorLabelPosition.inside
                                ? const Color(0xff4bb34b).withOpacity(0.7)
                                : const Color(0xff4bb34b)
                            : appBatteryIndicatorLabelPosition ==
                                    AppBatteryIndicatorLabelPosition.inside
                                ? const Color(0xffff3a2e).withOpacity(0.7)
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
                        color: Get.isDarkMode
                            ? const Color(0xffeeeeee)
                            : Colors.black,
                      ),
                    ),
                  ),
                  if (appBatteryIndicatorLabelPosition ==
                      AppBatteryIndicatorLabelPosition.inside)
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        '$batteryLevel%',
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Get.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }
}
