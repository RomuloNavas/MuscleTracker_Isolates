import 'dart:async';
import 'dart:math' as math;
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/workout_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/session/session_results.dart';
import 'package:neuro_sdk_isolate_example/screens/session/session_setup_screen.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/build_from_sensor.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:wakelock/wakelock.dart';
// import 'dart:developer';
// import 'package:f_logs/f_logs.dart';

class ControllerDeviceScreenMultiple extends GetxController {
  var currentValueOnX = 0.obs;
  RxList<Workout> sessionProgress = <Workout>[].obs;
}

class SessionMonitorScreen extends StatefulWidget {
  List<SensorUsedInSession> allSensorsUsedInSession;
  final Client client;

  SessionMonitorScreen({
    Key? key,
    required this.allSensorsUsedInSession,
    required this.client,
  }) : super(key: key);

  @override
  State<SessionMonitorScreen> createState() => _SessionMonitorScreenState();
}

class _SessionMonitorScreenState extends State<SessionMonitorScreen> {
  static Timer? _timerUpdateChart;
  static Timer? _timerUpdateConnectionStatus;
  static Timer? _timerReconnect;
  static Timer? _timerAddCerosToDisconnectedDevice;
  static Timer? _timerSyncEnvValuesForAnalytics;
  static Timer? _timerAreSensorsConnected;

  bool envelopeStarted = false;
  late String _sessionStartedAt;
  String sessionEndedAt = "Session haven't finished";

  bool isRecording = false;

  /// currentWorkout is created the moment user starts recording
  Workout? _currentWorkout;
  List<Workout> _completedWorkouts = [];

  /// currentWorkout value can be changed only if isRecording == true.
  Exercise _selectedExercise = Exercise(id: 0, name: 'Unknown');

  /// Variable used to prevent reconnection to disconnected device, after the session has finished.
  bool _isSessionFinished = false;

  bool isPaused = false;
  CallibriEnvelopeData envelopeData = CallibriEnvelopeData();
  int flutterCounter = 0;
  double sidebarWidth = 260;

  late FixedExtentScrollController _scrollController;

  List<double> maxV = [
    0.01,
    0.005,
    0.002,
    0.001,
    0.0005,
    0.0002,
    0.0001,
    0.00005,
  ];

  int maxVIndex = 3;

  List<Exercise> allExercises = [];
  late Future initAllExercises;

