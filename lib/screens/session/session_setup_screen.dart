import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/client_journal/client_history_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/search_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/session/session_monitor_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/search_controller.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/build_from_sensor.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_battery_indicator.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_bottom.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_client_avatar.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_muscle_side.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class GetxControllerSessionSetup extends GetxController {
  RxList<SensorUsedInSession> allConnectedSensorsUsedInSession =
      <SensorUsedInSession>[].obs;
  SensorUsedInSession? selectedSensor = null;
  bool isChoosingSide = false.obs();
}

class SessionSetupScreen extends StatefulWidget {
  final Client client;
  const SessionSetupScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  Placement? _selectedPlacement;

  // Async load data on init:
  List<Map<String, Object?>> allPlacementsInJson = [];
  // late Future initAllPlacementsInJson;

  @override
  void initState() {
    // initAllPlacementsInJson = _getAppPlacementsInJson();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  Widget build(BuildContext context) {
    final GetxControllerSessionSetup _controllerWorkoutSetup =
        Get.put(GetxControllerSessionSetup());

    return SafeArea(
      child: Scaffold(
        backgroundColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        body: Row(
          children: [
            SidePanelWorkoutSetup(
                client: widget.client, selectedPlacement: _selectedPlacement),
            // Flexible(
            //   flex: 1,
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Expanded(
            //         child: Builder(
            //           builder: (context) {
            //             List<Map<String, dynamic>> data = [];
            //             for (var i = 0; i < allPlacementsInJson.length; i++) {
            //               var map = Map<String, dynamic>();
            //               map['placementId'] =
            //                   allPlacementsInJson[i]["placementId"];
            //               map['placementMuscleName'] =
            //                   allPlacementsInJson[i]["placementMuscleName"];
            //               map['FK_Placement_bodyRegionId'] =
            //                   allPlacementsInJson[i]
            //                       ["FK_Placement_bodyRegionId"];
            //               map['placementAction'] =
            //                   allPlacementsInJson[i]["placementAction"];
            //               map['placementMuscleInsertions'] =
            //                   allPlacementsInJson[i]
            //                       ["placementMuscleInsertions"];
            //               map['placementLocationDescription'] =
            //                   allPlacementsInJson[i]
            //                       ["placementLocationDescription"];
            //               map['placementBehavioralTest'] =
            //                   allPlacementsInJson[i]["placementBehavioralTest"];

            //               data.add(map);
            //             }

            //             var groupedByRegions = groupBy(data,
            //                 (Map obj) => obj['FK_Placement_bodyRegionId']);

            //             List<Widget> listOfColumns = [];
            //             listOfColumns.add(const HeaderSearchBar());
            //             groupedByRegions.forEach((key, value) {
            //               listOfColumns.add(Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Padding(
            //                     padding:
            //                         const EdgeInsets.only(left: 48, top: 12),
            //                     child: Text(
            //                         idToBodyRegionString(bodyRegionId: key),
            //                         style: Get.isDarkMode
            //                             ? AppTheme
            //                                 .appDarkTheme.textTheme.headline3
            //                             : AppTheme
            //                                 .appTheme.textTheme.headline3),
            //                   ),
            //                   const SizedBox(height: 16),
            //                   SizedBox(
            //                     height: 190 + 24,
            //                     child: ListView.separated(
            //                       itemCount: groupedByRegions[key]!.length,
            //                       primary: false,
            //                       scrollDirection: Axis.horizontal,
            //                       separatorBuilder: (context, index) =>
            //                           const SizedBox(width: 16),
            //                       itemBuilder: (context, i) {
            //                         Placement sensorPlacement =
            //                             Placement.fromMap(
            //                                 groupedByRegions[key]![i]);

            //                         if (i == 0) {
            //                           return Row(
            //                             children: [
            //                               const SizedBox(width: 48),
            //                               CardSensorPlacementInfo(
            //                                 cardPlacement: sensorPlacement,
            //                                 selectedPlacement:
            //                                     _selectedPlacement ??
            //                                         (Placement(
            //                                             muscleName:
            //                                                 'Not assigned')),
            //                                 notifyParentPlacementSelected:
            //                                     (Placement placement) {
            //                                   setState(() {
            //                                     _selectedPlacement = placement;
            //                                   });
            //                                 },
            //                                 notifyParentSideSelected:
            //                                     (Placement placementWithSide) {
            //                                   setState(() {
            //                                     _selectedPlacement =
            //                                         placementWithSide;
            //                                   });
            //                                 },
            //                               )
            //                             ],
            //                           );
            //                         }
            //                         if (i ==
            //                             groupedByRegions[key]!.length - 1) {
            //                           return Row(
            //                             children: [
            //                               CardSensorPlacementInfo(
            //                                 cardPlacement: sensorPlacement,
            //                                 selectedPlacement:
            //                                     _selectedPlacement ??
            //                                         (Placement(
            //                                             muscleName:
            //                                                 'Not assigned')),
            //                                 notifyParentPlacementSelected:
            //                                     (Placement placement) {
            //                                   setState(() {
            //                                     _selectedPlacement = placement;
            //                                   });
            //                                 },
            //                                 notifyParentSideSelected:
            //                                     (Placement placementWithSide) {
            //                                   setState(() {
            //                                     _selectedPlacement =
            //                                         placementWithSide;
            //                                   });
            //                                 },
            //                               ),
            //                               const SizedBox(width: 48),
            //                             ],
            //                           );
            //                         }

            //                         return CardSensorPlacementInfo(
            //                           cardPlacement: sensorPlacement,
            //                           selectedPlacement: _selectedPlacement ??
            //                               (Placement(
            //                                   muscleName: 'Not assigned')),
            //                           notifyParentPlacementSelected:
            //                               (Placement placement) {
            //                             setState(() {
            //                               _selectedPlacement = placement;
            //                             });
            //                           },
            //                           notifyParentSideSelected:
            //                               (Placement placementWithSide) {
            //                             setState(() {
            //                               _selectedPlacement =
            //                                   placementWithSide;
            //                             });
            //                           },
            //                         );
            //                       },
            //                     ),
            //                   )
            //                 ],
            //               ));
            //             });
            //             return ListView(
            //               children: listOfColumns,
            //             );
            //           },
            //         ),
            //       )
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // Future<void> _getAppPlacementsInJson() async {
  //   var receivedData = await PlacementOperations().getAllPlacementsInJson();
  //   allPlacementsInJson = List.from(receivedData.toList());
  //   setState(() {});
  // }
}

class SidePanelWorkoutSetup extends StatefulWidget {
  const SidePanelWorkoutSetup({
    Key? key,
    required this.client,
    this.selectedPlacement,
  }) : super(key: key);
  final Client client;
  final Placement? selectedPlacement;

  @override
  State<SidePanelWorkoutSetup> createState() => _SidePanelWorkoutSetupState();
}

class _SidePanelWorkoutSetupState extends State<SidePanelWorkoutSetup> {
  double _sidePanelWidth = 320;
  bool _isLoading = true;

  final SearchController _searchController = SearchController();
  late StreamSubscription _subscription;

  List<RegisteredSensor> _allRegisteredSensors = [];
  List<SensorInfo> _allRegisteredAndFoundSensors = [];
  // List<SensorUsedInSession> _allRegisteredAndConnectedSensors = [];
  late Future<void> initRegisteredAndAvailableSensors;
  var registeredSensorOperations = RegisteredSensorOperations();

  @override
  void initState() {
    super.initState();
    initController();
    initRegisteredAndAvailableSensors = _initRegisteredSensorsDBAsync();
  }

  void initController() async {
    var loggedUser = await UserOperations().getLoggedInUser();
    var registeredSensors = await registeredSensorOperations
        .getRegisteredSensorsUsedByUser(loggedUser!);
    _allRegisteredSensors = registeredSensors;

    await _searchController.init();

    _subscription = _searchController.foundSensorsStream.listen((sensors) {
      List<SensorInfo> registeredAndFoundSensors = [];
      // Prepare a list of the registered and discovered sensors, to connect to them later.
      for (var registeredSensor in _allRegisteredSensors) {
        SensorInfo? registeredAndDiscoveredSensor = sensors.firstWhereOrNull(
            (element) => element.address == registeredSensor.address);
        if (registeredAndDiscoveredSensor != null) {
          registeredAndFoundSensors.add(registeredAndDiscoveredSensor);
        }
      }

      setState(() {
        _allRegisteredAndFoundSensors = registeredAndFoundSensors;
      });
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _allRegisteredAndFoundSensors.clear();
    _allRegisteredSensors.clear();
    _searchController.dispose();
    _subscription.cancel();
    _subscription.cancel();
    _searchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GetxControllerSessionSetup _controllerWorkoutSetup = Get.find();

    return Container(
      height: MediaQuery.of(context).size.height,
      width: _sidePanelWidth,
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
              width: 1.0,
              color: Get.isDarkMode
                  ? AppTheme.appDarkTheme.colorScheme.outline
                  : AppTheme.appTheme.colorScheme.outline),
        ),
      ),
      child: ListView(
        children: [
          SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 12, right: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppIconButton(
                        size: ButtonSize.big,
                        svgIconPath: 'arrow-left',
                        onPressed: () {
                          for (var registeredAndConnectedSensor
                              in _controllerWorkoutSetup
                                  .allConnectedSensorsUsedInSession.value) {
                            log('Disconnecting');
                            registeredAndConnectedSensor.sensor.disconnect();
                          }

                          Get.back();
                        },
                      ),
                      SizedBox(width: 6),
                      Text('New Session',
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.headline1
                              : AppTheme.appTheme.textTheme.headline1),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_allRegisteredSensors.isEmpty)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AppHeaderInfo(
                        title: 'No sensors registered',
                        labelPrimary:
                            "Add your Callibri sensors to start a session",
                      ),
                      Container(
                        width: 220,
                        height: 180,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/devices_turned_on.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      AppIconButton(
                        onPressed: () => Get.to(() => SearchScreen()),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        svgIconPath: 'sensor',
                        text: 'Add sensors',
                      ),
                    ],
                  ),
                if (_allRegisteredSensors.isNotEmpty)
                  Builder(
                    builder: (context) {
                      if (_controllerWorkoutSetup
                          .allConnectedSensorsUsedInSession.value.isNotEmpty) {
                        return AppHeaderInfo(
                          title: _controllerWorkoutSetup
                                      .allConnectedSensorsUsedInSession
                                      .length ==
                                  1
                              ? 'Connected to ${_controllerWorkoutSetup.allConnectedSensorsUsedInSession.length} sensor'
                              : 'Connected to ${_controllerWorkoutSetup.allConnectedSensorsUsedInSession.length} sensors',
                        );
                      }
                      if (_allRegisteredAndFoundSensors.isNotEmpty) {
                        return AppHeaderInfo(
                            title: _allRegisteredAndFoundSensors.length == 1
                                ? 'Connecting to ${_allRegisteredAndFoundSensors.length} sensor'
                                : 'Connecting to ${_allRegisteredAndFoundSensors.length} sensors',
                            labelPrimary:
                                'Turn on the sensors you want to use');
                      }
                      return AppHeaderInfo(
                          title: _allRegisteredAndFoundSensors.isEmpty
                              ? 'Turn on your sensors'
                              : 'Found ${_allRegisteredAndFoundSensors.length} Sensors',
                          labelPrimary:
                              'Connect to your registered Callibri sensors');
                    },
                  ),
                // if (_controllerWorkoutSetup
                //     .allConnectedSensorsUsedInSession.isNotEmpty)
                //   Container(
                //     width: _sidePanelWidth,
                //     child: ListView.builder(
                //         shrinkWrap: true,
                //         itemCount: _controllerWorkoutSetup
                //             .allConnectedSensorsUsedInSession.length,
                //         itemBuilder: (context, index) => SensorSetPlacementCard(
                //               currentSensor: _controllerWorkoutSetup
                //                   .allConnectedSensorsUsedInSession[index],
                //               onPressedRemovePlacement: () {
                //                 _controllerWorkoutSetup
                //                     .allConnectedSensorsUsedInSession[index]
                //                     .placement = null;

                //                 setState(() {});
                //               },
                //               onPressedSensor: () {
                //                 var listConnectedSensorsUsedInSession =
                //                     _controllerWorkoutSetup
                //                         .allConnectedSensorsUsedInSession;
                //                 // Unselects all sensors
                //                 for (var sensor
                //                     in listConnectedSensorsUsedInSession
                //                         .value) {
                //                   sensor.isSelectedToAssignPlacement = false;
                //                 }
                //                 //selects the chosen sensor
                //                 listConnectedSensorsUsedInSession[index]
                //                     .isSelectedToAssignPlacement = true;

                //                 _controllerWorkoutSetup.selectedSensor =
                //                     listConnectedSensorsUsedInSession[index];
                //                 setState(() {});
                //               },
                //               sidePanelWidth: _sidePanelWidth,
                //               isSelectedToAssignPlacement:
                //                   _controllerWorkoutSetup
                //                       .allConnectedSensorsUsedInSession[index]
                //                       .isSelectedToAssignPlacement,
                //             )),
                //   ),

                // - Start searching button
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                if (!_isLoading &&
                    _controllerWorkoutSetup
                        .allConnectedSensorsUsedInSession.isEmpty &&
                    _allRegisteredSensors.isNotEmpty)
                  Column(
                    children: [
                      SvgPicture.asset(
                        'assets/illustrations/turn-on.svg',
                        height: 180,
                      ),
                      const SizedBox(height: 16),
                      AppBottom(
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });
                            _searchController.startScanner();
                            await Future.delayed(const Duration(seconds: 4));
                            _searchController.stopScanner();

                            _initRegisteredSensorsDBAsync();
                          },
                          mainText: 'Start Searching'),
                    ],
                  ),
                if (!_isLoading &&
                    _controllerWorkoutSetup
                        .allConnectedSensorsUsedInSession.isNotEmpty)
                  AppBottom(
                    onPressed: () {
                      Get.off(() => SessionMonitorScreen(
                          client: widget.client,
                          allSensorsUsedInSession: _controllerWorkoutSetup
                              .allConnectedSensorsUsedInSession.value));
                    },
                    // secondaryText: 'Repeat search',
                    // secondaryTextColor: Theme.of(context).colorScheme.error,
                    mainText: 'Start session',
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
              top: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text('Type of workout (symmetric muscles, etc)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initRegisteredSensorsDBAsync() async {
    final GetxControllerSessionSetup _controllerWorkoutSetup = Get.find();

    /// Connect to the registered and discovered sensors:
    if (_allRegisteredAndFoundSensors.isNotEmpty) {
      _isLoading = true;

      // List with the registered sensors to which we will connect
      List<SensorUsedInSession> registeredAndConnectedSensors = [];

      for (var sensorInfo in _allRegisteredAndFoundSensors) {
        log('CONNECTING...');
        Sensor? connectedSensor;
        try {
          connectedSensor = await Sensor.create(sensorInfo);
          log('CONNECTED');
        } catch (e) {
          log(e.toString(),
              name:
                  'session_setup_screen - _initRegisteredSensorsDBAsync, - Could not connect to sensor.');
        }
        if (connectedSensor != null) {
          var sensorUsedInSession = await _startSensorUsedInSessionClass(
              connectedSensor: connectedSensor);
          registeredAndConnectedSensors.add(sensorUsedInSession);
        } else {
          log("Could't connect");
        }
      }
      _controllerWorkoutSetup.allConnectedSensorsUsedInSession.value =
          registeredAndConnectedSensors;

      _allRegisteredAndFoundSensors.clear();
      _searchController.dispose();
    }
    _isLoading = false;
    setState(() {});
  }

  Future<SensorUsedInSession> _startSensorUsedInSessionClass(
      {required Sensor connectedSensor}) async {
    final int connectedSensorBattery = await connectedSensor.battery.value;
    final CallibriColorType connectedSensorColor =
        await connectedSensor.color.value;
    final String connectedSensorAddress = await connectedSensor.address.value;

    var registeredSensor = await registeredSensorOperations
        .getRegisteredSensorByAddress(connectedSensorAddress);
    registeredSensor?.battery = connectedSensorBattery;
    registeredSensorOperations.updateRegisteredSensorBattery(registeredSensor!);

    return SensorUsedInSession(
        battery: connectedSensorBattery,
        color: buildColorNameFromSensor(
            rawSensorNameAndColor: '$connectedSensorColor'),
        address: connectedSensorAddress,
        isSelectedToAssignPlacement: false,
        sensor: connectedSensor,
        listEnvSamplesValuesForGraphic: [0],
        envelopeValuesForAnalytics: EnvelopeValuesForAnalytics(
            address: connectedSensorAddress,
            listEnvSamplesValuesForStatistics: []),
        chartData: [ChartSampleData(x: 0, y: 0)],
        columnChartData: []);
  }
}

// class SensorSetPlacementCard extends StatelessWidget {
//   final double sidePanelWidth;
//   final Function() onPressedSensor;
//   final Function() onPressedRemovePlacement;
//   bool isSelectedToAssignPlacement;
//   SensorUsedInSession currentSensor;
//   SensorSetPlacementCard({
//     required this.currentSensor,
//     required this.sidePanelWidth,
//     required this.isSelectedToAssignPlacement,
//     required this.onPressedSensor,
//     required this.onPressedRemovePlacement,
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ZoomTapAnimation(
//       onTap: onPressedSensor,
//       child: Container(
//         height: 80,
//         width: sidePanelWidth,
//         decoration: BoxDecoration(
//           color: isSelectedToAssignPlacement
//               ? Get.isDarkMode
//                   ? Colors.white.withOpacity(0.1)
//                   : Colors.black.withOpacity(0.1)
//               : Colors.transparent,
//         ),
//         child: Padding(
//           padding:
//               const EdgeInsets.only(right: 12, left: 12, top: 8, bottom: 8),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: isSelectedToAssignPlacement
//                         ? Colors.white
//                         : Colors.transparent,
//                     radius: 22,
//                     child: CircleAvatar(
//                       backgroundColor: Get.isDarkMode
//                           ? Colors.white.withOpacity(0.1)
//                           : Colors.black.withOpacity(0.1),
//                       child: SvgPicture.asset(
//                           'assets/icons/callibri_device-${currentSensor.color}.svg',
//                           width: 16,
//                           semanticsLabel: 'Battery'),
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   AppBatteryIndicator(
//                       batteryLevel: currentSensor.battery!,
//                       appBatteryIndicatorLabelPosition:
//                           AppBatteryIndicatorLabelPosition.inside)
//                 ],
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       currentSensor.placement == null
//                           ? 'Not assigned'
//                           : idToBodyRegionString(
//                               bodyRegionId:
//                                   currentSensor.placement!.bodyRegionId),
//                       style: Get.isDarkMode
//                           ? AppTheme.appDarkTheme.textTheme.caption
//                               ?.copyWith(color: const Color(0xff878787))
//                           : AppTheme.appTheme.textTheme.caption?.copyWith(
//                               color: const Color(0xff444547),
//                             ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                         currentSensor.placement == null
//                             ? 'Not assigned'
//                             : currentSensor.placement!.muscleName,
//                         style: Get.isDarkMode
//                             ? AppTheme.appDarkTheme.textTheme.bodyText1
//                             : AppTheme.appTheme.textTheme.bodyText1),
//                     const SizedBox(height: 2),
//                     if (currentSensor.placement?.side != null)
//                       AppMuscleSideIndicator(
//                           side: currentSensor.placement!.side!)
//                   ],
//                 ),
//               ),
//               AppIconButton(
//                   svgIconPath: 'trash', onPressed: onPressedRemovePlacement),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

/**
 * WIDGETS USED IN CURRENT SCREEN
 */

class HeaderSearchBar extends StatelessWidget {
  const HeaderSearchBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Sensor Placement ',
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.headline1
                  : AppTheme.appTheme.textTheme.headline1),
          IconButton(
              icon: const Icon(Icons.search, size: 32), onPressed: () => null),
        ],
      ),
    );
  }
}

class CardSensorPlacementInfo extends StatelessWidget {
  const CardSensorPlacementInfo({
    required this.notifyParentPlacementSelected,
    required this.notifyParentSideSelected,
    required this.cardPlacement,
    Key? key,
    required this.selectedPlacement,
  }) : super(key: key);
  final Placement cardPlacement;
  final Placement selectedPlacement;
  final Function(Placement placement) notifyParentPlacementSelected;
  final Function(Placement placementWithSide) notifyParentSideSelected;

  @override
  Widget build(BuildContext context) {
    final GetxControllerSessionSetup _controllerWorkoutSetup = Get.find();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            notifyParentPlacementSelected(cardPlacement);

            if (_controllerWorkoutSetup.selectedSensor != null) {
              _controllerWorkoutSetup.selectedSensor!.placement = cardPlacement;
              _controllerWorkoutSetup.allConnectedSensorsUsedInSession
                  .refresh(); //! Important
              _controllerWorkoutSetup.isChoosingSide = true;
            }
          },
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.contain,
                  image: AssetImage(
                    'assets/images/sensor_placements/${idToBodyRegionString(bodyRegionId: cardPlacement.bodyRegionId)}/${cardPlacement.muscleName}.png',
                  )),
            ),
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: FractionalOffset.bottomCenter,
                      end: FractionalOffset.topCenter,
                      colors: Get.isDarkMode
                          ? [
                              Colors.black.withOpacity(.8),
                              Colors.black.withOpacity(.3)
                            ]
                          : [
                              Colors.black.withOpacity(.5),
                              Colors.black.withOpacity(.0)
                            ])),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                        height: 8,
                        width: 180,
                        color: Theme.of(context)
                            .scaffoldBackgroundColor
                            .withOpacity(.5)),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Row(
                      children: [
                        Container(
                            height: 24,
                            width: 8,
                            color: Get.isDarkMode
                                ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                                    .withOpacity(0.5)
                                : AppTheme.appTheme.scaffoldBackgroundColor
                                    .withOpacity(0.5)),
                        Container(
                            width: 180 - 8 - 8,
                            margin: const EdgeInsets.only(left: 8),
                            child: Text(cardPlacement.muscleName.toString(),
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                        ?.copyWith(
                                            color: const Color(0xffeeeeee))
                                    : AppTheme.appTheme.textTheme.headline5
                                        ?.copyWith(color: Colors.white))),
                      ],
                    ),
                  ),
                  if (selectedPlacement.muscleName ==
                          cardPlacement.muscleName &&
                      _controllerWorkoutSetup.isChoosingSide == true)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ZoomTapAnimation(
                            child: AppMuscleSideIndicator(
                                side: 'left', size: ButtonSize.big),
                            onTap: () {
                              selectedPlacement.side = 'left';
                              notifyParentSideSelected(selectedPlacement);
                              if (_controllerWorkoutSetup.selectedSensor !=
                                  null) {
                                _controllerWorkoutSetup.selectedSensor!
                                    .placement = selectedPlacement;
                                _controllerWorkoutSetup
                                    .allConnectedSensorsUsedInSession
                                    .refresh(); //! Important
                                _controllerWorkoutSetup.isChoosingSide = false;
                              }
                            },
                          ),
                          const SizedBox(width: 24),
                          ZoomTapAnimation(
                            onTap: () {
                              selectedPlacement.side = 'right';
                              notifyParentSideSelected(selectedPlacement);
                              if (_controllerWorkoutSetup.selectedSensor !=
                                  null) {
                                _controllerWorkoutSetup.selectedSensor!
                                    .placement = selectedPlacement;
                                _controllerWorkoutSetup
                                    .allConnectedSensorsUsedInSession
                                    .refresh(); //! Important
                                _controllerWorkoutSetup.isChoosingSide = false;
                              }
                            },
                            child: AppMuscleSideIndicator(
                                side: 'right', size: ButtonSize.big),
                          )
                        ],
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(cardPlacement.muscleName,
            style: Get.isDarkMode
                ? AppTheme.appDarkTheme.textTheme.overline
                : AppTheme.appTheme.textTheme.overline),
      ],
    );
  }
}

