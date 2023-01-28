import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/extension_methods.dart';

class TapperRegisteredSensorInfo extends StatelessWidget {
  const TapperRegisteredSensorInfo(
      {Key? key, required this.tappedRegisteredSensorInfo})
      : super(key: key);

  final RegisteredSensor tappedRegisteredSensorInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Get.isDarkMode
              ? AppTheme.appDarkTheme.colorScheme.surface
              : AppTheme.appTheme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InformationTile(
              title: 'Serial Number',
              description:
                  tappedRegisteredSensorInfo.serialNumber.toUpperCase()),
          InformationTile(
              title: 'Address',
              description: tappedRegisteredSensorInfo.address.toUpperCase()),
          InformationTile(
              title: 'Color',
              description: tappedRegisteredSensorInfo.color
                  .split('.')
                  .last
                  .toCapitalized()),
          InformationTile(
              title: 'Gain',
              description: tappedRegisteredSensorInfo.gain
                  .split('.')
                  .last
                  .toCapitalized()),
          InformationTile(
              title: 'Data offset',
              description: tappedRegisteredSensorInfo.dataOffset
                  .split('.')
                  .last
                  .toCapitalized()),
          InformationTile(
              title: 'ADC Input',
              description: tappedRegisteredSensorInfo.adcInput
                  .split('.')
                  .last
                  .toCapitalized()),
          InformationTile(
              title: 'Hardware filters',
              description: tappedRegisteredSensorInfo.hardwareFilters),
          InformationTile(
              title: 'Sampling frequency',
              description: tappedRegisteredSensorInfo.samplingFrequency
                  .split('frequency')
                  .last
                  .toUpperCase()),
        ],
      ),
    );
  }
}

class InformationTile extends StatelessWidget {
  const InformationTile({
    Key? key,
    required String title,
    required String description,
  })  : _title = title,
        _description = description,
        super(key: key);

  final String _title;
  final String _description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_title: ', style: AppTheme.appDarkTheme.textTheme.labelMedium),
          Text(_description,
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.overline
                  : AppTheme.appTheme.textTheme.overline),
          Container(
            height: 1,
            color: Get.isDarkMode
                ? AppTheme.appDarkTheme.colorScheme.outline
                : AppTheme.appTheme.colorScheme.outline,
          )
        ],
      ),
    );
  }
}
