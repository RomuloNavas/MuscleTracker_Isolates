import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

class AppPopMenuItemChild extends StatelessWidget {
  const AppPopMenuItemChild({
    Key? key,
    required this.title,
    required this.iconData,
    this.iconColor,
  }) : super(key: key);

  final String title;
  final IconData iconData;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          iconData,
          color: iconColor ??
              (Get.isDarkMode
                  ? AppTheme.appDarkTheme.colorScheme.secondary
                  : AppTheme.appTheme.colorScheme.secondary),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: Get.isDarkMode
                ? AppTheme.appDarkTheme.textTheme.bodyText1
                : AppTheme.appTheme.textTheme.bodyText1),
      ],
    );
  }
}
