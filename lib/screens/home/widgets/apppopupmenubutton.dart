import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_pop_menu_item_child.dart';

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
      splashRadius: 22,
      icon: Container(
        decoration: BoxDecoration(
          color: Get.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Icon(
                iconData,
                size: 25,
                color: Color(0xff838997),
              ),
            ),
          ),
        ),
      ),
      itemBuilder: (context) => itemBuilder,
    );
  }
}