  @override
  void initState() {
    super.initState();
    initAllExercises = _getAllExercises();
    _sessionStartedAt = DateTime.now().toIso8601String();
    _scrollController = FixedExtentScrollController();

    Wakelock.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollController.jumpToItem(maxVIndex));
  }

  @override
  void dispose() {
    Wakelock.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.dispose();
  }

  @override
  void deactivate() {
    log('Deactivating....');
    _timerAddCerosToDisconnectedDevice?.cancel();
    _timerReconnect?.cancel();
    _timerUpdateChart?.cancel();
    _timerUpdateConnectionStatus?.cancel();
    log('Timers canceled');
    super.deactivate();
  }

  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final ControllerDeviceScreenMultiple controllerChartMultiple =
        Get.put(ControllerDeviceScreenMultiple());

    return Scaffold(
      backgroundColor: Get.isDarkMode
          ? AppTheme.appDarkTheme.scaffoldBackgroundColor
          : AppTheme.appTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: (widget.allSensorsUsedInSession.isNotEmpty)
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0;
                            i < widget.allSensorsUsedInSession.length;
                            i++)
                          buildChartFromSensor(
                            context: context,
                            controllerChartMultiple: controllerChartMultiple,
                            connectedSensorUsedInSession:
                                widget.allSensorsUsedInSession[i],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                        top: 12, left: 8, right: 8, bottom: 12),
                    width: sidebarWidth,
                    color: Get.isDarkMode
                        ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                        : AppTheme.appTheme.scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppIconButton(
                                svgIconPath: 'check',
                                iconColor: Theme.of(context).colorScheme.error,
                                size: ButtonSize.big,
                                onPressed: () async {
                                  _isSessionFinished = true;
                                  sessionEndedAt =
                                      DateTime.now().toIso8601String();
                                  _cancelAllTimers();

                                  for (var i = 0;
                                      i < widget.allSensorsUsedInSession.length;
                                      i++) {
                                    await Future.delayed(
                                        const Duration(milliseconds: 400));

                                    widget.allSensorsUsedInSession[i].sensor
                                        .executeCommand(
                                            SensorCommand.stopEnvelope);
                                    widget.allSensorsUsedInSession[i].sensor
                                        .envelopeStream
                                        .dispose();
                                    log('Stop envelope: ${widget.allSensorsUsedInSession[i].sensor.name}');
                                  }
                                  for (var i = 0;
                                      i < widget.allSensorsUsedInSession.length;
                                      i++) {
                                    log('Disconnecting from: ${widget.allSensorsUsedInSession[i].sensor.name}');
                                    widget.allSensorsUsedInSession[i].sensor
                                        .disconnect();
                                    widget.allSensorsUsedInSession[i].sensor
                                        .dispose();
                                  }
                                  await Future.delayed(Duration(seconds: 1));

                                  var usedSensors = <SensorInfoForResults>[];
                                  for (var i = 0;
                                      i < widget.allSensorsUsedInSession.length;
                                      i++) {
                                    var sensorColor = widget
                                        .allSensorsUsedInSession[i].color!;
                                    var sensorAddress = widget
                                        .allSensorsUsedInSession[i].address!;
                                    var sensorPlacement = widget
                                            .allSensorsUsedInSession[i]
                                            .placement ??
                                        Placement(
                                            muscleName: 'Unsigned muscle',
                                            bodyRegionId: 0);
                                    var sensorInfoForResults =
                                        SensorInfoForResults(
                                      color: sensorColor,
                                      address: sensorAddress,
                                      sensorPlacement: sensorPlacement,
                                    );
                                    usedSensors.add(sensorInfoForResults);
                                  }

                                  Get.off(() {
                                    return SessionResultsScreen(
                                      client: widget.client,
                                      usedSensors: usedSensors,
                                      completedWorkouts: _completedWorkouts,
                                      sessionStartedAt: _sessionStartedAt,
                                      sessionEndedAt: sessionEndedAt,
                                    );
                                  });
                                }),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Controls',
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.headline5
                                  : AppTheme.appTheme.textTheme.headline5),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          color: Get.isDarkMode
                              ? AppTheme.appDarkTheme.colorScheme.surface
                              : AppTheme.appTheme.colorScheme.surface,
                          child: Column(
                            // crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 16, 0, 16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                                isRecording ? 'Stop' : 'Record',
                                                style: Get.isDarkMode
                                                    ? AppTheme.appDarkTheme
                                                        .textTheme.overline
                                                        ?.copyWith(fontSize: 13)
                                                    : AppTheme.appTheme
                                                        .textTheme.overline
                                                        ?.copyWith(
                                                            fontSize: 13)),
                                            AppIconButton(
                                                size: ButtonSize.big,
                                                svgIconPath: isRecording
                                                    ? 'stop'
                                                    : 'record',
                                                iconColor: isRecording
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .tertiary
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                onPressed: () {
                                                  setState(() {
                                                    isRecording = !isRecording;
                                                  });
                                                  if (isRecording) {
                                                    // log('RECORDING');
                                                    _currentWorkout = Workout(
                                                        exercise:
                                                            _selectedExercise,
                                                        startedAt:
                                                            DateTime.now());
                                                    for (var sensorUsedInSession
                                                        in widget
                                                            .allSensorsUsedInSession) {
                                                      sensorUsedInSession
                                                          .envelopeValuesForAnalytics
                                                          .listEnvSamplesValuesForStatistics
                                                          .clear();
                                                    }
                                                  } else {
                                                    _currentWorkout
                                                            ?.finishedAt =
                                                        DateTime.now();

                                                    var samplesFromElectrodes =
                                                        <SamplesFromElectrode>[];

                                                    for (var sensorUsedInSession
                                                        in widget
                                                            .allSensorsUsedInSession) {
                                                      samplesFromElectrodes.add(SamplesFromElectrode(
                                                          sensorPlacement: sensorUsedInSession
                                                                      .placement !=
                                                                  null
                                                              ? sensorUsedInSession
                                                                  .placement!
                                                              : Placement(
                                                                  muscleName:
                                                                      'Muscle not assigned'),
                                                          sensorAddress:
                                                              sensorUsedInSession
                                                                  .address!,
                                                          sensorColor:
                                                              sensorUsedInSession
                                                                  .color!,
                                                          samples: List.from(
                                                              sensorUsedInSession
                                                                  .envelopeValuesForAnalytics
                                                                  .listEnvSamplesValuesForStatistics)));
                                                    }
                                                    _currentWorkout!
                                                            .samplesFromElectrodes =
                                                        samplesFromElectrodes;
                                                    _completedWorkouts
                                                        .add(_currentWorkout!);
                                                  }
                                                }),
                                          ],
                                        ),
                                        if (envelopeStarted == true)
                                          Column(
                                            children: [
                                              Text(
                                                  isPaused
                                                      ? 'Continue'
                                                      : 'Pause',
                                                  style: Get.isDarkMode
                                                      ? AppTheme.appDarkTheme
                                                          .textTheme.overline
                                                          ?.copyWith(
                                                              fontSize: 13)
                                                      : AppTheme.appTheme
                                                          .textTheme.overline
                                                          ?.copyWith(
                                                              fontSize: 13)),
                                              AppIconButton(
                                                  size: ButtonSize.big,
                                                  svgIconPath: isPaused
                                                      ? 'play'
                                                      : 'pause',
                                                  iconColor: isPaused
                                                      ? Theme.of(context)
                                                          .shadowColor
                                                      : Color(0xff838997),
                                                  onPressed: () {
                                                    isPaused = !isPaused;
                                                    if (isPaused == true) {
                                                      _timerUpdateChart!
                                                          .cancel();
                                                    } else {
                                                      startTimerUpdateChart();
                                                    }
                                                    setState(() {});
                                                  }),
                                            ],
                                          ),
                                        if (envelopeStarted == false)
                                          Column(
                                            children: [
                                              Text('Start',
                                                  style: Get.isDarkMode
                                                      ? AppTheme.appDarkTheme
                                                          .textTheme.overline
                                                          ?.copyWith(
                                                              fontSize: 13)
                                                      : AppTheme.appTheme
                                                          .textTheme.overline
                                                          ?.copyWith(
                                                              fontSize: 13)),
                                              AppIconButton(
                                                size: ButtonSize.big,
                                                svgIconPath: 'play',
                                                iconColor: Get.isDarkMode
                                                    ? AppTheme.appDarkTheme
                                                        .colorScheme.primary
                                                        .withAlpha(200)
                                                    : AppTheme.appTheme
                                                        .colorScheme.primary
                                                        .withAlpha(200),
                                                onPressed: () async {
                                                  if (envelopeStarted ==
                                                      false) {
                                                    _sessionStartedAt =
                                                        DateTime.now()
                                                            .toIso8601String();
                                                    // log('ENVELOPE STARTED');
                                                    setState(() {
                                                      envelopeStarted = true;
                                                    });

                                                    // - CALLBACK: START ELECTRODE STATE
                                                    for (var sensorUsedInSession
                                                        in widget
                                                            .allSensorsUsedInSession) {
                                                      sensorUsedInSession.sensor
                                                          .electrodeStateStream
                                                          .init();
                                                      Stream
                                                          sensorEnvelopeStream =
                                                          sensorUsedInSession
                                                              .sensor
                                                              .electrodeStateStream
                                                              .stream;

                                                      sensorEnvelopeStream
                                                          .listen(
                                                              (electrodeState) {
                                                        if (sensorUsedInSession
                                                                .electrodeState !=
                                                            electrodeState) {
                                                          sensorUsedInSession
                                                              .countLastElectrodeState = 0;
                                                        }
                                                        sensorUsedInSession
                                                            .countLastElectrodeState++;
                                                        sensorUsedInSession
                                                                .electrodeState =
                                                            electrodeState;
                                                        if (sensorUsedInSession
                                                                .countLastElectrodeState ==
                                                            3) {
                                                          setState(() {});
                                                        }
                                                      });
                                                    }

                                                    // -Timer that checks if sensors are connected. When a sensor is disconnected starts functions to add ceros and reconnect to device
                                                    // log('STARTED: IS CONNECTED?');
                                                    _timerAreSensorsConnected =
                                                        Timer.periodic(
                                                      const Duration(
                                                          milliseconds: 225),
                                                      (_timer) {
                                                        // log('IS CONNECTED?');

                                                        for (SensorUsedInSession sensorUsedInSession
                                                            in widget
                                                                .allSensorsUsedInSession) {
                                                          bool isConnected =
                                                              sensorUsedInSession
                                                                      .signalForCheckingSensorState >
                                                                  0;

                                                          if (!isConnected &&
                                                              sensorUsedInSession
                                                                  .isConnected) {
                                                            sensorUsedInSession
                                                                    .isConnected =
                                                                false;

                                                            /// Notify about disconnection the EnvelopeValuesForAnalytics to make sync timer work faster:
                                                            sensorUsedInSession
                                                                .envelopeValuesForAnalytics
                                                                .isConnected = false;
                                                            setState(() {});
                                                            startTimerAddCerosToDisconnectedDevice();
                                                            startTimerReconnect();
                                                          }
                                                          if (isConnected &&
                                                              sensorUsedInSession
                                                                      .isConnected ==
                                                                  false) {
                                                            sensorUsedInSession
                                                                    .isConnected =
                                                                true;

                                                            /// Notify about connection the EnvelopeValuesForAnalytics to make sync timer work normally:
                                                            sensorUsedInSession
                                                                .envelopeValuesForAnalytics
                                                                .isConnected = true;
                                                            stopReconnectingTimer();
                                                            stopTimerAddCerosToDisconnectedDevice();
                                                            setState(() {});
                                                          }
                                                          sensorUsedInSession
                                                              .signalForCheckingSensorState = 0;
                                                        }
                                                      },
                                                    );

                                                    // - Timer to synchronize EnvValues for Analytics

                                                    // log('STARTED: SYNC ENV VALUES');
                                                    _timerSyncEnvValuesForAnalytics =
                                                        Timer.periodic(
                                                            const Duration(
                                                                milliseconds:
                                                                    200), (Timer
                                                                timerSyncEnvValues) {
                                                      // log('SYNC ENV VALUES');
                                                      final sensorsEnvelopeValuesForAnalytics =
                                                          List.generate(
                                                              widget
                                                                  .allSensorsUsedInSession
                                                                  .length,
                                                              (i) => widget
                                                                  .allSensorsUsedInSession[
                                                                      i]
                                                                  .envelopeValuesForAnalytics);

                                                      sensorsEnvelopeValuesForAnalytics
                                                          .sort((a, b) => a
                                                              .listEnvSamplesValuesForStatistics
                                                              .length
                                                              .compareTo(b
                                                                  .listEnvSamplesValuesForStatistics
                                                                  .length));

                                                      for (var i = 0;
                                                          i <
                                                              widget.allSensorsUsedInSession
                                                                      .length -
                                                                  1;
                                                          i++) {
                                                        EnvelopeValuesForAnalytics
                                                            currentSensorAnalytics =
                                                            sensorsEnvelopeValuesForAnalytics[
                                                                i];
                                                        EnvelopeValuesForAnalytics
                                                            nextSensorAnalytics =
                                                            sensorsEnvelopeValuesForAnalytics[
                                                                i + 1];

                                                        int difference = nextSensorAnalytics
                                                                .listEnvSamplesValuesForStatistics
                                                                .length -
                                                            currentSensorAnalytics
                                                                .listEnvSamplesValuesForStatistics
                                                                .length;
                                                        if (difference >= 4 &&
                                                            !nextSensorAnalytics
                                                                .isConnected) {
                                                          nextSensorAnalytics
                                                              .listEnvSamplesValuesForStatistics
                                                              .removeRange(
                                                                  nextSensorAnalytics
                                                                          .listEnvSamplesValuesForStatistics
                                                                          .length -
                                                                      difference,
                                                                  nextSensorAnalytics
                                                                      .listEnvSamplesValuesForStatistics
                                                                      .length);
                                                          nextSensorAnalytics
                                                                  .countRemovedValues +=
                                                              difference;
                                                        } else if (difference >
                                                                3 &&
                                                            nextSensorAnalytics
                                                                .isConnected) {
                                                          nextSensorAnalytics
                                                              .listEnvSamplesValuesForStatistics
                                                              .removeLast();
                                                          nextSensorAnalytics
                                                              .countRemovedValues++;
                                                        }
                                                      }
                                                    });

                                                    //- TIMER UPDATE GRAPHIC
                                                    startTimerUpdateChart();

                                                    _startCallibriEnvelopeCallback(
                                                      widget
                                                          .allSensorsUsedInSession,
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Amplitude',
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.headline5
                                  : AppTheme.appTheme.textTheme.headline5),
                        ),
                        SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          color: Get.isDarkMode
                              ? AppTheme.appDarkTheme.colorScheme.surface
                              : AppTheme.appTheme.colorScheme.surface,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 60,
                                child: ListWheelScrollView.useDelegate(
                                  controller: _scrollController,
                                  itemExtent: 23,
                                  perspective: 0.001,
                                  diameterRatio: 0.9,
                                  onSelectedItemChanged: (value) =>
                                      setState(() {
                                    maxVIndex = value;
                                  }),
                                  physics: const FixedExtentScrollPhysics(),
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: maxV.length,
                                    builder: (context, i) {
                                      return Center(
                                        child: Text(
                                            buildTextFromAmplitude(
                                                amplitude: maxV[i]),
                                            style: Get.isDarkMode
                                                ? AppTheme.appDarkTheme
                                                    .textTheme.caption
                                                : AppTheme.appTheme.textTheme
                                                    .caption),
                                      );
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),

                        ///SESSION PROGRESS
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Session Progress',
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.headline5
                                  : AppTheme.appTheme.textTheme.headline5),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          color: Get.isDarkMode
                              ? AppTheme.appDarkTheme.colorScheme.surface
                              : AppTheme.appTheme.colorScheme.surface,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Get.isDarkMode
                                      ? AppTheme
                                          .appDarkTheme.colorScheme.primary
                                          .withAlpha(200)
                                      : AppTheme.appTheme.colorScheme.primary
                                          .withAlpha(200),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 180,
                                            child: Text(
                                              _selectedExercise.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                              style: AppTheme
                                                  .appTheme.textTheme.bodyText2
                                                  ?.copyWith(
                                                      color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                        constraints: BoxConstraints(
                                            minWidth: sidebarWidth - 16,
                                            maxHeight: 200),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        elevation: 0.2,
                                        color: Get.isDarkMode
                                            ? AppTheme.appDarkTheme.colorScheme
                                                .surface
                                            : AppTheme
                                                .appTheme.colorScheme.surface,
                                        position: PopupMenuPosition.under,
                                        offset: Offset(8, 10),
                                        // position: PopupMenuPosition.over,
                                        // offset: Offset(48, -10),
                                        splashRadius: 36,
                                        icon: Icon(
                                          Icons.expand_more_outlined,
                                          size: 32,
                                          color: Colors.white,
                                        ),
                                        itemBuilder: (context) => [
                                              for (var i = 0;
                                                  i < allExercises.length;
                                                  i++)
                                                PopupMenuItem(
                                                  value: allExercises[i],
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedExercise =
                                                          allExercises[i];
                                                    });
                                                  },
                                                  child: Text(
                                                      allExercises[i].name,
                                                      style: Get.isDarkMode
                                                          ? AppTheme
                                                              .appDarkTheme
                                                              .textTheme
                                                              .bodyText1
                                                          : AppTheme
                                                              .appTheme
                                                              .textTheme
                                                              .bodyText1),
                                                ),
                                            ]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: scrollController,
                            thickness: 4,
                            trackVisibility: true,
                            thumbVisibility: true,
                            child: ListView(
                              // shrinkWrap: true,
                              controller: scrollController,
                              children: [
                                for (var i = 0;
                                    i < _completedWorkouts.length;
                                    i++)
                                  Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(2, 4, 2, 4),
                                    margin:
                                        const EdgeInsets.fromLTRB(0, 4, 0, 0),
                                    decoration: BoxDecoration(
                                      color: Get.isDarkMode
                                          ? AppTheme
                                              .appDarkTheme.colorScheme.surface
                                          : AppTheme
                                              .appTheme.colorScheme.surface,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        AppIconButton(
                                            svgIconPath: 'trash',
                                            onPressed: () {
                                              _completedWorkouts.removeAt(i);
                                              setState(() {});
                                            }),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 2),
                                              Text(
                                                _completedWorkouts[i]
                                                    .exercise
                                                    .name,
                                                style: Get.isDarkMode
                                                    ? AppTheme.appDarkTheme
                                                        .textTheme.bodyText2
                                                        ?.copyWith(
                                                            color: const Color(
                                                                0xff7a7575))
                                                    : AppTheme.appTheme
                                                        .textTheme.bodyText2
                                                        ?.copyWith(
                                                            color: const Color(
                                                                0xff444547)),
                                              ),
                                              Text(
                                                getMinutesAndSecondsFromDuration(
                                                    duration: _completedWorkouts[
                                                            i]
                                                        .finishedAt!
                                                        .difference(
                                                            _completedWorkouts[
                                                                    i]
                                                                .startedAt!)),
                                                style: Get.isDarkMode
                                                    ? AppTheme.appDarkTheme
                                                        .textTheme.bodyText2
                                                        ?.copyWith(
                                                            color: const Color(
                                                                0xff444547))
                                                    : AppTheme.appTheme
                                                        .textTheme.bodyText2
                                                        ?.copyWith(
                                                            color: const Color(
                                                                0xff444547)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(
                child: Text("No devices"),
              ),
      ),
    );
  }

  void _cancelAllTimers() {
    if (_timerUpdateChart != null) {
      _timerUpdateChart!.cancel();
      _timerUpdateChart = null;
      log('CANCELED TIMER: _timerUpdateChart');
    }
    if (_timerUpdateConnectionStatus != null) {
      _timerUpdateConnectionStatus!.cancel();
      _timerUpdateConnectionStatus = null;
      log('CANCELED TIMER: _timerUpdateConnectionStatus');
    }
    if (_timerReconnect != null) {
      _timerReconnect!.cancel();
      _timerReconnect = null;
      log('CANCELED TIMER: _timerReconnect');
    }
    if (_timerAddCerosToDisconnectedDevice != null) {
      _timerAddCerosToDisconnectedDevice!.cancel();
      _timerAddCerosToDisconnectedDevice = null;
      log('CANCELED TIMER: _timerAddCerosToDisconnectedDevice');
    }

    if (_timerSyncEnvValuesForAnalytics != null) {
      _timerSyncEnvValuesForAnalytics!.cancel();
      _timerSyncEnvValuesForAnalytics = null;
      log('CANCELED TIMER: _timerSyncEnvValuesForAnalytics');
    }
    if (_timerAreSensorsConnected != null) {
      _timerAreSensorsConnected!.cancel();
      _timerAreSensorsConnected = null;
      log('CANCELED TIMER: _timerAreSensorsConnected');
    }
  }

  // -  Adds ceros (0) to sensor.listEnvSamplesValues when sensor is disconnected
  void startTimerAddCerosToDisconnectedDevice() {
    if (_isSessionFinished == false) {
      // log('STARTED _timerAddCerosToDisconnectedDevice');

      _timerAddCerosToDisconnectedDevice = Timer.periodic(
          const Duration(milliseconds: 30), (addCeroTimerInside) {
        // log('timerAddCerosToDisconnectedDevice');
        List<SensorUsedInSession> listOfDisconnectedSensors = widget
            .allSensorsUsedInSession
            .where((s) => s.envelopeValuesForAnalytics.isConnected == false)
            .toList();

        for (var disconnectedSensor in listOfDisconnectedSensors) {
          disconnectedSensor.listEnvSamplesValuesForGraphic.add(0);
          disconnectedSensor
              .envelopeValuesForAnalytics.listEnvSamplesValuesForStatistics
              .add(0);
        }
      });
    }
  }

  // - Reconnect timer: Will try to reconnect to sensor each 20 seconds
  void startTimerReconnect() {
    if (_isSessionFinished == false) {
      // log('STARTED: RECONNECT');

      _timerReconnect =
          Timer.periodic(const Duration(seconds: 20), (timerTryToReconnect) {
        // log('RECONNECT');
        if (_isSessionFinished == false) {
          List<SensorUsedInSession> listOfDisconnectedSensors = widget
              .allSensorsUsedInSession
              .where((s) => s.isConnected == false)
              .toList();

          for (var disconnectedSensor in listOfDisconnectedSensors) {
            disconnectedSensor.sensor.connect();

            Future.delayed(const Duration(seconds: 2), () {
              try {
                disconnectedSensor.sensor
                    .executeCommand(SensorCommand.startEnvelope);
              } catch (e) {
                log("Couldn't start envelope of sensor ${disconnectedSensor.sensor.name}: $e",
                    name: 'session_monitor_screen.dart');
              }
            });
          }
        }
      });
    }
  }

  void stopReconnectingTimer() {
    if (_timerReconnect != null) {
      // log('RECONNECTING TIMER CANCELED');
      _timerReconnect!.cancel();
    } else {
      // log('RECONNECTING IS NULL');
    }
  }

  void stopTimerAddCerosToDisconnectedDevice() {
    log('TIMER ADD 0 CANCELED');
    _timerAddCerosToDisconnectedDevice?.cancel();
  }

  Future<void> _getAllExercises() async {
    var receivedData = await ExerciseOperations().getAllWorkouts();
    allExercises = List.from(receivedData.toList());
    setState(() {});
  }

  String buildTextFromAmplitude({required double amplitude}) {
    String amplitudeText = '$amplitude';
    if (amplitude <= 0.01 && amplitude > 0.0009) {
      amplitudeText = '${(amplitude * 1000).toInt()}mV';
    } else if (amplitude <= 0.0009 && amplitude > 0) {
      amplitudeText = '${(amplitude * 1000000).toInt()}μV';
    }
    return amplitudeText;
  }

  startTimerUpdateChart() {
    // log('STARTED: UPDATE CHART');
    _timerUpdateChart =
        Timer.periodic(const Duration(milliseconds: 25), (timer) {
      // log('UPDATE CHART');

      // if (isPaused == true) {
      //   timer.cancel();
      // }
      List<int> smallestListLength = List.generate(
          widget.allSensorsUsedInSession.length,
          (i) => widget.allSensorsUsedInSession[i]
              .listEnvSamplesValuesForGraphic.length);
      smallestListLength.sort((a, b) => a.compareTo(b));

      if (smallestListLength.first > 1) {
        smallestListLength = [1];
      }

      if (smallestListLength.first > 0) {
        for (var s in widget.allSensorsUsedInSession) {
          if (s.chartData.length >= 100) {
            s.chartData.removeRange(0, smallestListLength.first);
            for (int i = 0; i < smallestListLength.first; i++) {
              s.chartData.add(
                ChartSampleData(
                  x: s.xValueCounter,
                  y: s.listEnvSamplesValuesForGraphic[i],
                ),
              );

              s.xValueCounter++;
            }

            final List<int> indexes = <int>[];

            for (int i = s.chartData.length - 1; i >= 0; i--) {
              indexes.add(s.chartData.length - 1 - i);
            }
            List<int> removedIndexes =
                List.generate(s.chartData.length, (index) => index);

            s.chartSeriesController?.updateDataSource(
              removedDataIndexes: removedIndexes,
              addedDataIndexes: indexes,
              updatedDataIndexes: removedIndexes,
            );
            s.listEnvSamplesValuesForGraphic.clear();
          } else {
            if (s.chartData.isNotEmpty) {
              for (int i = 0;
                  i <
                      s.listEnvSamplesValuesForGraphic
                          .length; //!!!use the smallest list length
                  i++) {
                s.chartData.add(ChartSampleData(
                    x: s.xValueCounter,
                    y: s.listEnvSamplesValuesForGraphic[i]));
                s.xValueCounter++;
              }

              /// Returns the newly added indexes value.
              final List<int> indexes = <int>[];
              for (int i = s.listEnvSamplesValuesForGraphic.length - 1;
                  i >= 0;
                  i--) {
                indexes.add(s.chartData.length - 1 - i);
              }

              /// Update chart
              s.chartSeriesController?.updateDataSource(
                addedDataIndexes: indexes,
              );
              s.listEnvSamplesValuesForGraphic.clear();
            }
          }
        }
      }
    });
  }

  Widget buildChartFromSensor({
    required BuildContext context,
    required ControllerDeviceScreenMultiple controllerChartMultiple,
    required SensorUsedInSession connectedSensorUsedInSession,
  }) {
    final List<double> stops = <double>[];
    stops.add(0.0);
    stops.add(0.5);
    stops.add(1.0);

    // double columnChartWidth = 50;

    final List<Color> color = <Color>[];

    final LinearGradient gradientColors =
        LinearGradient(colors: color, stops: stops);

    Color deviceColor = buildColorFromSensorName(
        rawSensorNameAndColor: connectedSensorUsedInSession.color!);

    return Row(
      children: [
        Container(
          height: (MediaQuery.of(context).size.height /
                  widget.allSensorsUsedInSession.length) -
              32 / widget.allSensorsUsedInSession.length,
          width: MediaQuery.of(context).size.width -
              sidebarWidth -
              16, // add (minus) - columnChartWidth if column is added

          child: SfCartesianChart(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),

            title: ChartTitle(
              alignment: ChartAlignment.near,
              text: buildTextForChart(connectedSensorUsedInSession),
              textStyle: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.caption
                  : AppTheme.appTheme.textTheme.caption,
            ),

            series: <CartesianSeries>[
              AreaSeries<ChartSampleData, int>(
                onRendererCreated: (ChartSeriesController controller) {
                  connectedSensorUsedInSession.chartSeriesController =
                      controller;
                },
                dataSource: connectedSensorUsedInSession.chartData,
                xValueMapper: (ChartSampleData sales, _) => sales.x,
                yValueMapper: (ChartSampleData sales, _) => sales.y,
                color: buildColorFromSensorName(
                    rawSensorNameAndColor: connectedSensorUsedInSession.color!),
                // gradient: buildGradientFromCallibriColor(
                //     connectedSensorUsedInSession.color!),
                borderColor: buildColorFromSensorName(
                    rawSensorNameAndColor: connectedSensorUsedInSession.color!),
                borderWidth: 3,
              ),
            ],

            primaryXAxis: NumericAxis(
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              isVisible: false,
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,

              maximum: maxV[maxVIndex],
              isVisible: false,
              labelFormat: '{value}mV',
              // labelStyle: TextStyle(color: Colors.transparent),
              rangePadding: ChartRangePadding.none,
            ),

            borderColor: Get.isDarkMode
                ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                : AppTheme.appTheme.scaffoldBackgroundColor, //frame of widgetƑ
            backgroundColor: Get.isDarkMode
                ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                : AppTheme
                    .appTheme.scaffoldBackgroundColor, // Background of frame
            // plotAreaBackgroundColor: Get.isDarkMode
            //     ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            //     : AppTheme.appTheme.scaffoldBackgroundColor, // main background
            plotAreaBackgroundColor: buildPlotAreaBackgroundColorFromSensor(
                connectedSensorUsedInSession:
                    connectedSensorUsedInSession), // main background
            plotAreaBorderColor: Get.isDarkMode
                ? AppTheme.appDarkTheme.colorScheme.outline
                : const Color(
                    0xff7a7575), // Thick line, the last one at the top
            borderWidth: 4,
          ),
        ),
      ],
    );
  }
}

class ChartSampleData {
  ChartSampleData({required this.x, required this.y});

  final int x;
  final double y;
}

Color buildPlotAreaBackgroundColorFromSensor(
    {required SensorUsedInSession connectedSensorUsedInSession}) {
  Color plotAreaBackgroundColor = Get.isDarkMode
      ? AppTheme.appDarkTheme.scaffoldBackgroundColor
      : AppTheme.appTheme.scaffoldBackgroundColor;
  if (connectedSensorUsedInSession.electrodeState !=
      CallibriElectrodeState.elStNormal) {
    plotAreaBackgroundColor =
        AppTheme.appTheme.colorScheme.error.withOpacity(0.5);
  }
  if (connectedSensorUsedInSession.isConnected == false) {
    plotAreaBackgroundColor =
        AppTheme.appTheme.colorScheme.error.withOpacity(0.7);
  }

  return plotAreaBackgroundColor;
}

String buildTextForChart(SensorUsedInSession connectedSensorUsedInSession) {
  String sensorName = 'Callibri ${connectedSensorUsedInSession.color!}';
  String textForChart = connectedSensorUsedInSession.placement != null
      ? '$sensorName - ${connectedSensorUsedInSession.placement!.muscleName} ${connectedSensorUsedInSession.placement?.side != null ? '- ${connectedSensorUsedInSession.placement!.side}' : ""}'
      : sensorName;

// REMOVED TO AVOID SET STATE
  if (connectedSensorUsedInSession.electrodeState !=
      CallibriElectrodeState.elStNormal) {
    switch (connectedSensorUsedInSession.electrodeState) {
      case CallibriElectrodeState.elStDetached:
        textForChart = '$sensorName - ELECTRODE DETACHED';
        break;
      case CallibriElectrodeState.elStHighResistance:
        textForChart = '$sensorName - HIGH RESISTANCE';
        break;

      case CallibriElectrodeState.elStNormal:
        break;
    }
  }
  if (connectedSensorUsedInSession.isConnected == false) {
    textForChart = '$sensorName DISCONNECTED';
  }
  return textForChart;
}

void _startCallibriEnvelopeCallback(
    List<SensorUsedInSession> allSensorsUsedInSession) {
  for (var i = 0; i < allSensorsUsedInSession.length; i++) {
    SensorUsedInSession sensorUsedInSession = allSensorsUsedInSession[i];
    if (sensorUsedInSession.sensor.isSupportedFeature(SensorFeature.envelope)) {
      sensorUsedInSession.sensor.envelopeStream.init();
      sensorUsedInSession.sensor.envelopeStream.stream.listen((listEnvData) {
        if (listEnvData.isNotEmpty) {
          for (var envData in listEnvData) {
            sensorUsedInSession.listEnvSamplesValuesForGraphic
                .add(envData.sample);

            // SAVE VALUES IN BUFFER FOR FURTHER STATISTICS
            sensorUsedInSession
                .envelopeValuesForAnalytics.listEnvSamplesValuesForStatistics
                .add(envData.sample);
          }

          // Counter to see if the devices is disconnected
          sensorUsedInSession.signalForCheckingSensorState++;
        }
      });
      try {
        sensorUsedInSession.sensor.executeCommand(SensorCommand.startEnvelope);
      } catch (e) {
        log("Couldn't start envelope of sensor ${sensorUsedInSession.sensor.name}: $e",
            name: 'session_monitor_screen.dart');
      }
    } else {
      log("${sensorUsedInSession.address} doesn't support envelope");
    }
  }
}

class Workout {
  Workout({
    required this.exercise,
    required this.startedAt,
    this.finishedAt,
    this.samplesFromElectrodes,
  });
  final Exercise exercise;
  final DateTime? startedAt;
  late DateTime? finishedAt;
  late List<SamplesFromElectrode>? samplesFromElectrodes;

  double getMaxAmpInVFromSensor({required String sensorAddress}) {
    var allSamplesFromCurrentSensor = samplesFromElectrodes!
        .firstWhereOrNull((element) => element.sensorAddress == sensorAddress);
    double maxAmp = 0;
    if (allSamplesFromCurrentSensor != null) {
      maxAmp = allSamplesFromCurrentSensor.samples.reduce(math.max);
    }
    return maxAmp;
  }

  double getMinAmpInVFromSensor({required String sensorAddress}) {
    var allSamplesFromCurrentSensor = samplesFromElectrodes!
        .firstWhereOrNull((element) => element.sensorAddress == sensorAddress);
    double minAmp = 0;
    if (allSamplesFromCurrentSensor != null) {
      minAmp = allSamplesFromCurrentSensor.samples.reduce(math.min);
    }
    return minAmp;
  }

  double getAvrAmpInVFromSensor({required String sensorAddress}) {
    var allSamplesFromCurrentSensor = samplesFromElectrodes!
        .firstWhereOrNull((element) => element.sensorAddress == sensorAddress);
    double avrAmp = 0;
    if (allSamplesFromCurrentSensor != null) {
      avrAmp = getAverage(allSamplesFromCurrentSensor.samples);
    }
    return avrAmp;
  }

  double getAreaFromSensor({required String sensorAddress}) {
    var allSamplesFromCurrentSensor = samplesFromElectrodes!
        .firstWhereOrNull((element) => element.sensorAddress == sensorAddress);
    double area = 0;
    if (allSamplesFromCurrentSensor != null) {
      area = (allSamplesFromCurrentSensor.samples
              .reduce((value, element) => value + element)) /
          50;
    }
    return area;
  }
}

class SamplesFromElectrode {
  SamplesFromElectrode({
    required this.sensorAddress,
    required this.sensorColor,
    required this.samples,
    required this.sensorPlacement,
  });
  final String sensorAddress;
  final Placement sensorPlacement;
  final String sensorColor;
  final List<double> samples;
}

class SensorInfoForResults {
  SensorInfoForResults({
    required this.color,
    required this.address,
    required this.sensorPlacement,
  });
  final String color;
  final String address;
  final Placement sensorPlacement;
}
