import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

class AppHeaderInfo extends StatelessWidget {
  const AppHeaderInfo({
    Key? key,
    required String title,
    required String label,
  })  : _title = title,
        _label = label,
        super(key: key);

  final String _title;
  final String _label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 16, left: 8, right: 8),
      child: Column(
        children: [
          Text(_title,
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.headline4
                  : AppTheme.appTheme.textTheme.headline4),
          const SizedBox(height: 4),
          Text(_label,
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.bodyText2
                  : AppTheme.appTheme.textTheme.bodyText2),
        ],
      ),
    );
  }
}
