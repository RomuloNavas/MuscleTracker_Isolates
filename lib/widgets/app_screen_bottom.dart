import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';

class AppScreenBottom extends StatelessWidget {
  final Function() onPressed;
  final String mainText;
  const AppScreenBottom({
    Key? key,
    required this.onPressed,
    required this.mainText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 12, right: 12),
      child: SizedBox(
        width: MediaQuery.of(context).size.width > 600
            ? MediaQuery.of(context).size.width * 0.65
            : double.infinity,
        child: AppFilledButton(
            onPressed: onPressed,
            child: Text(
              mainText,
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.button
                  : AppTheme.appTheme.textTheme.button,
            )),
      ),
    );
  }
}
