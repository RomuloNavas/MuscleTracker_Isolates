import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';

class AppBottom extends StatelessWidget {
  final Function() onPressed;
  final Function()? onSecondaryButtonPressed;
  final String mainText;
  final String? secondaryText;
  final Color? secondaryTextColor;
  const AppBottom({
    Key? key,
    required this.onPressed,
    this.onSecondaryButtonPressed,
    required this.mainText,
    this.secondaryText,
    this.secondaryTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: 12,
          left: 12,
          right: 12,
          bottom: (secondaryText == null) ? 36 : 24),
      child: Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width > 600
                ? MediaQuery.of(context).size.width * 0.65
                : double.infinity,
            child: AppFilledButton(onPressed: onPressed, text: mainText),
          ),
          if (secondaryText != null && onSecondaryButtonPressed != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: MediaQuery.of(context).size.width > 600
                    ? MediaQuery.of(context).size.width * 0.65
                    : double.infinity,
                child: AppTextButton(
                  onPressed: onSecondaryButtonPressed!,
                  text: secondaryText!,
                  colorText: secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
