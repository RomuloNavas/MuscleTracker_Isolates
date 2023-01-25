import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import '../theme.dart';

class AppFilledButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const AppFilledButton({
    Key? key,
    required this.child,
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

        shadowColor:
            MaterialStateProperty.all(AppTheme.appTheme.highlightColor),
        surfaceTintColor:
            MaterialStateProperty.all(AppTheme.appTheme.highlightColor),
      ),
      child: child,
    );
  }
}

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    Key? key,
    required Widget child,
    required VoidCallback action,
    required Color color,
  })  : _child = child,
        _action = action,
        _color = color,
        super(key: key);

  final Widget _child;
  final VoidCallback _action;

  final Color _color;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: _action,
        style: ButtonStyle(
          // Border Color
          side: MaterialStateProperty.all(BorderSide(width: 2, color: _color)),
          overlayColor: MaterialStateProperty.all(_color.withOpacity(0.5)),
          minimumSize: MaterialStateProperty.all(const Size(0, 48)),
          shadowColor:
              MaterialStateProperty.all(AppTheme.appTheme.primaryColorDark),
          //Color when button is pressed
          splashFactory: NoSplash.splashFactory,
          // Text color
          foregroundColor: MaterialStateProperty.all(_color),
          surfaceTintColor:
              MaterialStateProperty.all(AppTheme.appTheme.primaryColorDark),
          backgroundColor: MaterialStateProperty.all(_color.withOpacity(0.3)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0))),
        ),
        child: _child);
  }
}

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    Key? key,
    required Widget child,
    required VoidCallback action,
    required Color color,
  })  : _child = child,
        _action = action,
        _color = color,
        super(key: key);

  final Widget _child;
  final VoidCallback _action;

  final Color _color;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: _action,
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
          foregroundColor: MaterialStateProperty.all(_color),
          surfaceTintColor:
              MaterialStateProperty.all(AppTheme.appTheme.primaryColorDark),
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0))),
        ),
        child: _child);
  }
}

class AppIconButtonMedium extends StatelessWidget {
  const AppIconButtonMedium({
    Key? key,
    required VoidCallback onPressed,
    required this.iconData,
    this.iconColor,
    this.backgroundColor,
  })  : _onPressed = onPressed,
        super(key: key);

  final VoidCallback _onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (Get.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              iconData,
              size: 22,
              color: iconColor ?? (Color(0xff838997)),
            ),
          ),
        ),
      ),
    );
  }
}

class AppIconButtonBig extends StatelessWidget {
  const AppIconButtonBig({
    Key? key,
    required Widget icon32px,
    required VoidCallback onPressed,
    this.backgroundColor,
  })  : _icon32px = icon32px,
        _onPressed = onPressed,
        super(key: key);

  final Widget _icon32px;
  final VoidCallback _onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _onPressed,
          child: SizedBox(width: 48, height: 48, child: _icon32px),
        ),
      ),
    );
  }
}

class AppIconButtonVeryBig extends StatelessWidget {
  const AppIconButtonVeryBig({
    Key? key,
    required Widget icon40px,
    this.backgroundColor,
    required VoidCallback onPressed,
    String? tooltip,
  })  : _icon40px = icon40px,
        _onPressed = onPressed,
        _tooltip = tooltip,
        super(key: key);

  final Color? backgroundColor;
  final Widget _icon40px;
  final VoidCallback _onPressed;
  final String? _tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
            color: backgroundColor, borderRadius: BorderRadius.circular(20)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _onPressed,
            child: SizedBox(width: 50, height: 50, child: _icon40px),
          ),
        ),
      ),
    );
  }
}
