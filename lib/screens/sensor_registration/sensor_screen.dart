import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/workout_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/home/home_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/search_for_registration/search_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/sensor_conroller.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/widgets/sensor_screen_body.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/build_battery_indicator_icon.dart';
import 'package:neuro_sdk_isolate_example/utils/build_from_sensor.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_battery_indicator.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_bottom.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_pop_menu_item_child.dart';

class SensorScreen extends StatefulWidget {
  final List<Sensor> listConnectedSensor;
  const SensorScreen({super.key, required this.listConnectedSensor});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  List<RegisteredSensor> listSensorsToRegister = [];
  bool _isLoading = false;

  late Future connectedSensorMinimalInfo;

  @override
  void initState() {
    super.initState();
    connectedSensorMinimalInfo = _getConnectedSensorInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading == true) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: MediaQuery.of(context).size.height < 500 ? 50 : 80,
          titleTextStyle: Get.isDarkMode
              ? AppTheme.appDarkTheme.textTheme.headline3
              : AppTheme.appTheme.textTheme.headline3,
          title: const Text('Sensors registration'),
          titleSpacing: 32.0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            const AppHeaderInfo(
              title: 'The Serial Numbers must coincide with your sensors',
              labelPrimary: "Tap on the cards below to localize your sensors",
            ),
            Expanded(
              child: ListView.builder(
                itemCount: listSensorsToRegister.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 12, top: 12, right: 12),
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: MediaQuery.of(context).size.width > 600
                            ? MediaQuery.of(context).size.width * 0.65
                            : double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Get.isDarkMode
                                ? AppTheme.appDarkTheme.cardColor
                                : AppTheme.appTheme.cardColor),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () =>
                                _findSensor(widget.listConnectedSensor[index]),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, top: 16, right: 16, bottom: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/callibri_${listSensorsToRegister[index].color}.png',
                                        semanticLabel: 'Sensor Icon}',
                                        height: 44,
                                      ),
                                      const SizedBox(width: 3),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Callibri ${listSensorsToRegister[index].color}',
                                            style: Get.isDarkMode
                                                ? AppTheme.appDarkTheme
                                                    .textTheme.bodyText1
                                                : AppTheme.appTheme.textTheme
                                                    .bodyText1,
                                          ),
                                          RichText(
                                            text: TextSpan(
                                              style: Get.isDarkMode
                                                  ? AppTheme.appDarkTheme
                                                      .textTheme.caption
                                                  : AppTheme.appTheme.textTheme
                                                      .caption,
                                              children: <TextSpan>[
                                                const TextSpan(
                                                    text: 'Serial Number: '),
                                                TextSpan(
                                                    text: listSensorsToRegister[
                                                            index]
                                                        .serialNumber,
                                                    style: Get.isDarkMode
                                                        ? AppTheme.appDarkTheme
                                                            .textTheme.caption
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)
                                                        : AppTheme.appTheme
                                                            .textTheme.caption
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      FutureBuilder(
                                          future: widget
                                              .listConnectedSensor[index]
                                              .battery
                                              .value,
                                          builder: (context,
                                              AsyncSnapshot<int> snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return AppBatteryIndicator(
                                                  appBatteryIndicatorLabelPosition:
                                                      AppBatteryIndicatorLabelPosition
                                                          .left,
                                                  batteryLevel: snapshot.data!);
                                            } else {
                                              return SizedBox();
                                            }
                                          }),
                                      const SizedBox(width: 8),
                                      PopupMenuButton(
                                          constraints:
                                              BoxConstraints(minWidth: 220),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(20.0),
                                            ),
                                          ),
                                          elevation: 0.2,
                                          color: Get.isDarkMode
                                              ? AppTheme.appDarkTheme
                                                  .colorScheme.surface
                                              : AppTheme
                                                  .appTheme.colorScheme.surface,
                                          position: PopupMenuPosition.under,
                                          offset: Offset(0, 12),
                                          // position: PopupMenuPosition.over,
                                          // offset: Offset(48, -10),
                                          splashRadius: 26,
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: Get.isDarkMode
                                                ? Color(0xffdcdcdc)
                                                : Colors.black,
                                          ),
                                          itemBuilder: (context) => [
                                                PopupMenuItem(
                                                    onTap: () => _findSensor(
                                                        widget.listConnectedSensor[
                                                            index]),
                                                    child:
                                                        const AppPopMenuItemChild(
                                                      title: 'Find sensor',
                                                      iconData:
                                                          Icons.emoji_objects,
                                                    )),
                                                PopupMenuItem(
                                                    onTap: () {
                                                      listSensorsToRegister
                                                          .removeAt(index);
                                                      setState(() {});
                                                    },
                                                    child: AppPopMenuItemChild(
                                                      title: 'Remove sensor',
                                                      iconData:
                                                          Icons.delete_outline,
                                                      iconColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .error,
                                                    )),
                                              ])
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            AppBottom(
              onPressed: () async {
                _isLoading = true;
                setState(() {});
                for (var sensorToRegister in listSensorsToRegister) {
                  await RegisteredSensorOperations()
                      .insertNewSensor(sensorToRegister);
                }
                for (var connectedSensor in widget.listConnectedSensor) {
                  connectedSensor.disconnect();
                }

                Get.off(() => HomeScreen(),
              );
              },
              mainText: 'Save ${widget.listConnectedSensor.length} sensors',
              secondaryText: 'Repeat search of sensors',
              secondaryTextColor: Theme.of(context).colorScheme.error,
            )
          ],
        ));
  }

  _findSensor(Sensor sensor) async {
    // First check if the sensor is connected.
    SensorState sensorState = await sensor.state.value;

    if (sensorState == SensorState.inRange) {
      // If the sensor is connected, execute the command findMe
      await sensor.executeCommand(SensorCommand.findMe);
    }
  }

  Future<void> _getConnectedSensorInfo() async {
    List<RegisteredSensor> allConnectedSensorToRegister = [];
    for (var sensor in widget.listConnectedSensor) {
      var serialNumber = await sensor.serialNumber.value;
      var address = await sensor.address.value;
      var color = await sensor.color.value;
      var gain = await sensor.gain.value;
      var dataOffset = await sensor.dataOffset.value;
      var adcInput = await sensor.adcInput.value;
      var hardwareFilters = await sensor.hardwareFilters.value;
      var samplingFrequency = await sensor.samplingFrequency.value;
      var battery = await sensor.battery.value;
      var registeredSensor = RegisteredSensor(
        serialNumber: serialNumber,
        address: address,
        color: buildColorNameFromSensor(rawSensorNameAndColor: '$color'),
        gain: '$gain',
        dataOffset: '$dataOffset',
        adcInput: '$adcInput',
        hardwareFilters: '$hardwareFilters',
        samplingFrequency: '$samplingFrequency',
        battery: battery,
      );
      allConnectedSensorToRegister.add(registeredSensor);
    }
    listSensorsToRegister = allConnectedSensorToRegister;
    _isLoading = false;
    setState(() {});
  }
}
