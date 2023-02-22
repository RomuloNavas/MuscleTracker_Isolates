import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/home/home_screen.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
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
  List<RegisteredSensor> listSensorsInRegistrationQueue = [];
  bool _isLoading = false;

  late Future connectedSensorMinimalInfo;

  @override
  void initState() {
    super.initState();
    connectedSensorMinimalInfo = _addConnecterSensorsToRegistrationQueue();
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
              labelPrimary: "You can find it at the front back of your sensor",
            ),
            Expanded(
              child: ListView.builder(
                itemCount: listSensorsInRegistrationQueue.length,
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
                                ? AppTheme.appDarkTheme.colorScheme.surface
                                : AppTheme.appTheme.colorScheme.surface),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 16, top: 16, right: 16, bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/callibri_${listSensorsInRegistrationQueue[index].color}.png',
                                      semanticLabel: 'Sensor Icon}',
                                      height: 44,
                                    ),
                                    const SizedBox(width: 3),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Callibri ${listSensorsInRegistrationQueue[index].color}',
                                          style: Get.isDarkMode
                                              ? AppTheme.appDarkTheme.textTheme
                                                  .bodyText1
                                              : AppTheme
                                                  .appTheme.textTheme.bodyText1,
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            style: Get.isDarkMode
                                                ? AppTheme.appDarkTheme
                                                    .textTheme.caption
                                                : AppTheme
                                                    .appTheme.textTheme.caption,
                                            children: <TextSpan>[
                                              const TextSpan(
                                                  text: 'Serial Number: '),
                                              TextSpan(
                                                  text:
                                                      listSensorsInRegistrationQueue[
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
                                            ? AppTheme.appDarkTheme.colorScheme
                                                .surface
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
                                                  onTap: () =>
                                                      _removeSensorFromRegistrationQueue(
                                                          index: index),
                                                  child: AppPopMenuItemChild(
                                                    title: 'Remove sensor',
                                                    iconData:
                                                        Icons.delete_outline,
                                                    iconColor: Theme.of(context)
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
                  );
                },
              ),
            ),
            AppBottom(
              onPressed: () async {
                _isLoading = true;
                setState(() {});
                await _saveSensorsInDataBase();
                _openHomeScreen();
              },
              mainText: 'Save ${widget.listConnectedSensor.length} sensors',
              secondaryText: 'Repeat search of sensors',
              secondaryTextColor: Theme.of(context).colorScheme.error,
            )
          ],
        ));
  }

  Future<void> _saveSensorsInDataBase() async {
    await RegisteredSensorOperations().updateUserUsedSensors();
    for (var sensorToRegister in listSensorsInRegistrationQueue) {
      await RegisteredSensorOperations().insertNewSensor(sensorToRegister);
    }
  }

  void _openHomeScreen() {
    Get.off(() => const HomeScreen());

    setState(() {});
  }

  void _removeSensorFromRegistrationQueue({required int index}) {
    listSensorsInRegistrationQueue.removeAt(index);

    setState(() {});
  }

  Future<void> _addConnecterSensorsToRegistrationQueue() async {
    List<RegisteredSensor> listSensorsToRegister = [];
    for (var sensor in widget.listConnectedSensor) {
      late final String serialNumber;
      late final String address;
      late final CallibriColorType color;
      late final User? user;
      late final int? userId;
      late final int battery;

      serialNumber = await sensor.serialNumber.value;
      address = await sensor.address.value;
      color = await sensor.color.value;
      user = await UserOperations().getLoggedInUser();
      userId = user!.id;
      battery = await sensor.battery.value;

      var registeredSensor = RegisteredSensor(
        serialNumber: serialNumber,
        address: address,
        color: buildColorNameFromSensor(rawSensorNameAndColor: '$color'),
        userId: userId!,
        battery: battery,
        isBeingUsed: 1,
      );
      listSensorsToRegister.add(registeredSensor);
      await Future.delayed(const Duration(milliseconds: 100));
      log('disconnecting');
      _disconnectFromSensors(sensor);
    }
    listSensorsInRegistrationQueue = listSensorsToRegister;

    _isLoading = false;
    setState(() {});
  }

  void _disconnectFromSensors(Sensor connectedSensor) {
      connectedSensor.disconnect();
    
  
  }
}
