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
import 'package:neuro_sdk_isolate_example/screens/client_journal/session/session_setup_screen.dart';
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
  Timer? _timerUpdateChart;
  Timer? _timerUpdateConnectionStatus;
  Timer? _timerReconnect;
  Timer? _timerAddCerosToDisconnectedDevice;

  bool envelopeStarted = false;
  String sessionStartedAt = "Signal haven't been initialized";
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
    initAllExercises = _getAllExercises();

    _scrollController = FixedExtentScrollController();

    super.initState();
    Wakelock.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollController.jumpToItem(maxVIndex));
  }

  @override
  void dispose() {
    super.dispose();
    _timerAddCerosToDisconnectedDevice?.cancel();
    _timerReconnect?.cancel();
    _timerUpdateChart?.cancel();
    _timerUpdateConnectionStatus?.cancel();
    log('TIMER CANCELLED');
    Wakelock.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final ControllerDeviceScreenMultiple controllerChartMultiple =
        Get.put(ControllerDeviceScreenMultiple());

    return Scaffold(
      backgroundColor: Get.isDarkMode
          ? AppTheme.appDarkTheme.scaffoldBackgroundColor
          : const Color(0xffF2F3F5),
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
                                iconData: Icons.check,
                                size: ButtonSize.big,
                                onPressed: () async {
                                  _isSessionFinished = true;
                                  sessionEndedAt =
                                      DateTime.now().toIso8601String();

                                  _timerReconnect?.cancel();
                                  _timerAddCerosToDisconnectedDevice?.cancel();
                                  _timerUpdateChart?.cancel();
                                  _timerUpdateConnectionStatus?.cancel();

                                  log('TIMERS SET TO NULL');
                                  _timerReconnect = null;
                                  _timerAddCerosToDisconnectedDevice = null;
                                  _timerUpdateChart = null;
                                  _timerUpdateConnectionStatus = null;

                                  for (var i = 0;
                                      i < widget.allSensorsUsedInSession.length;
                                      i++) {
                                    await Future.delayed(
                                        const Duration(milliseconds: 800));

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
                                  // Get.off(() {
                                  //   return SessionResultsScreen(
                                  //     client: widget.client,
                                  //     usedSensors: usedSensors,
                                  //     completedWorkouts: _completedWorkouts,
                                  //     sessionStartedAt: sessionStartedAt,
                                  //     sessionEndedAt: sessionEndedAt,
                                  //   );
                                  // });
                                }),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Controls',
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.headline4
                                  : AppTheme.appTheme.textTheme.headline4),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          color: Get.isDarkMode
                              ? AppTheme.appDarkTheme.cardColor
                              : AppTheme.appTheme.cardColor,
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
                                                iconData: isRecording
                                                    ? Icons.stop_circle_rounded
                                                    : Icons
                                                        .radio_button_checked_outlined,
                                                onPressed: () {
                                                  setState(() {
                                                    isRecording = !isRecording;
                                                  });
                                                  if (isRecording) {
                                                    log('RECORDING');
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
                                                  iconData: isPaused
                                                      ? Icons.play_arrow
                                                      : Icons.pause,
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
                                                iconData: Icons.play_arrow,
                                                onPressed: () async {
                                                  if (envelopeStarted ==
                                                      false) {
                                                    sessionStartedAt =
                                                        DateTime.now()
                                                            .toIso8601String();
                                                    log('ENVELOPE STARTED');
                                                    setState(() {
                                                      envelopeStarted = true;
                                                    });

                                                    // - CALLBACK: START ELECTRODE STATE
                                                    // for (var sensorUsedInSession
                                                    //     in allSensorsUsedInSession) {
                                                    //   // ~ 1 Init sensor envelope stream
                                                    //   sensorUsedInSession
                                                    //       .sensor.electrodeStateStream
                                                    //       .init();
                                                    //   Stream
                                                    //       sensorEnvelopeStream =
                                                    //       sensorUsedInSession
                                                    //           .sensor.electrodeStateStream
                                                    //           .stream;

                                                    //   sensorEnvelopeStream
                                                    //       .listen((event) {});

                                                    // ! TODO: SENSOR STATE
                                                    // sensorUsedInSession.sensor
                                                    //         .callibriElectrodeStateCallback =
                                                    //     (electrodeState) {
                                                    //   if (sensorUsedInSession
                                                    //           .electrodeState !=
                                                    //       electrodeState) {
                                                    //     sensorUsedInSession
                                                    //         .countLastElectrodeState = 0;
                                                    //   }
                                                    //   sensorUsedInSession
                                                    //       .countLastElectrodeState++;
                                                    //   sensorUsedInSession
                                                    //           .electrodeState =
                                                    //       electrodeState;
                                                    //   if (sensorUsedInSession
                                                    //           .countLastElectrodeState ==
                                                    //       3) {
                                                    //     setState(() {});
                                                    //   }
                                                    // };
                                                    // }

                                                    // // - Reconnect timer
                                                    // void startTimerReconnect() {
                                                    //   if (_isSessionFinished ==
                                                    //       false) {
                                                    //     _timerReconnect =
                                                    //         Timer.periodic(
                                                    //             const Duration(
                                                    //                 seconds:
                                                    //                     40),
                                                    //             (timerTryToReconnect) {
                                                    //       if (_isSessionFinished ==
                                                    //           false) {
                                                    //         List<SensorUsedInSession>
                                                    //             listOfDisconnectedSensors =
                                                    //             allSensorsUsedInSession
                                                    //                 .where((s) =>
                                                    //                     s.isConnected ==
                                                    //                     false)
                                                    //                 .toList();

                                                    //         for (var disconnectedSensor
                                                    //             in listOfDisconnectedSensors) {
                                                    //           // FLog.info(
                                                    //           //     className:
                                                    //           //         disconnectedSensor
                                                    //           //             .envelopeValuesForAnalytics
                                                    //           //             .address,
                                                    //           //     methodName: '',
                                                    //           //     dataLogType: '',
                                                    //           //     text:
                                                    //           //         'TRYING TO RECONNECT...');
                                                    //           // disconnectedSensor
                                                    //           //     .sensor
                                                    //           //     .connectSensor();
                                                    //           // Future.delayed(
                                                    //           //     const Duration(
                                                    //           //         seconds:
                                                    //           //             2),
                                                    //           //     () {
                                                    //           //   disconnectedSensor
                                                    //           //       .sensor
                                                    //           //       .execCommandSensor(
                                                    //           //           SensorCommand
                                                    //           //               .startEnvelope);
                                                    //           // });
                                                    //         }
                                                    //       }
                                                    //     });
                                                    //   }
                                                    // }

                                                    void
                                                        stopReconnectingTimer() {
                                                      // log('RECONNECTING TIMER CANCELED');
                                                      _timerReconnect?.cancel();
                                                    }

                                                    void
                                                        stoptimerAddCerosToDisconnectedDevice() {
                                                      // log('TIMER ADD 0 CANCELED');
                                                      _timerAddCerosToDisconnectedDevice
                                                          ?.cancel();
                                                    }

                                                    // -  Adds ceros (0) to sensor.listEnvSamplesValues when sensor it is disconnected
                                                    // void
                                                    //     startTimerAddCerosToDisconnectedDevice() {
                                                    //   if (_isSessionFinished ==
                                                    //       false) {
                                                    //     _timerAddCerosToDisconnectedDevice =
                                                    //         Timer.periodic(
                                                    //             const Duration(
                                                    //                 milliseconds:
                                                    //                     30),
                                                    //             (addCeroTimerInside) {
                                                    //       log('STARTED _timerAddCerosToDisconnectedDevice');
                                                    //       List<SensorUsedInSession>
                                                    //           listOfDisconnectedSensors =
                                                    //           allSensorsUsedInSession
                                                    //               .where((s) =>
                                                    //                   s.envelopeValuesForAnalytics
                                                    //                       .isConnected ==
                                                    //                   false)
                                                    //               .toList();

                                                    //       for (var disconnectedSensor
                                                    //           in listOfDisconnectedSensors) {
                                                    //         //-TEST: COUNT CEROS
                                                    //         // disconnectedSensor
                                                    //         //     .envelopeValuesForAnalytics
                                                    //         //     .countCerosAdded++;

                                                    //         disconnectedSensor
                                                    //             .listEnvSamplesValuesForGraphic
                                                    //             .add(0);
                                                    //         disconnectedSensor
                                                    //             .envelopeValuesForAnalytics
                                                    //             .listEnvSamplesValuesForStatistics
                                                    //             .add(0);
                                                    //       }
                                                    //     });
                                                    //   }
                                                    // }

                                                    // -Timer that checks if sensors are connected. When a sensor is disconnected starts functions to add ceros and reconnect to device
                                                    // Timer.periodic(
                                                    //   const Duration(
                                                    //       milliseconds: 225),
                                                    //   (_timer) {
                                                    //     for (SensorUsedInSession sensorUsedInSession
                                                    //         in allSensorsUsedInSession) {
                                                    //       bool isConnected =
                                                    //           sensorUsedInSession
                                                    //                   .signalForCheckingSensorState >
                                                    //               0;

                                                    //       if (!isConnected &&
                                                    //           sensorUsedInSession
                                                    //               .isConnected) {
                                                    //         // FLog.warning(
                                                    //         //     className: '\n\n\n' +
                                                    //         //         sensorUsedInSession
                                                    //         //             .sensor
                                                    //         //             .address,
                                                    //         //     methodName: '',
                                                    //         //     dataLogType: '',
                                                    //         //     text:
                                                    //         //         '====================DISCONNECTED===================');

                                                    //         sensorUsedInSession
                                                    //                 .isConnected =
                                                    //             false;
                                                    //         // Notify about disconnection the EnvelopeValuesForAnalytics to make sync timer work faster
                                                    //         sensorUsedInSession
                                                    //             .envelopeValuesForAnalytics
                                                    //             .isConnected = false;
                                                    //         setState(() {});
                                                    //         startTimerAddCerosToDisconnectedDevice();
                                                    //         startTimerReconnect();
                                                    //       }
                                                    //       if (isConnected &&
                                                    //           sensorUsedInSession
                                                    //                   .isConnected ==
                                                    //               false) {
                                                    //         // FLog.warning(
                                                    //         //     className: '\n\n' +
                                                    //         //         sensorUsedInSession
                                                    //         //             .sensor
                                                    //         //             .address,
                                                    //         //     methodName: '',
                                                    //         //     dataLogType: '',
                                                    //         //     text:
                                                    //         //         '========RECONNECTED=========');
                                                    //         // log('RECONNECTED ${sensorUsedInSession.sensor.name}');
                                                    //         sensorUsedInSession
                                                    //                 .isConnected =
                                                    //             true;
                                                    //         // Notify about connection the EnvelopeValuesForAnalytics to make sync timer work normally
                                                    //         sensorUsedInSession
                                                    //             .envelopeValuesForAnalytics
                                                    //             .isConnected = true;
                                                    //         stopReconnectingTimer();
                                                    //         stoptimerAddCerosToDisconnectedDevice();
                                                    //         setState(() {});
                                                    //       }
                                                    //       sensorUsedInSession
                                                    //           .signalForCheckingSensorState = 0;
                                                    //     }
                                                    //   },
                                                    // );

                                                    // - Timer to synchronize EnvValues for Analytics
                                                    Timer.periodic(
                                                        const Duration(
                                                            milliseconds: 200),
                                                        (Timer
                                                            timerSyncEnvValues) {
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
                                                          // log('DONE removing LAST: SMALLER ${currentSensorAnalytics.address} ${currentSensorAnalytics.listEnvSamplesValuesForStatistics.length} GREATER ${nextSensorAnalytics.address} ${nextSensorAnalytics.listEnvSamplesValuesForStatistics.length}');
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

                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Amplitude',
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.headline4
                                  : AppTheme.appTheme.textTheme.headline4),
                        ),
                        SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          color: Get.isDarkMode
                              ? AppTheme.appDarkTheme.cardColor
                              : AppTheme.appTheme.cardColor,
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
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Session Progress',
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.headline4
                                  : AppTheme.appTheme.textTheme.headline4),
                        ),
                        SizedBox(height: 2),
                        Container(
                          color: Get.isDarkMode
                              ? AppTheme.appDarkTheme.cardColor
                              : AppTheme.appTheme.cardColor,
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
                                              // TODO: Add filters to the list of exercises
                                              // PopupMenuItem(
                                              //   onTap: null,
                                              //   child: Row(
                                              //     children: [
                                              //       IconButton(
                                              //         onPressed: () =>
                                              //             log('hi'),
                                              //         icon: Icon(Icons
                                              //             .align_vertical_top_sharp),
                                              //       ),
                                              //       IconButton(
                                              //         onPressed: null,
                                              //         icon: Icon(Icons
                                              //             .align_vertical_top_sharp),
                                              //       ),
                                              //       IconButton(
                                              //         onPressed: null,
                                              //         icon: Icon(Icons
                                              //             .align_vertical_top_sharp),
                                              //       )
                                              //     ],
                                              //   ),
                                              // ),
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
                                    // AppIconButtonBig(
                                    //     icon32px: const Icon(Icons.expand_more,
                                    //         size: 32, color: Colors.white),
                                    //     onPressed: () => null)
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
                                          ? AppTheme.appDarkTheme.cardColor
                                          : AppTheme.appTheme.cardColor,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        AppIconButton(
                                            iconData: Icons.delete,
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
    log('RUNNING startTimerUpdateChart');
    _timerUpdateChart =
        Timer.periodic(const Duration(milliseconds: 25), (timer) {
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
          /// Is better to use >= than ==. (The app could skip the moment when  `s.chartData.length >= 120`)

          // ---- THIS CODE UPDATES THE COLUMN CHART
          // s.columnChartData.first =
          //     ChartSampleData(x: 0, y: s.listEnvSamplesValuesForGraphic.last);
          // // - Update column chart
          // s.columnChartSeriesController?.updateDataSource(updatedDataIndex: 0);
          // ---- THIS CODE UPDATES THE COLUMN CHART

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
            // // - Update column chart
            // s.columnChartSeriesController?.updateDataSource(
            //   removedDataIndexes: removedIndexes,
            //   addedDataIndexes: indexes,
            //   updatedDataIndexes: removedIndexes,
            // );
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
              // // - Update column chart
              // s.columnChartSeriesController?.updateDataSource(
              //   addedDataIndexes: indexes,
              // );

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
    // LinearGradient buildGradientFromCallibriColorType(
    //     CallibriColorType callibriColorType) {
    //   late List<Color> colors;

    //   switch (callibriColorType) {
    //     case CallibriColorType.white:
    //       colors = <Color>[
    //         Colors.grey[200]!,
    //         Colors.grey[400]!,
    //         Colors.grey[700]!
    //       ];
    //       break;
    //     case CallibriColorType.red:
    //       colors = <Color>[
    //         Colors.red[200]!,
    //         Colors.red[400]!,
    //         Colors.red[700]!
    //       ];
    //       break;
    //     case CallibriColorType.blue:
    //       colors = <Color>[
    //         Colors.blue[200]!,
    //         Colors.blue[400]!,
    //         Colors.blue[700]!
    //       ];
    //       break;
    //     case CallibriColorType.yellow:
    //       colors = <Color>[
    //         Colors.yellow[200]!,
    //         Colors.yellow[400]!,
    //         Colors.yellow[700]!
    //       ];
    //       break;
    //     default:
    //       colors = <Color>[
    //         Colors.grey[200]!,
    //         Colors.grey[400]!,
    //         Colors.grey[700]!
    //       ];
    //   }
    //   var linearGradient = LinearGradient(
    //       begin: Alignment.bottomCenter,
    //       end: Alignment.topCenter,
    //       colors: colors,
    //       stops: const <double>[
    //         (0.0),
    //         (0.5),
    //         (1.0),
    //       ]);
    //   return linearGradient;
    // }

    // final List<double> stops = <double>[];
    // stops.add(0.0);
    // stops.add(0.5);
    // stops.add(1.0);
    // double columnChartWidth = 50;

    //  final LinearGradient gradientColors =
    //   LinearGradient(colors: color, stops: stops);

    // final List<Color> color = <Color>[];
    // color.add(darkerColorFrom(color: deviceColor, amount: 0.4));
    // color.add(deviceColor);
    // color.add(darkerColorFrom(color: deviceColor, amount: 0.4));

    // Color deviceColor = buildColorFromCallibriColorType(
    //     connectedSensorUsedInSession.sensor.colorCallibri);
    double columnChartWidth = 0;

    //  While bigger is the chart (the space that the y values use in the area), the more will be the raster (worse performance)
    // with a 20valueMax/100areaMax graphic, the raster is 17ms  (+gradient)
    // with a 20valueMax/60areaMax graphic, the raster is 22ms (+gradient)
    // with a 20valueMax/20areaMax graphic, the raster is 33ms (+gradient)
    //gradient affects in just a couple of ms (1-4)ms
    return Row(
      children: [
        Container(
          height: (MediaQuery.of(context).size.height /
                  widget.allSensorsUsedInSession.length) -
              32 / widget.allSensorsUsedInSession.length,
          width: MediaQuery.of(context).size.width -
              sidebarWidth -
              16 -
              columnChartWidth,
          child: SfCartesianChart(
            margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),

            title: ChartTitle(
              alignment: ChartAlignment.near,
              // text: buildTextForChart(connectedSensorUsedInSession),
              textStyle: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.bodyText1
                  : AppTheme.appTheme.textTheme.bodyText1,
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
                // gradient: buildGradientFromCallibriColorType(
                //     connectedSensorUsedInSession.sensor.colorCallibri),
                // borderColor: buildColorFromCallibriColorType(
                //     connectedSensorUsedInSession.sensor.colorCallibri),
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
                : const Color(0xffF2F3F5), //frame of widgetƑ
            backgroundColor: Get.isDarkMode
                ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                : const Color(0xffF2F3F5), // Background of frame
            plotAreaBackgroundColor: Get.isDarkMode
                ? const Color(0xff282828)
                : const Color(0xffF2F3F5), // main background
            // plotAreaBackgroundColor: buildPlotAreaBackgroundColorFromSensor(
            //     connectedSensorUsedInSession:
            //         connectedSensorUsedInSession), // main background
            plotAreaBorderColor: Get.isDarkMode
                ? AppTheme.appDarkTheme.colorScheme.outline
                : const Color(
                    0xff7a7575), // Thick line, the last one at the top
            borderWidth: 4,
          ),
        ),
        // ---------------- COLUMN CHART --------------------
        // ---------------- COLUMN CHART --------------------
        // ---------------- COLUMN CHART --------------------
        // Container(
        //   padding: const EdgeInsets.only(top: 34),
        //   height: (MediaQuery.of(context).size.height /
        //           listSensorsUsedInSession.length) -
        //       (32 / listSensorsUsedInSession.length) -
        //       16,
        //   width: columnChartWidth,
        //   child: SfCartesianChart(
        //     margin: const EdgeInsets.all(0), // Fill all width

        //     series: <ChartSeries>[
        //       ColumnSeries<ChartSampleData, int>(
        //         onRendererCreated: (controller) => connectedSensorUsedInSession
        //             .columnChartSeriesController = controller,
        //         dataSource: connectedSensorUsedInSession.columnChartData,
        //         xValueMapper: (ChartSampleData chartData, _) => 0,
        //         yValueMapper: (ChartSampleData chartData, _) => chartData.y,
        //         // Map the data label text for each point from the data source

        //         dataLabelMapper: (ChartSampleData sales, _) =>
        //             '${(sales.y * 1000000).toInt()}',
        //         dataLabelSettings: const DataLabelSettings(
        //             labelAlignment: ChartDataLabelAlignment.bottom,
        //             labelIntersectAction: LabelIntersectAction.none,
        //             labelPosition: ChartDataLabelPosition.outside,
        //             isVisible: true,
        //             textStyle: TextStyle(fontSize: 16)),
        //         color: buildColorFromCallibriColorType(
        //             connectedSensorUsedInSession.sensor.colorCallibri),
        //         // pointColorMapper: (ChartSampleData sales, _) {
        //         //   if (sales.y >= maxV[maxVIndex] * 0.9) {
        //         //     return Color.fromARGB(255, 242, 112, 94);
        //         //   }
        //         //   if (sales.y >= maxV[maxVIndex] * 0.5) {
        //         //     return Color.fromARGB(255, 244, 164, 88);
        //         //   } else {
        //         //     return Color.fromARGB(255, 244, 241, 101);
        //         //   }
        //         // },
        //         // trackColor: Get.isDarkMode
        //         //     ? AppTheme.appDarkTheme.scaffoldBackgroundColor
        //         //     : const Color(0xffF2F3F5),
        //         width: 1, // Fill all width
        //         isTrackVisible: false,
        //       )
        //     ],
        //     plotAreaBorderColor: Get.isDarkMode
        //         ? AppTheme.appDarkTheme.colorScheme.outline
        //         : const Color(
        //             0xff7a7575), // Thick line, the last one at the top
        //     primaryXAxis: NumericAxis(
        //       isVisible: false,
        //     ),
        //     primaryYAxis: NumericAxis(
        //       minimum: 0,
        //       maximum: maxV[maxVIndex],
        //       isVisible: false,
        //       rangePadding: ChartRangePadding.none,
        //     ),
        //   ),
        // )
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
  Color plotAreaBackgroundColor =
      Get.isDarkMode ? const Color(0xff282828) : const Color(0xffF2F3F5);
  if (connectedSensorUsedInSession.electrodeState !=
      CallibriElectrodeState.elStNormal) {
    plotAreaBackgroundColor = Colors.red.shade700.withOpacity(0.3);
  }
  if (connectedSensorUsedInSession.isConnected == false) {
    plotAreaBackgroundColor = Colors.red.shade700.withOpacity(0.4);
  }

  return plotAreaBackgroundColor;
}

// String buildTextForChart(SensorUsedInSession connectedSensorUsedInSession) {
// String sensorName =
//     connectedSensorUsedInSession.sensor.name.split('_').join(' ');
// String textForChart = connectedSensorUsedInSession.placement != null
//     ? '$sensorName - ${connectedSensorUsedInSession.placement!.muscleName}'
//     : sensorName;

// REMOVED TO AVOID SET STATE
// if (connectedSensorUsedInSession.electrodeState !=
//     CallibriElectrodeState.elStNormal) {
//   switch (connectedSensorUsedInSession.electrodeState) {
//     case CallibriElectrodeState.elStDetached:
//       textForChart = '$sensorName - ELECTRODE DETACHED';
//       break;
//     case CallibriElectrodeState.elStHighResistance:
//       textForChart = '$sensorName - HIGH RESISTANCE';
//       break;

//     case CallibriElectrodeState.elStNormal:
//       break;
//   }
// }
// if (connectedSensorUsedInSession.isConnected == false) {
//   textForChart = '$sensorName DISCONNECTED';
// }
// return textForChart;
// }

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
          log(sensorUsedInSession.listEnvSamplesValuesForGraphic.toString());

          // Count to see if the devices is disconnected
          sensorUsedInSession.signalForCheckingSensorState++;
        }
      });
      sensorUsedInSession.sensor.executeCommand(SensorCommand.startEnvelope);
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
