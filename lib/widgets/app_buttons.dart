import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import '../theme.dart';

enum ButtonSize {
  small,
  medium,
  big,
}

enum ButtonType {
  textButton,
  outlinedButton,
  filledButton,
}

class AppFilledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const AppFilledButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(0, 48)),
        shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))),
        foregroundColor: MaterialStateProperty.all(Colors.white), // Text color
        backgroundColor: MaterialStateProperty.all(backgroundColor ??
            (Get.isDarkMode
                ? AppTheme.appDarkTheme.colorScheme.primary
                : AppTheme.appTheme.colorScheme.primary)),

        /// Enable/disable the splash effect
        splashFactory: NoSplash.splashFactory,

        /// Button color on splash
        overlayColor: Get.isDarkMode
            ? MaterialStateProperty.all(lighterColorFrom(
                color: backgroundColor ??
                    (Get.isDarkMode
                        ? AppTheme.appDarkTheme.colorScheme.primary
                        : AppTheme.appTheme.colorScheme.primary)))
            : MaterialStateProperty.all(darkerColorFrom(
                color: backgroundColor ??
                    (Get.isDarkMode
                        ? AppTheme.appDarkTheme.colorScheme.primary
                        : AppTheme.appTheme.colorScheme.primary))),

        side: MaterialStateProperty.all(const BorderSide(
            width: 0,
            color: Colors.transparent)), // Button's border width and color

        shadowColor: MaterialStateProperty.all(
            AppTheme.appTheme.colorScheme.surfaceVariant),
        surfaceTintColor: MaterialStateProperty.all(
            AppTheme.appTheme.colorScheme.surfaceVariant),
      ),
      child: Text(
        text,
        style: Get.isDarkMode
            ? AppTheme.appDarkTheme.textTheme.button
            : AppTheme.appTheme.textTheme.button,
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.colorText,
  }) : super(key: key);

  final String text;
  final VoidCallback onPressed;
  final Color? colorText;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          // Border Color
          side: MaterialStateProperty.all(
              const BorderSide(width: 2, color: Colors.transparent)),
          overlayColor:
              MaterialStateProperty.all(Colors.black.withOpacity(0.05)),
          minimumSize: MaterialStateProperty.all(const Size(0, 48)),
          shadowColor:
              MaterialStateProperty.all(AppTheme.appTheme.primaryColorDark),
          splashFactory: NoSplash
              .splashFactory, //Enable/Disable splash when button is pressed
          // Text color
          foregroundColor: MaterialStateProperty.all(colorText),
          surfaceTintColor:
              MaterialStateProperty.all(AppTheme.appTheme.primaryColorDark),
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0))),
        ),
        child: Text(
          text,
          style: Get.isDarkMode
              ? AppTheme.appDarkTheme.textTheme.button?.copyWith(
                  color: colorText ??
                      (AppTheme.appDarkTheme.colorScheme.secondary),
                )
              : AppTheme.appTheme.textTheme.button?.copyWith(
                  color: colorText ?? (AppTheme.appTheme.colorScheme.secondary),
                ),
        ));
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    Key? key,
    this.svgIconPath,
    this.onPressed,
    this.iconColor,
    this.textColor,
    this.borderColor,
    this.text,
    this.backgroundColor,
    this.size,
    this.buttonType,
  }) : super(key: key);

  final Function()? onPressed;
  final String? text;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? borderColor;
  final String? svgIconPath;
  final ButtonSize? size;
  final ButtonType? buttonType;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        Widget? textButton;
        Widget? button;

        button = ScaleTap(
          onPressed: onPressed,
          scaleMinValue: 0.9,
          opacityMinValue: 0.4,
          scaleCurve: Curves.decelerate,
          opacityCurve: Curves.fastOutSlowIn,
          child: SizedBox(
            width: size == ButtonSize.big
                ? 48
                : size == ButtonSize.medium
                    ? 44
                    : 40,
            height: size == ButtonSize.big
                ? 48
                : size == ButtonSize.medium
                    ? 44
                    : 40,
            child: Center(
              child: svgIconPath != null
                  ? SvgPicture.asset(
                      'assets/icons/ui/$svgIconPath.svg',
                      width: size == ButtonSize.big
                          ? 32
                          : size == ButtonSize.medium
                              ? 24
                              : 20,
                      color: iconColor ??
                          (Get.isDarkMode
                              ? AppTheme.appDarkTheme.colorScheme.tertiary
                              : AppTheme.appTheme.colorScheme.tertiary),
                    )
                  : null,
            ),
          ),
        );

        if (text == null) {
          return button;
        } else {
          return textButton = ScaleTap(
            onPressed: onPressed,
            scaleMinValue: 0.9,
            scaleCurve: Curves.decelerate,
            opacityCurve: Curves.fastOutSlowIn,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              width: size == ButtonSize.big
                  ? 240
                  : size == ButtonSize.medium
                      ? 160
                      : size == ButtonSize.small
                          ? 120
                          : 240,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  width: 2,
                  color:
                      borderColor != null ? borderColor! : Colors.transparent,
                ),
                color:
                    backgroundColor ?? (Theme.of(context).colorScheme.primary),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(text!,
                        style: AppTheme.appDarkTheme.textTheme.button
                            ?.copyWith(color: textColor ?? (Colors.white))),
                    if (svgIconPath != null) const SizedBox(width: 8),
                    if (svgIconPath != null)
                      SvgPicture.asset(
                        'assets/icons/ui/$svgIconPath.svg',
                        width: 24,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
