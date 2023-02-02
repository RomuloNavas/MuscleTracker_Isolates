import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/search_controller.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/widgets/prepare.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/sensor_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/widgets/searching_animation.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/build_from_sensor.dart';
import 'package:neuro_sdk_isolate_example/utils/extension_methods.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_bottom.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GetxControllerServices _getxServicesManager =
      Get.put(GetxControllerServices());
  final SearchController _searchController = SearchController();
  late StreamSubscription _subscription;

  final List<SensorInfo> _foundSensorsWithCallback = [];
  List<SensorForCheckBox> _foundSensorsForCheckbox = [];
  List<Sensor> connectedSensors = [];

  bool _isLoading = true;
  bool _isReadyToStartDiscovery = false;
  bool _isScannerFinished = false;

  @override
  void initState() {
    super.initState();
    initController();
    _getxServicesManager.requestBluetoothAndGPS();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  void initController() async {
    await _searchController.init();
    _subscription = _searchController.foundSensorsStream.listen((sensors) {
      setState(() {
        _foundSensorsWithCallback.clear();
        _foundSensorsWithCallback.addAll(sensors);
      });
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
    _searchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode
          ? AppTheme.appDarkTheme.scaffoldBackgroundColor
          : AppTheme.appTheme.scaffoldBackgroundColor,
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
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  semanticsLabel: "Инициализация сканера..."),
            );
          }

          if (!_searchController.isAllPermissionGranted) {
            return const Center(
              child: Text("Необходимо предоставить разрешения!"),
            );
          }
          if (_isScannerFinished == true && _foundSensorsWithCallback.isEmpty) {
            return Center(
              child: Column(
                children: [
                  AppHeaderInfo(
                      title: _foundSensorsWithCallback.length == 1
                          ? 'Found 1 device'
                          : 'Found ${_foundSensorsWithCallback.length} devices',
                      labelPrimary: _foundSensorsWithCallback.isEmpty
                          ? 'Make sure that devices are near and turned on'
                          : 'Select your devices and press on the button Connect'),
                  Expanded(child: SizedBox()),
                  AppBottom(
                    mainText: 'Repeat scan',
                    onPressed: () {
                      setState(() {
                        _isReadyToStartDiscovery = true;
                        _isScannerFinished = false;
                      });
                    },
                  ),
                ],
              ),
            );
          }
          if (_isScannerFinished == true &&
              _foundSensorsWithCallback.isNotEmpty) {
            return Column(
              children: [
                AppHeaderInfo(
                    title: _foundSensorsWithCallback.length == 1
                        ? 'Found 1 device'
                        : 'Found ${_foundSensorsWithCallback.length} devices',
                    labelPrimary: _foundSensorsWithCallback.isEmpty
                        ? 'Make sure that devices are near and turned on'
                        : 'Select your devices and press on the button Connect'),
                _buildDiscoveredSensorsCheckBox(),
                AppBottom(
                    mainText:
                        'Connect to ${_foundSensorsForCheckbox.where((e) => e.value == true).length.toString()} devices',
                    onPressed: () async {
                      _isLoading = true;
                      setState(() {});
                      _searchController.stopScanner();
                      _foundSensorsWithCallback.clear();
                      List<Sensor> listSensor = [];
                      List<SensorForCheckBox> listMarkedSensorsFromCheckBox =
                          _foundSensorsForCheckbox
                              .where((s) => s.value == true)
                              .toList();
                      for (var s in listMarkedSensorsFromCheckBox) {
                        var sensor = await Sensor.create(s.sensorInfo);
                        listSensor.add(sensor);
                      }

                      Get.off(() => SensorScreen(
                            listConnectedSensor: listSensor,
                          ));
                    }),
              ],
            );
          }

          if (!_isReadyToStartDiscovery) {
            return GetReadyScreen(
              servicesManager: _getxServicesManager,
              notifyParentStartDiscovery: () {
                setState(() {
                  _isReadyToStartDiscovery = true;
                });
              },
            );
          }
          if (_isReadyToStartDiscovery) {
            return SearchingSensorsScreen(notifyParentStartScanner: () {
              if (_foundSensorsWithCallback.isEmpty) {
                startScanner();
              }
            }, notifyParentStopScanner: () {
              stopScanner();
              _isScannerFinished = true;
              setState(() {});
            });
          }

          return Text('nothing');
        },
      ),
    );
  }

  Expanded _buildDiscoveredSensorsCheckBox() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: _foundSensorsForCheckbox.length,
        itemBuilder: (context, index) {
          SensorForCheckBox sensorForCheckbox = _foundSensorsForCheckbox[index];

          return Padding(
            padding: const EdgeInsets.only(left: 12, top: 12, right: 12),
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
                      : AppTheme.appTheme.cardColor,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        sensorForCheckbox.value = !sensorForCheckbox.value;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 16, top: 16, right: 16, bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/callibri_${buildColorNameFromSensor(rawSensorNameAndColor: sensorForCheckbox.sensorInfo.name)}.png',
                                height: 44,
                              ),
                              const SizedBox(width: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sensorForCheckbox.sensorInfo.address,
                                    style: Get.isDarkMode
                                        ? AppTheme
                                            .appDarkTheme.textTheme.caption
                                        : AppTheme.appTheme.textTheme.caption,
                                  ),
                                  Text(
                                    sensorForCheckbox.sensorInfo.name.isNotEmpty
                                        ? buildCallibriNameFromSensor(
                                                rawSensorNameAndColor:
                                                    sensorForCheckbox
                                                        .sensorInfo.name)
                                            .toTitleCase()
                                        : 'Unknown Callibri',
                                    style: Get.isDarkMode
                                        ? AppTheme
                                            .appDarkTheme.textTheme.bodyText1
                                        : AppTheme.appTheme.textTheme.bodyText1,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Transform.scale(
                            scale: 1.5,
                            child: Checkbox(
                                activeColor: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.colorScheme.primary
                                    : AppTheme.appTheme.colorScheme.primary,
                                overlayColor: MaterialStateProperty.all(
                                  Theme.of(context).primaryColor,
                                ),
                                checkColor: Colors.white,
                                value: sensorForCheckbox.value,
                                shape: const CircleBorder(),
                                onChanged: (bool? value) {
                                  setState(() {
                                    sensorForCheckbox.value = value!;
                                  });
                                }),
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
    );
  }

  void startScanner() {
    _searchController.stopScanner();
    _searchController.startScanner();
    setState(() {});
  }

  void stopScanner() {
    _searchController.stopScanner();
    setState(() {});
    for (var sensor in _foundSensorsWithCallback) {
      var sensorCheckbox = SensorForCheckBox(
        sensorInfo: sensor,
        value: true,
      );
      _foundSensorsForCheckbox.add(sensorCheckbox);
    }
  }

  void _openSensorScreen(List<SensorForCheckBox> sensorsForCheckbox) {
    _searchController.stopScanner();

    // Get.off(() => SensorScreen(connectedSensors: sensorsForCheckbox),
    //     transition: Transition.circularReveal);

    _foundSensorsWithCallback.clear();
    setState(() {});
  }
}

class SensorForCheckBox {
  final SensorInfo sensorInfo;
  bool value;
  SensorForCheckBox({
    required this.sensorInfo,
    this.value = true,
  });
}