class SensorUsedInSession {
  SensorUsedInSession({
    required this.sensor,
    this.placement,
    this.isSelectedToAssignPlacement = false,
    this.color,
    this.address,
    this.battery,
    this.isConnected = true,
    this.chartSeriesController,
    this.columnChartSeriesController,
    this.countLastElectrodeState = 0,
    this.electrodeState = CallibriElectrodeState.elStNormal,
    this.signalForCheckingSensorState = 0,
    this.xValueCounter = 0,
    required this.listEnvSamplesValuesForGraphic,
    required this.envelopeValuesForAnalytics,
    required this.chartData,
    required this.columnChartData,
  });

  final Sensor sensor;
  Placement? placement;
  bool isSelectedToAssignPlacement = false;
  String? color;
  String? address;
  int? battery;
  bool isConnected;
  int countLastElectrodeState;
  CallibriElectrodeState electrodeState;
  int xValueCounter;
  ChartSeriesController? chartSeriesController;
  ChartSeriesController? columnChartSeriesController;
  List<double> listEnvSamplesValuesForGraphic;
  int signalForCheckingSensorState;
  List<ChartSampleData> chartData;
  List<ChartSampleData> columnChartData;
  EnvelopeValuesForAnalytics envelopeValuesForAnalytics;
}

class EnvelopeValuesForAnalytics {
  EnvelopeValuesForAnalytics({
    required this.address,
    required this.listEnvSamplesValuesForStatistics,
    this.countSamplesFromSensor = 0,
    this.countCerosAdded = 0,
    this.countRemovedValues = 0,
    this.isConnected = true,
  });
  final String address;
  List<double> listEnvSamplesValuesForStatistics;
  int countSamplesFromSensor;
  int countRemovedValues;
  int countCerosAdded;
  bool isConnected;
}
