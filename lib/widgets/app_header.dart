import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

class AppHeaderInfo extends StatelessWidget {
  const AppHeaderInfo({
    Key? key,
    required this.title,
    this.labelPrimary,
    this.labelSecondary,
  }) : super(key: key);
  final String title;
  final String? labelPrimary;
  final String? labelSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(title,
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.headline4
                  : AppTheme.appTheme.textTheme.headline4),
          const SizedBox(height: 4),
          if(labelPrimary != null)
          Text(labelPrimary!,
              textAlign:
                  labelSecondary != null ? TextAlign.start : TextAlign.center,
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.bodyText2
                  : AppTheme.appTheme.textTheme.bodyText2),
          if (labelSecondary != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                labelSecondary!,
                textAlign: TextAlign.center,
                style: Get.isDarkMode
                    ? AppTheme.appDarkTheme.textTheme.caption?.copyWith(
                        color: Color(0xffbfc7cb),
                        fontWeight: FontWeight.w600,
                      )
                    : AppTheme.appTheme.textTheme.caption?.copyWith(
                        color: Color(0xffbfc7cb),
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
