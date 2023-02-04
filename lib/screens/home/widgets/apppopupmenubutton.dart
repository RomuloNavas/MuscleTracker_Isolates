import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_pop_menu_item_child.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';

class AppPopupMenuButton extends StatelessWidget {
  final List<PopupMenuEntry<dynamic>> itemBuilder;
  final IconData iconData;
  AppPopupMenuButton({
    Key? key,
    required this.iconData,
    required this.itemBuilder,
  }) : super(key: key);

  final clientOperations = ClientOperations();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      padding: EdgeInsets.all(0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(8),
        ),
      ),
      elevation: 0.4,
      color: Get.isDarkMode
          ? AppTheme.appDarkTheme.colorScheme.surface
          : AppTheme.appTheme.colorScheme.surface,
      position: PopupMenuPosition.under,
      offset: Offset(0, 12),
      splashRadius: 0.1,
      icon: ScaleTap(
        scaleMinValue: 0.9,
        opacityMinValue: 0.4,
        scaleCurve: Curves.decelerate,
        opacityCurve: Curves.fastOutSlowIn,
        child: SvgPicture.asset('assets/icons/ui/settings.svg',
            width: 32, semanticsLabel: 'Callibri icon'),
      ),
      itemBuilder: (context) => itemBuilder,
    );
  }
}
