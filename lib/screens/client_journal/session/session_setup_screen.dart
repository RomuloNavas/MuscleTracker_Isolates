import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/session_setup_manager.dart';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/client_journal/session/session_monitor_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/search_for_registration/controllers/search_controller.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/build_from_sensor.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_battery_indicator.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_bottom.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_client_avatart.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
  late Future initAllPlacementsInJson;

  @override
  void initState() {
    initAllPlacementsInJson = _getAppPlacementsInJson();
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        body: Row(
          children: [
            SidePanelWorkoutSetup(
                client: widget.client, selectedPlacement: _selectedPlacement),
            Flexible(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        List<Map<String, dynamic>> data = [];
                        for (var i = 0; i < allPlacementsInJson.length; i++) {
                          var map = Map<String, dynamic>();
                          map['placementId'] =
                              allPlacementsInJson[i]["placementId"];
                          map['placementMuscleName'] =
                              allPlacementsInJson[i]["placementMuscleName"];
                          map['FK_Placement_bodyRegionId'] =
                              allPlacementsInJson[i]
                                  ["FK_Placement_bodyRegionId"];
                          map['placementAction'] =
                              allPlacementsInJson[i]["placementAction"];
                          map['placementMuscleInsertions'] =
                              allPlacementsInJson[i]
                                  ["placementMuscleInsertions"];
                          map['placementLocationDescription'] =
                              allPlacementsInJson[i]
                                  ["placementLocationDescription"];
                          map['placementBehavioralTest'] =
                              allPlacementsInJson[i]["placementBehavioralTest"];

                          data.add(map);
                        }

                        var groupedByRegions = groupBy(data,
                            (Map obj) => obj['FK_Placement_bodyRegionId']);

                        List<Widget> listOfColumns = [];
                        listOfColumns.add(const HeaderSearchBar());
                        groupedByRegions.forEach((key, value) {
                          listOfColumns.add(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 65, top: 32),
                                child: Text(
                                    idToBodyRegionString(bodyRegionId: key),
                                    style: Get.isDarkMode
                                        ? AppTheme
                                            .appDarkTheme.textTheme.headline3
                                        : AppTheme
                                            .appTheme.textTheme.headline3),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 224 + 24,
                                child: ListView.separated(
                                  itemCount: groupedByRegions[key]!.length,
                                  primary: false,
                                  scrollDirection: Axis.horizontal,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (context, i) {
                                    Placement sensorPlacement =
                                        Placement.fromMap(
                                            groupedByRegions[key]![i]);

                                    if (i == 0) {
                                      return Row(
                                        children: [
                                          const SizedBox(width: 65),
                                          CardSensorPlacementInfo(
                                            cardPlacement: sensorPlacement,
                                            selectedPlacement:
                                                _selectedPlacement ??
                                                    (Placement(
                                                        muscleName:
                                                            'Not assigned')),
                                            notifyParentPlacementSelected:
                                                (Placement placement) {
                                              setState(() {
                                                _selectedPlacement = placement;
                                              });
                                            },
                                            notifyParentSideSelected:
                                                (Placement placementWithSide) {
                                              setState(() {
                                                _selectedPlacement =
                                                    placementWithSide;
                                              });
                                            },
                                          )
                                        ],
                                      );
                                    }
                                    if (i ==
                                        groupedByRegions[key]!.length - 1) {
                                      return Row(
                                        children: [
                                          CardSensorPlacementInfo(
                                            cardPlacement: sensorPlacement,
                                            selectedPlacement:
                                                _selectedPlacement ??
                                                    (Placement(
                                                        muscleName:
                                                            'Not assigned')),
                                            notifyParentPlacementSelected:
                                                (Placement placement) {
                                              setState(() {
                                                _selectedPlacement = placement;
                                              });
                                            },
                                            notifyParentSideSelected:
                                                (Placement placementWithSide) {
                                              setState(() {
                                                _selectedPlacement =
                                                    placementWithSide;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 65),
                                        ],
                                      );
                                    }

                                    return CardSensorPlacementInfo(
                                      cardPlacement: sensorPlacement,
                                      selectedPlacement: _selectedPlacement ??
                                          (Placement(
                                              muscleName: 'Not assigned')),
                                      notifyParentPlacementSelected:
                                          (Placement placement) {
                                        setState(() {
                                          _selectedPlacement = placement;
                                        });
                                      },
                                      notifyParentSideSelected:
                                          (Placement placementWithSide) {
                                        setState(() {
                                          _selectedPlacement =
                                              placementWithSide;
                                        });
                                      },
                                    );
                                  },
                                ),
                              )
                            ],
                          ));
                        });
                        return ListView(
                          children: listOfColumns,
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getAppPlacementsInJson() async {
    var receivedData = await PlacementOperations().getAllPlacementsInJson();
    allPlacementsInJson = List.from(receivedData.toList());
    setState(() {});
  }
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
  double sidebarWidth = 310;
  bool _isLoading = true;

  final SearchController _searchController = SearchController();
  late StreamSubscription _subscription;

  List<RegisteredSensor> _allRegisteredSensors = [];
  List<SensorInfo> _allRegisteredAndFoundSensors = [];
  List<SensorUsedInSession> _allRegisteredAndConnectedSensors = [];
  late Future<void> initRegisteredAndAvailableSensors;

  @override
  void initState() {
    super.initState();
    initController();
    initRegisteredAndAvailableSensors = _initRegisteredSensorsDBAsync();
  }

  void initController() async {
    var registeredSensors =
        await RegisteredSensorOperations().getAllRegisteredSensors();
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
    super.dispose();
    _subscription.cancel();
    _searchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  @override
  Widget build(BuildContext context) {
    for (var element in _allRegisteredAndConnectedSensors) {
      if (element.isSelectedToAssignPlacement) {
        setState(() {
          element.placement = widget.selectedPlacement;
        });
      }
    }
    return Container(
      height: MediaQuery.of(context).size.height,
      width: sidebarWidth,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppIconButton(
                        size: ButtonSize.big,
                        iconData: Icons.arrow_back,
                        onPressed: () {
                          for (var registeredAndConnectedSensor
                              in _allRegisteredAndConnectedSensors) {
                            registeredAndConnectedSensor.sensor.disconnect();
                          }

                          Get.back();
                        },
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 160,
                                child: Text(
                                    '${widget.client.surname} ${widget.client.name}',
                                    maxLines: 2,
                                    textAlign: TextAlign.right,
                                    style: Get.isDarkMode
                                        ? AppTheme
                                            .appDarkTheme.textTheme.headline5
                                        : AppTheme
                                            .appTheme.textTheme.headline5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  DateFormat.Md()
                                      .add_jm()
                                      .format(DateTime.now()),
                                  style: Get.isDarkMode
                                      ? AppTheme
                                          .appDarkTheme.textTheme.headline5
                                          ?.copyWith(color: Color(0xff878787))
                                      : AppTheme.appTheme.textTheme.headline5
                                          ?.copyWith(color: Color(0xff7a7575))),
                            ],
                          ),
                          const SizedBox(width: 12),
                          ContactCircleAvatar(
                            radius: 27,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    if (_allRegisteredAndConnectedSensors.isNotEmpty) {
                      return AppHeaderInfo(
                        title: _allRegisteredAndConnectedSensors.length == 1
                            ? 'Connected to ${_allRegisteredAndConnectedSensors.length} sensor'
                            : 'Connected to ${_allRegisteredAndConnectedSensors.length} sensors',
                      );
                    }
                    if (_allRegisteredAndFoundSensors.isNotEmpty) {
                      return AppHeaderInfo(
                          title: _allRegisteredAndFoundSensors.length == 1
                              ? 'Connecting to ${_allRegisteredAndFoundSensors.length} sensor'
                              : 'Connecting to ${_allRegisteredAndFoundSensors.length} sensors',
                          labelPrimary: 'Turn on the sensors you want to use');
                    }
                    return AppHeaderInfo(
                        title: _allRegisteredAndFoundSensors.isEmpty
                            ? 'Connect to your Sensors'
                            : 'Found ${_allRegisteredAndConnectedSensors.length} Sensors',
                        labelPrimary: 'Turn on the sensors you want to use');
                  },
                ),
                // if (_allRegisteredAndConnectedSensors.isNotEmpty)
                SizedBox(height: 12),
                Container(
                  width: sidebarWidth,
                  child: Column(
                    children: [
                      for (int i = 0;
                          i < _allRegisteredAndConnectedSensors.length;
                          i++)
                        Container(
                          height: 80,
                          width: sidebarWidth,
                          decoration: BoxDecoration(
                            color: _allRegisteredAndConnectedSensors[i]
                                    .isSelectedToAssignPlacement
                                ? Get.isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                for (var registeredSensor
                                    in _allRegisteredAndConnectedSensors) {
                                  registeredSensor.isSelectedToAssignPlacement =
                                      false;
                                }
                                _allRegisteredAndConnectedSensors[i]
                                    .isSelectedToAssignPlacement = true;
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: 12, left: 12, top: 8, bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              _allRegisteredAndConnectedSensors[
                                                          i]
                                                      .isSelectedToAssignPlacement
                                                  ? Colors.white
                                                  : Colors.transparent,
                                          radius: 22,
                                          child: CircleAvatar(
                                            backgroundColor: Get.isDarkMode
                                                ? Colors.white.withOpacity(0.1)
                                                : Colors.black.withOpacity(0.1),
                                            child: SvgPicture.asset(
                                                'assets/icons/callibri_device-${_allRegisteredAndConnectedSensors[i].color}.svg',
                                                width: 16,
                                                semanticsLabel: 'Battery'),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        AppBatteryIndicator(
                                            batteryLevel:
                                                _allRegisteredAndConnectedSensors[
                                                        i]
                                                    .battery!,
                                            appBatteryIndicatorLabelPosition:
                                                AppBatteryIndicatorLabelPosition
                                                    .inside)
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _allRegisteredAndConnectedSensors[i]
                                                        .placement ==
                                                    null
                                                ? 'Not assigned'
                                                : idToBodyRegionString(
                                                    bodyRegionId:
                                                        _allRegisteredAndConnectedSensors[
                                                                i]
                                                            .placement!
                                                            .bodyRegionId),
                                            style: Get.isDarkMode
                                                ? AppTheme.appDarkTheme
                                                    .textTheme.caption
                                                    ?.copyWith(
                                                        color: const Color(
                                                            0xff878787))
                                                : AppTheme
                                                    .appTheme.textTheme.caption
                                                    ?.copyWith(
                                                    color:
                                                        const Color(0xff444547),
                                                  ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                              _allRegisteredAndConnectedSensors[
                                                              i]
                                                          .placement ==
                                                      null
                                                  ? 'Not assigned'
                                                  : _allRegisteredAndConnectedSensors[
                                                          i]
                                                      .placement!
                                                      .muscleName,
                                              style:
                                                  Get.isDarkMode
                                                      ? AppTheme.appDarkTheme
                                                          .textTheme.bodyText1
                                                      : AppTheme.appTheme
                                                          .textTheme.bodyText1),
                                          const SizedBox(height: 2),
                                          if (_allRegisteredAndConnectedSensors[
                                                      i]
                                                  .placement
                                                  ?.side !=
                                              null)
                                            Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  8, 1, 8, 1),
                                              decoration: BoxDecoration(
                                                color:
                                                    _allRegisteredAndConnectedSensors[
                                                                    i]
                                                                .placement!
                                                                .side ==
                                                            'left'
                                                        ? Color(0xffebb63b)
                                                            .withOpacity(0.3)
                                                        : Color(0xff004457)
                                                            .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  width: 1.0,
                                                  color:
                                                      _allRegisteredAndConnectedSensors[
                                                                      i]
                                                                  .placement!
                                                                  .side ==
                                                              'left'
                                                          ? Color(0xffebb63b)
                                                          : Color(0xff004457),
                                                ),
                                              ),
                                              child: Text(
                                                  _allRegisteredAndConnectedSensors[
                                                          i]
                                                      .placement!
                                                      .side
                                                      .toString(),
                                                  style: AppTheme.appDarkTheme
                                                      .textTheme.caption
                                                      ?.copyWith(
                                                    color:
                                                        _allRegisteredAndConnectedSensors[
                                                                        i]
                                                                    .placement!
                                                                    .side ==
                                                                'left'
                                                            ? Color(0xffebb63b)
                                                            : Color(0xff004457),
                                                  )),
                                            )
                                        ],
                                      ),
                                    ),
                                    AppIconButton(
                                      iconData: Icons.delete,
                                      onPressed: () {
                                        _allRegisteredAndConnectedSensors[i]
                                            .placement = null;

                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // - Start searching button
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                if (!_isLoading && _allRegisteredAndConnectedSensors.isEmpty)
                  AppBottom(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        _searchController.startScanner();
                        await Future.delayed(Duration(seconds: 2));
                        _searchController.stopScanner();
                        _searchController.startScanner();
                        await Future.delayed(Duration(seconds: 4));
                        _searchController.stopScanner();
                        _searchController.startScanner();
                        await Future.delayed(Duration(seconds: 6));
                        _searchController.stopScanner();

                        _initRegisteredSensorsDBAsync();
                      },
                      mainText: 'Start Searching'),
                if (!_isLoading && _allRegisteredAndConnectedSensors.isNotEmpty)
                  AppBottom(
                    onPressed: () {
                      Get.off(() => SessionMonitorScreen(
                          client: widget.client,
                          allSensorsUsedInSession:
                              _allRegisteredAndConnectedSensors));
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
    /// Connect to the registered and discovered sensors:
    if (_allRegisteredAndFoundSensors.isNotEmpty) {
      _isLoading = true;

      // List with the registered sensors to which we will connect
      List<SensorUsedInSession> registeredAndConnectedSensors = [];

      for (var info in _allRegisteredAndFoundSensors) {
        log('CONNECTING...');
        var connectedSensor = await Sensor.create(info);

        int connectedSensorBattery = await connectedSensor.battery.value;
        CallibriColorType connectedSensorColor =
            await connectedSensor.color.value;
        String connectedSensorAddress = await connectedSensor.address.value;

        registeredAndConnectedSensors.add(
          SensorUsedInSession(
              battery: connectedSensorBattery,
              color: buildColorNameFromSensor(
                  rawSensorNameAndColor: '$connectedSensorColor'),
              address: connectedSensorAddress,
              isSelectedToAssignPlacement: false,
              sensor: connectedSensor,
              listEnvSamplesValuesForGraphic: [0],
              envelopeValuesForAnalytics: EnvelopeValuesForAnalytics(
                  address: info.address, listEnvSamplesValuesForStatistics: []),
              chartData: [ChartSampleData(x: 0, y: 0)],
              columnChartData: []),
        );
      }
      _allRegisteredAndConnectedSensors = registeredAndConnectedSensors;

      _allRegisteredAndFoundSensors.clear();
      _searchController.dispose();
    }
    _isLoading = false;
    setState(() {});
  }
}

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
      padding: const EdgeInsets.fromLTRB(65, 60, 65, 5),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => notifyParentPlacementSelected(cardPlacement),
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
                  const Positioned(
                    left: 8,
                    top: 8,
                    child: Icon(
                      Icons.help_rounded,
                      color: Color(0xff767676),
                    ),
                  ),
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
        if (selectedPlacement.muscleName == cardPlacement.muscleName)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AppOutlinedButton(
                child: Text('Left',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    )),
                action: () {
                  selectedPlacement.side = 'left';
                  notifyParentSideSelected(selectedPlacement);
                },
                color: Color(0xffebb63b),
                buttonSize: ButtonSize.medium,
              ),
              const SizedBox(width: 24),
              AppOutlinedButton(
                action: () {
                  selectedPlacement.side = 'right';
                  notifyParentSideSelected(selectedPlacement);
                },
                color: Color(0xff004457),
                buttonSize: ButtonSize.medium,
                child: Text('Right',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    )),
              )
            ],
          )
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
