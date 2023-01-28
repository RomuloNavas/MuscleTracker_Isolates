import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/build_battery_indicator_icon.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';

class AppDataCellPercentageBox extends StatelessWidget {
  const AppDataCellPercentageBox({
    Key? key,
    required this.value,
    this.cellWidth = 100,
    required this.maxValue,
  }) : super(key: key);
  final double value;
  final double cellWidth;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cellWidth,
      height: 36.0,
      child: Stack(
        children: [
          Container(
            width: cellWidth,
            height: 36.0,
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? lighterColorFrom(
                      color: AppTheme.appDarkTheme.scaffoldBackgroundColor,
                      amount: 0.1)
                  : darkerColorFrom(
                      color: AppTheme.appTheme.scaffoldBackgroundColor,
                      amount: 0.1),
            ),
            alignment: Alignment.centerLeft, // where to position the child
            child: Container(
              width: maxValue > 0.00000009
                  ? calculatePercentageGlobal(
                      widgetWidthValueInPX: cellWidth,
                      currentValue: value,
                      maxValue: maxValue)
                  : cellWidth,
              height: 36.0,
              decoration: BoxDecoration(
                color: maxValue > 0.00000009
                    ? AppTheme.appDarkTheme.hintColor.withOpacity(0.2)
                    : Colors.transparent,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text((value * 1000000).toStringAsFixed(0),
                  style: Get.isDarkMode
                      ? AppTheme.appDarkTheme.textTheme.bodyText1
                      : AppTheme.appTheme.textTheme.bodyText1),
            ),
          ),
        ],
      ),
    );
  }
}
