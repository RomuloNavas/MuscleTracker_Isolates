import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/sensor_report_operations.dart';
import 'package:neuro_sdk_isolate_example/database/session_operations.dart';
import 'package:neuro_sdk_isolate_example/database/workout_report_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/home/add_client_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/session/session_monitor_screen.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/build_battery_indicator_icon.dart';
import 'package:neuro_sdk_isolate_example/utils/build_from_sensor.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_client_avatar.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_muscle_side.dart';
import 'package:path_provider/path_provider.dart';

import '../home/home_screen.dart';

class SessionResultsScreen extends StatefulWidget {
  final List<Workout> completedWorkouts;
  final List<SensorInfoForResults> usedSensors;
  final Client client;
  final String sessionStartedAt;
  final String sessionEndedAt;
  const SessionResultsScreen({
    required this.completedWorkouts,
    required this.usedSensors,
    Key? key,
    required this.client,
    required this.sessionStartedAt,
    required this.sessionEndedAt,
  }) : super(key: key);

  @override
  SessionResultsScreenState createState() => SessionResultsScreenState();
}

class SessionResultsScreenState extends State<SessionResultsScreen>
    with SingleTickerProviderStateMixin {
  // DATA TABLE VARIABLES
  int sortColumnIndex = 0;
  bool isAscending = false;

  // Text editing controllers
  late TextEditingController _textEditingControllerTitle;
  late TextEditingController _textEditingControllerDescription;
  final _formKeyTitle = GlobalKey<FormState>();
  final _formKeyDescription = GlobalKey<FormState>();

  @override
  void initState() {
    _textEditingControllerTitle = TextEditingController();
    _textEditingControllerDescription = TextEditingController();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);

    super.initState();
  }

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      widget.completedWorkouts.sort((a, b) => compareString(
          ascending,
          getMinutesAndSecondsFromDuration(
              duration: a.finishedAt!.difference(a.startedAt!)),
          (getMinutesAndSecondsFromDuration(
              duration: b.finishedAt!.difference(b.startedAt!)))));
    } else if (columnIndex == 1) {
      widget.completedWorkouts.sort(
        (a, b) {
          int result = 0;
          for (var i = 0;
              i < widget.completedWorkouts.first.samplesFromElectrodes!.length;
              i++) {
            result = compareString(
                ascending,
                getAverage(b.samplesFromElectrodes![i].samples),
                getAverage(a.samplesFromElectrodes![i].samples));
          }
          return result;
        },
      );
    } else if (columnIndex == 2) {
      widget.completedWorkouts.sort(
        (a, b) {
          int result = 0;
          for (var i = 0;
              i < widget.completedWorkouts.first.samplesFromElectrodes!.length;
              i++) {
            result = compareString(
                ascending,
                a.samplesFromElectrodes![i].samples.reduce(math.max),
                b.samplesFromElectrodes![i].samples.reduce(math.max));
          }
          return result;
        },
      );
    } else if (columnIndex == 3) {
      widget.completedWorkouts.sort(
        (a, b) {
          int result = 0;
          for (var i = 0;
              i < widget.completedWorkouts.first.samplesFromElectrodes!.length;
              i++) {
            result = compareString(
                ascending,
                a.samplesFromElectrodes![i].samples.reduce(math.min),
                b.samplesFromElectrodes![i].samples.reduce(math.min));
          }
          return result;
        },
      );
    } else if (columnIndex == 4) {
      widget.completedWorkouts.sort(
        (a, b) {
          int result = 0;
          for (var i = 0;
              i < widget.completedWorkouts.first.samplesFromElectrodes!.length;
              i++) {
            double areaA = (a.samplesFromElectrodes![i].samples
                    .reduce((value, element) => value + element)) /
                50;
            double areaB = (b.samplesFromElectrodes![i].samples
                    .reduce((value, element) => value + element)) /
                50;
            result = compareString(ascending, areaA, areaB);
          }
          return result;
        },
      );
    }
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  int compareString(bool ascending, dynamic value1, dynamic value2) {
    return ascending ? value1.compareTo(value2) : value2.compareTo(value1);
  }

  DataTable buildDataTable(
      {required List<Workout> tableCompletedWorkouts,
      required SensorInfoForResults usedSensor}) {
    final columns = [
      'Exercise name',
      'A(avr), µV',
      'A(max), µV',
      'A(min), µV',
      'S, mV*ms'
    ];

    var samplesFromCurrentSensor = <SamplesFromElectrode?>[];
    for (var w in tableCompletedWorkouts) {
      var _sampleFromElectrode = w.samplesFromElectrodes!.firstWhereOrNull(
          (element) => element.sensorAddress == usedSensor.address);
      samplesFromCurrentSensor.add(_sampleFromElectrode);
    }
    return DataTable(
      sortColumnIndex: sortColumnIndex,
      sortAscending: isAscending,
      horizontalMargin: 8,
      columnSpacing: 0,
      dataRowHeight: 60,
      columns: getColumns(columns, completedWorkouts: widget.completedWorkouts),
      rows: getRows(
          usedSensor: usedSensor,
          samplesFromCurrentSensor: samplesFromCurrentSensor,
          completedWorkouts: widget.completedWorkouts),
    );
  }

  List<DataColumn> getColumns(List<String> columns,
      {required List<Workout> completedWorkouts}) {
    return columns
        .map((String column) => DataColumn(
            onSort: (columnIndex, ascending) {
              onSort(columnIndex, ascending);
            },
            label: Text(column,
                style: Get.isDarkMode
                    ? AppTheme.appDarkTheme.textTheme.headline5
                    : AppTheme.appTheme.textTheme.headline5)))
        .toList();
  }

  List<DataRow> getRows({
    required List<SamplesFromElectrode?> samplesFromCurrentSensor,
    required List<Workout> completedWorkouts,
    required SensorInfoForResults usedSensor,
  }) {
    List<DataRow> dataRow = [];
    var _samplesFromCurrentSensor = <SamplesFromElectrode>[];

    for (var e in completedWorkouts) {
      var samplesFromSensor = e.samplesFromElectrodes!
          .where((e) => e.sensorAddress == usedSensor.address)
          .toList();
      _samplesFromCurrentSensor.addAll(samplesFromSensor);
    }

    // -DEBUG

    var listAllSensorValuesFromAvrAmp = <double>[];
    var listAllSensorValuesFromMaxAmp = <double>[];
    var listAllSensorValuesFromMinAmp = <double>[];
    var listAllSensorValuesFromArea = <double>[];

    for (var i = 0; i < _samplesFromCurrentSensor.length; i++) {
      listAllSensorValuesFromAvrAmp
          .add(getAverage(samplesFromCurrentSensor[i]!.samples));
      listAllSensorValuesFromMaxAmp
          .add(samplesFromCurrentSensor[i]!.samples.reduce(math.max));
      listAllSensorValuesFromMinAmp
          .add(samplesFromCurrentSensor[i]!.samples.reduce(math.min));
      listAllSensorValuesFromArea.add((samplesFromCurrentSensor[i]!
              .samples
              .reduce((value, element) => value + element)) /
          50);
    }
    // Last value is the highest
    listAllSensorValuesFromAvrAmp.sort();
    listAllSensorValuesFromMaxAmp.sort();
    listAllSensorValuesFromMinAmp.sort();
    listAllSensorValuesFromArea.sort();

    for (var i = 0; i < _samplesFromCurrentSensor.length; i++) {
      double avrAmp = getAverage(samplesFromCurrentSensor[i]!.samples);
      double maxAmp = samplesFromCurrentSensor[i]!.samples.reduce(math.max);
      double minAmp = samplesFromCurrentSensor[i]!.samples.reduce(math.min);
      double area = (samplesFromCurrentSensor[i]!
              .samples
              .reduce((value, element) => value + element)) /
          50;
      dataRow.add(
        DataRow(
          cells: [
            DataCell(
              Container(
                  padding: EdgeInsets.all(10),
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(completedWorkouts[i].exercise.name,
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.bodyText1
                              : AppTheme.appTheme.textTheme.bodyText1),
                      Text(
                          getMinutesAndSecondsFromDuration(
                              duration: completedWorkouts[i]
                                  .finishedAt!
                                  .difference(completedWorkouts[i].startedAt!)),
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.overline
                              : AppTheme.appTheme.textTheme.overline)
                    ],
                  )),
            ),
            DataCell(
              AppDataCellChild(
                  value: avrAmp, maxValue: listAllSensorValuesFromAvrAmp.last),
            ),
            DataCell(
              AppDataCellChild(
                  value: maxAmp, maxValue: listAllSensorValuesFromMaxAmp.last),
            ),
            DataCell(
              AppDataCellChild(
                  value: minAmp, maxValue: listAllSensorValuesFromMinAmp.last),
            ),
            DataCell(
              AppDataCellChild(
                  value: area, maxValue: listAllSensorValuesFromArea.last),
            ),
          ],
        ),
      );
    }
    return dataRow;
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
        iconTheme: IconThemeData(
          size: 32,
          color: Get.isDarkMode ? Color(0xffeeeeee) : Colors.black,
        ),
        toolbarHeight: MediaQuery.of(context).size.height < 500 ? 50 : 80,
        titleTextStyle: Get.isDarkMode
            ? AppTheme.appDarkTheme.textTheme.headline3
            : AppTheme.appTheme.textTheme.headline3,
        title: const Text('Results from session'),
        titleSpacing: 32.0,
        automaticallyImplyLeading: false,
        actions: [
          // Container(
          //   margin: const EdgeInsets.only(right: 16),
          //   child: IconButton(
          //     icon: Icon(Icons.done),
          //     tooltip: 'Save and close',
          //     onPressed: () {
          //       Get.off(() => HomeScreen());
          //       // handle the press
          //     },
          //   ),
          // ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ListView(
            children: [
              Center(
                child: Container(
                  width: Get.size.width > 800 ? 720 : Get.size.width - 32,
                  child: Column(
                    children: [
                      SizedBox(height: 64),
                      Text('Muscles activity comparison',
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.headline1
                              : AppTheme.appTheme.textTheme.headline1),
                      const SizedBox(height: 36),

                      for (var i = 0; i < widget.usedSensors.length; i++)
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(left: 8),
                                    color: Get.isDarkMode
                                        ? AppTheme
                                            .appDarkTheme.colorScheme.surface
                                        : AppTheme.appTheme.colorScheme.surface,
                                    height: 8,
                                    // width: 240,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      // Text(
                                      //   '${i+ 1}',
                                      //   style: Get.isDarkMode
                                      //       ? AppTheme.appDarkTheme.textTheme
                                      //           .headline1
                                      //       : AppTheme
                                      //           .appTheme.textTheme.headline1,
                                      // ),
                                      const SizedBox(width: 12),
                                      CircleAvatar(
                                        backgroundColor: Get.isDarkMode
                                            ? AppTheme.appDarkTheme.colorScheme
                                                .surface
                                            : AppTheme
                                                .appTheme.colorScheme.surface,
                                        radius: 22,
                                        child: SvgPicture.asset(
                                            'assets/icons/callibri_device-${widget.usedSensors[i].color}.svg',
                                            width: 16,
                                            semanticsLabel: 'Battery'),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              idToBodyRegionString(
                                                  bodyRegionId: widget
                                                      .usedSensors[i]
                                                      .sensorPlacement
                                                      .bodyRegionId),
                                              style: Get.isDarkMode
                                                  ? AppTheme.appDarkTheme
                                                      .textTheme.caption
                                                      ?.copyWith(
                                                          color: const Color(
                                                              0xff878787))
                                                  : AppTheme.appTheme.textTheme
                                                      .caption
                                                      ?.copyWith(
                                                          color: const Color(
                                                              0xff444547))),
                                          Text(
                                            widget.usedSensors[i]
                                                .sensorPlacement.muscleName,
                                            style: Get.isDarkMode
                                                ? AppTheme.appDarkTheme
                                                    .textTheme.bodyText1
                                                : AppTheme.appTheme.textTheme
                                                    .bodyText1,
                                          ),
                                          if (widget.usedSensors[i]
                                                  .sensorPlacement.side !=
                                              null)
                                            AppMuscleSideIndicator(
                                                side: widget.usedSensors[i]
                                                    .sensorPlacement.side!)
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: buildDataTable(
                                  usedSensor: widget.usedSensors[i],
                                  tableCompletedWorkouts:
                                      widget.completedWorkouts),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      const SizedBox(height: 64),
                      Center(
                        child: Text(
                          'Session Notes',
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.headline1
                              : AppTheme.appTheme.textTheme.headline1,
                        ),
                        // (1) general information about the session; (2) narrative about the session; and (3) the type of referrals made during the session.
                      ),
                      const SizedBox(height: 36),
                      ContactCircleAvatar(
                        radius: 32,
                      ),
                      AppHeaderInfo(
                        title:
                            '${widget.client.name} ${widget.client.surname} ${widget.client.patronymic}',
                        labelPrimary:
                            'Session duration: ${getMinutesAndSecondsFromDurationWithSign(duration: Duration(seconds: DateTime.parse(widget.sessionEndedAt).difference(DateTime.parse(widget.sessionStartedAt)).inSeconds))}',
                      ),
                      const SizedBox(height: 36),
                      const SizedBox(height: 16),
                      AppTextField(
                          textEditingController: _textEditingControllerTitle,
                          keyboardType: TextInputType.text,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          globalKey: _formKeyTitle,
                          hint: 'Session Title',
                          svgIconPath: 'title',
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(80),
                          ],
                          validator: (value) {
                            if (value != null) {
                              if (value.isEmpty) {
                                return null;
                              }
                              if (value.length > 80) {
                                return 'Only 80 characters allowed';
                              } else {
                                return null;
                              }
                            } else {
                              return null;
                            }
                          }),
                      const SizedBox(height: 16),
                      AppTextField(
                          textEditingController:
                              _textEditingControllerDescription,
                          keyboardType: TextInputType.text,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          globalKey: _formKeyDescription,
                          hint: 'Session Description',
                          svgIconPath: 'description',
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(200),
                          ],
                          validator: (value) {
                            if (value != null) {
                              if (value.isEmpty) {
                                return null;
                              }
                              if (value.length > 200) {
                                return 'Only 200 characters allowed';
                              } else {
                                return null;
                              }
                            } else {
                              return null;
                            }
                          }),
                      const SizedBox(height: 8),

                      // RecordVideo(),
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 16),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: AppFilledButton(
                            onPressed: () async {
                              var clientOperations = ClientOperations();
                              var sessionOperations = SessionOperations();
                              var workoutReportOperations =
                                  WorkoutReportOperations();

                              /// Save Session to DB and get the added session (row) ID
                              var completedSession = Session(
                                startedAt: widget.sessionStartedAt,
                                endedAt: widget.sessionEndedAt,
                                name: _textEditingControllerTitle.text,
                                description:
                                    _textEditingControllerDescription.text,
                                clientId: widget.client.id,
                                bodyRegionId: widget.usedSensors.first
                                    .sensorPlacement.bodyRegionId,
                              );

                              var idOfLastAddedSession = await sessionOperations
                                  .createSession(completedSession);

                              /// Inserts a WorkoutReport to the DB and gets it ID.
                              for (var workout in widget.completedWorkouts) {
                                var workoutReport = WorkoutReport(
                                  startedAt:
                                      workout.startedAt!.toIso8601String(),
                                  endedAt:
                                      workout.finishedAt!.toIso8601String(),
                                  sessionId: idOfLastAddedSession,
                                  workoutId: workout.exercise.id ??= 0,
                                );
                                var idOfLastAddedWorkoutReport =
                                    await workoutReportOperations
                                        .createWorkoutReport(workoutReport);

                                ///  Inserts a SensorReport for each used sensor
                                for (var sensor in widget.usedSensors) {
                                  var registeredUsedSensor =
                                      await RegisteredSensorOperations()
                                          .getRegisteredSensorByAddress(
                                              sensor.address);

                                  int?
                                      sensorPlacementOfRegisteredAndUsedSensor =
                                      widget.usedSensors
                                          .firstWhere((s) =>
                                              s.address ==
                                              registeredUsedSensor!.address)
                                          .sensorPlacement
                                          .id;

                                  final sensorReport = SensorReport(
                                    maxAmp: workout.getMaxAmpInVFromSensor(
                                        sensorAddress: sensor.address),
                                    minAmp: workout.getMinAmpInVFromSensor(
                                        sensorAddress: sensor.address),
                                    avrAmp: workout.getAvrAmpInVFromSensor(
                                        sensorAddress: sensor.address),
                                    area: workout.getAreaFromSensor(
                                        sensorAddress: sensor.address),
                                    registeredSensorId:
                                        registeredUsedSensor!.id!,
                                    workoutReportId: idOfLastAddedWorkoutReport,
                                    placementId:
                                        sensorPlacementOfRegisteredAndUsedSensor,
                                    side: sensor.sensorPlacement.side,
                                  );

                                  await SensorReportOperations()
                                      .createSensorReport(sensorReport);

                                  // Update client's last session
                                  widget.client.lastSession =
                                      DateTime.now().toIso8601String();
                                  await clientOperations
                                      .updateClient(widget.client);
                                }
                              }

                              Get.off(
                                () => const HomeScreen(),
                              );
                            },
                            backgroundColor: Get.isDarkMode
                                ? AppTheme.appDarkTheme.colorScheme.primary
                                : AppTheme.appTheme.colorScheme.primary,
                            text: 'Save and close',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40, top: 8),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: TextButton(
                              onPressed: () {
                                Get.off(() => const HomeScreen());
                              },
                              child: Text(
                                'Close without saving',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.button
                                        ?.copyWith(
                                            color: AppTheme
                                                .appDarkTheme.colorScheme.error)
                                    : AppTheme.appTheme.textTheme.button
                                        ?.copyWith(
                                            color: AppTheme
                                                .appTheme.colorScheme.error),
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class RecordVideo extends StatefulWidget {
//   const RecordVideo({
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<RecordVideo> createState() => _RecordVideoState();
// }

// class _RecordVideoState extends State<RecordVideo>
//     with SingleTickerProviderStateMixin {
//   double _videoWidth = Get.size.width > 800
//       ? (720 * 0.7) - 72
//       : Get.size.width - (32 * 0.3) - 72;
//   bool _isLoading = true;
//   bool _wantsToAddVideo = false;
//   bool _isRecording = false;
//   late CameraController _cameraController;
//   XFile? _fileWhereRecordedVideoWasSaved;
//   var _flashMode = FlashMode.off;

//   late final AnimationController _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//       lowerBound: 0.3,
//       upperBound: 1.0)
//     ..repeat(reverse: true);

//   late final Animation<double> _animation = CurvedAnimation(
//     parent: _animationController,
//     curve: Curves.fastOutSlowIn,
//   );

//   @override
//   void initState() {
//     super.initState();
//     _initCamera();
//   }

//   @override
//   void dispose() {
//     _cameraController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   _initCamera() async {
//     final cameras = await availableCameras();
//     final front = cameras.firstWhere(
//         (camera) => camera.lensDirection == CameraLensDirection.back);
//     _cameraController = CameraController(front, ResolutionPreset.max);
//     await _cameraController.initialize();
//     setState(() => _isLoading = false);
//   }

//   _recordVideo() async {
//     if (_isRecording) {
//       _fileWhereRecordedVideoWasSaved =
//           await _cameraController.stopVideoRecording();
//       _cameraController.setFlashMode(FlashMode.off);
//       setState(
//         () {
//           _isRecording = false;
//           _flashMode = FlashMode.off;
//         },
//       );
//     } else {
//       _fileWhereRecordedVideoWasSaved = null;
//       await _cameraController.prepareForVideoRecording();
//       await _cameraController.startVideoRecording();
//       setState(() => _isRecording = true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Container(
//         color: Colors.white,
//         child: const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     } else {
//       return Container(
//         decoration: BoxDecoration(
//           borderRadius: _wantsToAddVideo
//               ? BorderRadius.circular(0)
//               : BorderRadius.circular(12),
//         ),
//         child: Builder(builder: (context) {
//           if (_wantsToAddVideo) {
//             if (_fileWhereRecordedVideoWasSaved != null) {
//               return PlayRecordedVideo(
//                 filePath: _fileWhereRecordedVideoWasSaved!.path,
//                 dismissVideo: () {
//                   setState(() {
//                     _fileWhereRecordedVideoWasSaved = null;
//                   });
//                 },
//               );
//             } else {
//               return Row(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       // border: Border.all(width: 2, color: Colors.white),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(12),
//                         bottomLeft: Radius.circular(12),
//                       ),
//                       child: Container(
//                         width: 720 - 60,
//                         height: ((720 - 60 - 16) * 9) / 16,
//                         child: CameraPreview(_cameraController),
//                       ),
//                     ),
//                   ),
//                   if (_wantsToAddVideo)
//                     Container(
//                       padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
//                       height: ((720 - 60 - 16) * 9) / 16,
//                       width: 60,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.only(
//                           topRight: Radius.circular(12),
//                           bottomRight: Radius.circular(12),
//                         ),
//                         border: Border.all(
//                             width: 1,
//                             color: Get.isDarkMode
//                                 ? AppTheme.appDarkTheme.colorScheme.surface
//                                 : AppTheme.appTheme.colorScheme.surface),
//                         color: Get.isDarkMode
//                             ? AppTheme.appDarkTheme.colorScheme.surface
//                             : AppTheme.appTheme.colorScheme.surface,
//                       ),
//                       child: Column(
//                         mainAxisAlignment: _isRecording
//                             ? MainAxisAlignment.center
//                             : MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           if (_isRecording == false)
//                             AppIconButton(
//                               icon32px: Icon(Icons.close,
//                                   size: 32,
//                                   color: Get.isDarkMode
//                                       ? Color(0xffdcdcdc)
//                                       : Colors.black),
//                               onPressed: () {
//                                 setState(() {
//                                   _wantsToAddVideo = false;
//                                 });
//                               },
//                             ),
//                           InkWell(
//                             child: _isRecording
//                                 ? ButtonRecordingVideo(animation: _animation)
//                                 : const ButtonStartRecordingVideo(),
//                             onTap: () {
//                               _recordVideo();
//                             },
//                           ),
//                           // ------- FLash Button -------
//                           if (_isRecording == false)
//                             AppIconButton(
//                               icon32px: _flashMode == FlashMode.off
//                                   ? Icon(Icons.flash_off,
//                                       size: 32,
//                                       color: Get.isDarkMode
//                                           ? Color(0xffdcdcdc)
//                                           : Colors.black)
//                                   : Icon(Icons.flash_on,
//                                       size: 32,
//                                       color: Get.isDarkMode
//                                           ? Color(0xffdcdcdc)
//                                           : Colors.black),
//                               onPressed: () {
//                                 if (_flashMode == FlashMode.off) {
//                                   setState(() {
//                                     _flashMode = FlashMode.torch;
//                                   });
//                                   _cameraController
//                                       .setFlashMode(FlashMode.torch);
//                                 } else {
//                                   setState(() {
//                                     _flashMode = FlashMode.off;
//                                   });
//                                   _cameraController.setFlashMode(FlashMode.off);
//                                 }
//                               },
//                             ),
//                           // -xxxxxxx- FLash Button -xxxxxxx-
//                         ],
//                       ),
//                     ),
//                 ],
//               );
//             }
//           } else {
//             return Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.videocam,
//                     size: 40,
//                     color:
//                         Get.isDarkMode ? Color(0xffdcdcdc) : Color(0xff252006)),
//                 Text('Record video',
//                     style: Get.isDarkMode
//                         ? AppTheme.appDarkTheme.textTheme.headline5
//                         : AppTheme.appTheme.textTheme.headline5),
//                 Text('You can make a video of a custom workout',
//                     style: Get.isDarkMode
//                         ? AppTheme.appDarkTheme.textTheme.bodyText2
//                         : AppTheme.appTheme.textTheme.bodyText2),
//                 AppTextButton(
//                   action: () {
//                     setState(() {
//                       _wantsToAddVideo = true;
//                       _wantsToAddVideo = true;
//                       _videoWidth =
//                           Get.size.width > 800 ? 720 : Get.size.width - 32;
//                     });
//                   },
//                   color: Get.isDarkMode
//                       ? AppTheme.appDarkTheme.colorScheme.secondary
//                       : AppTheme.appTheme.colorScheme.secondary,
//                   child: const Text('Add video'),
//                 )
//               ],
//             );
//           }
//         }),
//       );
//     }
//   }
// }

// class ButtonRecordingVideo extends StatelessWidget {
//   const ButtonRecordingVideo({
//     Key? key,
//     required Animation<double> animation,
//   })  : _animation = animation,
//         super(key: key);

//   final Animation<double> _animation;

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         ScaleTransition(
//           scale: _animation,
//           child: Container(
//             height: 64,
//             width: 64,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: !Get.isDarkMode
//                   ? Color(0xffa9a9a9).withOpacity(0.5)
//                   : Color(0xffdcdcdc).withOpacity(0.5),
//             ),
//           ),
//         ),
//         Center(
//           child: Container(
//             height: 48,
//             width: 48,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: !Get.isDarkMode ? Colors.black : Color(0xffdcdcdc),
//             ),
//             child: Center(
//               child: Container(
//                 height: 20,
//                 width: 20,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(3),
//                   color: Get.isDarkMode ? Colors.black : Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class ButtonStartRecordingVideo extends StatelessWidget {
//   const ButtonStartRecordingVideo({
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 48,
//       width: 48,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(
//           width: 3,
//           color: Get.isDarkMode ? Color(0xffdcdcdc) : Color(0xff252006),
//         ),
//         color: Colors.transparent,
//       ),
//       child: Center(
//         child: Container(
//           height: 38,
//           width: 38,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Get.isDarkMode ? Color(0xffdcdcdc) : Color(0xff252006),
//           ),
//         ),
//       ),
//     );
//   }
// }

class AppDataCellChild extends StatelessWidget {
  const AppDataCellChild({
    Key? key,
    required this.value,
    this.cellWidth = 100,
    required this.maxValue,
  }) : super(key: key);
  final double value;
  final double cellWidth;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cellWidth,
      height: 36.0,
      child: Stack(
        children: [
          Container(
            width: cellWidth,
            height: 36.0,
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? lighterColorFrom(
                      color: AppTheme.appDarkTheme.scaffoldBackgroundColor,
                      amount: 0.1)
                  : darkerColorFrom(
                      color: AppTheme.appTheme.scaffoldBackgroundColor,
                      amount: 0.1),
            ),
            alignment: Alignment.centerLeft, // where to position the child
            child: Container(
              width: maxValue > 0.00000009
                  ? calculatePercentageGlobal(
                      widgetWidthValueInPX: cellWidth,
                      currentValue: value,
                      maxValue: maxValue)
                  : cellWidth,
              height: 36.0,
              decoration: BoxDecoration(
                color: maxValue > 0.00000009
                    ? AppTheme.appDarkTheme.hintColor.withOpacity(0.2)
                    : Colors.transparent,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text((value * 1000000).toStringAsFixed(0),
                  style: Get.isDarkMode
                      ? AppTheme.appDarkTheme.textTheme.bodyText1
                      : AppTheme.appTheme.textTheme.bodyText1),
            ),
          ),
        ],
      ),
    );
  }
}

// class PlayRecordedVideo extends StatefulWidget {
//   final Function dismissVideo;
//   final String filePath;

//   const PlayRecordedVideo({
//     Key? key,
//     required this.dismissVideo,
//     required this.filePath,
//   }) : super(key: key);

//   @override
//   _PlayRecordedVideoState createState() => _PlayRecordedVideoState();
// }

// class _PlayRecordedVideoState extends State<PlayRecordedVideo> {
//   late VideoPlayerController _videoPlayerController;

//   late Future<void> future;
//   final expandedKey = GlobalKey();

//   @override
//   void initState() {
//     // future = _initVideoPlayer();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _videoPlayerController.dispose();
//     super.dispose();
//   }

//   Timer? myTimer;

//   void _dismissVideo() {
//     widget.dismissVideo();
//   }

//   double _videoWidth = Get.size.width > 800
//       ? (720 * 0.7) - 72
//       : Get.size.width - (32 * 0.3) - 72;

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: future,
//       builder: (context, state) {
//         if (state.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else {
//           return Container(
//             width: 720 - 16,
//             height: ((720 - 16) * 9) / 16,
//             child: Stack(
//               alignment: Alignment.topCenter,
//               children: [
//                 Container(
//                   padding:
//                       EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 48),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     color: Get.isDarkMode
//                         ? AppTheme.appDarkTheme.colorScheme.surface
//                         : AppTheme.appTheme.colorScheme.surface,
//                     // border: Border.all(width: 2, color: Colors.white),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     ),
//                     child: Container(
//                       color: Colors.black,
//                       // ! IS REQUIRED THIS CONTAINER ???
//                       child: VideoPlayer(_videoPlayerController),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   top: 4,
//                   child: Container(
//                     width: 720 - 16,
//                     padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
//                     height: 60,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         AppIconButton(
//                             iconData: Icons.delete_outline,
//                             size: ButtonSize.big,
//                             onPressed: _dismissVideo),
//                         AppIconButton(
//                           iconData: Icons.check,
//                           size: ButtonSize.big,
//                           onPressed: () async {
//                             try {
//                               final directory =
//                                   await getExternalStorageDirectory();
//                               final path = directory?.path;
//                               if (path != null) {
//                                 final appSessionVideosPath =
//                                     '$path/Session_Videos';
//                                 final appVideosDirectory =
//                                     await Directory(appSessionVideosPath)
//                                         .create();
//                                 var appVideoFile = await File(
//                                         "$appSessionVideosPath/test_video.mp4")
//                                     .create();
//                                 log(appVideoFile.toString());

//                                 File videoCachePath = File(widget.filePath);
//                                 log(videoCachePath.toString());
//                                 // File("$appVideoFile")..writeAsString('Helloo');
//                                 log(appVideoFile.existsSync().toString());
//                                 await videoCachePath.copy(appVideoFile.path);

//                                 var listOfFiles = await appVideosDirectory
//                                     .list(recursive: true)
//                                     .toList();

//                                 var count = listOfFiles.length;
//                                 log('Number of files $count');
//                               }
//                             } catch (e) {
//                               log('ERROORR' + e.toString());
//                             } finally {
//                               log('DONE');
//                             }
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.bottomLeft,
//                   child: Container(
//                     margin: EdgeInsets.only(left: 8, right: 8),
//                     height: 48,
//                     decoration: const BoxDecoration(
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(12),
//                         bottomRight: Radius.circular(12),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         AppIconButton(
//                           icon32px: Icon(
//                               _videoPlayerController.value.isPlaying
//                                   ? Icons.pause
//                                   : Icons.play_arrow_rounded,
//                               size: 32,
//                               color: Get.isDarkMode
//                                   ? Color(0xffeeeeee)
//                                   : Colors.black),
//                           onPressed: () async {
//                             if (_videoPlayerController.value.isPlaying) {
//                               await _videoPlayerController.pause();
//                             } else {
//                               await _videoPlayerController.play();
//                               myTimer = Timer.periodic(
//                                   Duration(milliseconds: 500), (timer) {
//                                 if (_videoPlayerController.value.isPlaying) {
//                                   log('IS PLAYING');
//                                 } else {
//                                   myTimer!.cancel();
//                                   timer.cancel();
//                                   log('STOP PLAYING');
//                                   myTimer = null;
//                                 }
//                                 setState(() {});
//                               });
//                             }
//                           },
//                         ),
//                         AppIconButton(
//                           icon32px: Icon(Icons.loop_rounded,
//                               size: 32,
//                               color: Get.isDarkMode
//                                   ? _videoPlayerController.value.isLooping
//                                       ? Color(0xffeeeeee)
//                                       : Color(0xffeeeeee).withOpacity(0.5)
//                                   : Colors.black),
//                           onPressed: () async {
//                             if (_videoPlayerController.value.isLooping) {
//                               await _videoPlayerController.setLooping(false);
//                             } else {
//                               await _videoPlayerController.setLooping(true);
//                             }
//                             setState(() {});
//                           },
//                         ),
//                         Text(
//                             '${getMinutesAndSecondsFromDuration(duration: _videoPlayerController.value.position)} / ${getMinutesAndSecondsFromDuration(duration: _videoPlayerController.value.duration)}'),
//                         Expanded(
//                           key: expandedKey,
//                           child: LayoutBuilder(
//                             builder: (BuildContext context,
//                                 BoxConstraints constraints) {
//                               return Container(
//                                 height: 4.0,
//                                 margin:
//                                     const EdgeInsets.only(left: 12, right: 12),
//                                 child: Stack(
//                                   children: [
//                                     Container(
//                                       height: 4.0,
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(3),
//                                         color: !Get.isDarkMode
//                                             ? AppTheme.appDarkTheme.colorScheme
//                                                 .surface
//                                                 .withOpacity(0.3)
//                                             : AppTheme
//                                                 .appTheme.colorScheme.surface
//                                                 .withOpacity(0.3),
//                                       ),
//                                       alignment: Alignment
//                                           .centerLeft, // where to position the child
//                                       child: Container(
//                                         width: calculatePercentageGlobal(
//                                             widgetWidthValueInPX:
//                                                 constraints.maxWidth,
//                                             currentValue: _videoPlayerController
//                                                 .value.position.inMilliseconds
//                                                 .toDouble(),
//                                             maxValue: _videoPlayerController
//                                                 .value.duration.inMilliseconds
//                                                 .toDouble()),
//                                         height: 4.0,
//                                         decoration: BoxDecoration(
//                                           borderRadius:
//                                               BorderRadius.circular(3),
//                                           color: !Get.isDarkMode
//                                               ? AppTheme.appDarkTheme
//                                                   .colorScheme.surface
//                                               : AppTheme
//                                                   .appTheme.colorScheme.surface,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         AppIconButton(
//                           icon32px: Icon(Icons.fullscreen,
//                               size: 32,
//                               color: Get.isDarkMode
//                                   ? Color(0xffeeeeee)
//                                   : Colors.black),
//                           onPressed: () {
//                             log(_videoPlayerController.value.duration
//                                 .toString());
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//       },
//     );
//   }

// Future _initVideoPlayer() async {
//   if (widget.filePath != null) {
//     _videoPlayerController =
//         VideoPlayerController.file(File(widget.filePath));

//     /// GET A SAVED VIDEO:
//     // _videoPlayerController = VideoPlayerController.file(File(
//     //     '/storage/emulated/0/Android/data/com.example.flutter_neurosdk_example/files/Session_Videos/test_video.mp4'));

//     await _videoPlayerController.initialize();
//   } else {
//     log('NO FILE NO VIDEO SAVED ERROR');
//   }
// }
// }

// SizedBox(height: 56),
// Align(
//   alignment: Alignment.centerLeft,
//   child: Text('Used sensors',
//       style: Get.isDarkMode
//           ? AppTheme.appDarkTheme.textTheme.headline3
//           : AppTheme.appTheme.textTheme.headline3),
// ),
// SizedBox(height: 16),
// Row(
//   mainAxisAlignment: MainAxisAlignment.spaceAround,
//   children: [
//     for (var i = 0; i < widget.usedSensors.length; i++)
//       Container(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             const SizedBox(width: 8),
//             SizedBox(
//               width: 50,
//               child: SvgPicture.asset(
//                   'assets/icons/callibri_device-${buildColorNameFromSensor(rawSensorNameAndColor: widget.usedSensors[i].name.toString())}.svg',
//                   width: 16,
//                   semanticsLabel: 'Battery'),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 2),
//                 Text(
//                   widget.usedSensors[i].sensorPlacement
//                       .caption,
//                   style: Get.isDarkMode
//                       ? AppTheme.appDarkTheme.textTheme
//                           .bodyText1
//                       : AppTheme
//                           .appTheme.textTheme.bodyText1,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   'side',
//                   style: Get.isDarkMode
//                       ? AppTheme
//                           .appDarkTheme.textTheme.overline
//                       : AppTheme
//                           .appTheme.textTheme.overline,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       )
//   ],
// ),
// const SizedBox(height: 56),
// Align(
//   alignment: Alignment.centerLeft,
//   child: Text('Comparition table of completed exercises',
//       style: Get.isDarkMode
//           ? AppTheme.appDarkTheme.textTheme.headline3
//           : AppTheme.appTheme.textTheme.headline3),
// ),
// const SizedBox(height: 16),
