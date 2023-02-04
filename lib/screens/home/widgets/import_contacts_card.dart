import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

class ImportContactsCard extends StatelessWidget {
  const ImportContactsCard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          height: 70,
          width: MediaQuery.of(context).size.width - 372,
          color: Get.isDarkMode
              ? AppTheme.appDarkTheme.colorScheme.surface
              : AppTheme.appTheme.colorScheme.surface,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xff26c6f4),
                        Color(0xff6f78fa),
                        Color(0xffa73de4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4)),
                child: const Icon(
                  Icons.contacts,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Import people from your phone's contacts",
                    style: Get.isDarkMode
                        ? AppTheme.appDarkTheme.textTheme.bodyText2
                        : AppTheme.appTheme.textTheme.bodyText2,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: null,
                    child: Text(
                      'Import contacts',
                      style: Get.isDarkMode
                          ? AppTheme.appDarkTheme.textTheme.bodyText2?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.appDarkTheme.colorScheme.primary)
                          : AppTheme.appTheme.textTheme.bodyText2?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.appTheme.colorScheme.primary),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
          child: GestureDetector(
            onTap: null,
            child: const Icon(Icons.close),
          ),
        )
      ],
    );
  }
}
