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

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton(
      {Key? key,
      required this.child,
      required this.action,
      required this.color,
      this.buttonSize})
      : super(key: key);

  final Widget child;
  final VoidCallback action;
  final Color color;
  final ButtonSize? buttonSize;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: action,
      style: ButtonStyle(
        // Border Color
        side: MaterialStateProperty.all(BorderSide(width: 1, color: color)),
        overlayColor: MaterialStateProperty.all(color.withOpacity(0.3)),
        minimumSize: MaterialStateProperty.all(buttonSize == ButtonSize.medium
            ? const Size(0, 32)
            : buttonSize == ButtonSize.big
                ? const Size(0, 48)
                : const Size(0, 16)),
        shadowColor: MaterialStateProperty.all(
            darkerColorFrom(color: color, amount: 0.5)),
        //Color when button is pressed
        // splashFactory: NoSplash.splashFactory,
        // Text color
        foregroundColor: MaterialStateProperty.all(color),
        surfaceTintColor:
            MaterialStateProperty.all(AppTheme.appTheme.primaryColorDark),
        backgroundColor: MaterialStateProperty.all(color.withOpacity(0.3)),
        shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))),
      ),
      child: child,
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
    required VoidCallback onPressed,
    required this.svgIconPath,
    this.iconColor,
    this.text,
    this.backgroundColor,
    this.size,
  })  : _onPressed = onPressed,
        super(key: key);

  final VoidCallback _onPressed;
  final String? text;
  final Color? backgroundColor;
  final Color? iconColor;
  final String svgIconPath;
  final ButtonSize? size;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        Widget? textButton;
        Widget? button;

        button = ScaleTap(
          onPressed: _onPressed,
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
              child: SvgPicture.asset(
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
              ),
            ),
          ),
        );

        if (text == null) {
          return button;
        } else {
          return textButton = ScaleTap(
            onPressed: _onPressed,
            scaleMinValue: 0.9,
            scaleCurve: Curves.decelerate,
            opacityCurve: Curves.fastOutSlowIn,
            child: Container(
              width: 220,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color:
                    backgroundColor ?? (Theme.of(context).colorScheme.primary),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(text!,
                        style: AppTheme.appDarkTheme.textTheme.button
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(width: 8),
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
