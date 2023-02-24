import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

class AppTextFieldSearch extends StatelessWidget {
  const AppTextFieldSearch({
    required this.textEditingController,
    required this.hintText,
    required this.onCancelButtonPressed,
    super.key,
  });
  final TextEditingController textEditingController;
  final String hintText;
  final Function() onCancelButtonPressed;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
      cursorColor: Colors.grey,
      decoration: InputDecoration(
        fillColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.colorScheme.surface
            : AppTheme.appTheme.colorScheme.surface,
        filled: true,
        contentPadding: const EdgeInsets.all(0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(500),
            borderSide: BorderSide.none),
        hintText: hintText,
        hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.shadow, fontSize: 18),
        prefixIcon: Container(
          padding: const EdgeInsets.all(15),
          width: 18,
          child: Icon(
            Icons.search,
            size: 26,
            color: Theme.of(context).colorScheme.shadow,
          ),
        ),
        suffixIcon: GestureDetector(
          onTap: onCancelButtonPressed,
          child: Icon(
            Icons.cancel,
            size: 26,
            color: Theme.of(context).colorScheme.shadow,
          ),
        ),
      ),
    );
  }
}
