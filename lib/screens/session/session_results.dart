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
import 'package:neuro_sdk_isolate_example/widgets/app_bottom.dart';
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
      'A(avr), ??V',
      'A(max), ??V',
      'A(min), ??V',
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
        actions: [],
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
                      if (widget.completedWorkouts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 36, top: 48),
                          child: Text('Muscles activity comparison',
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.headline1
                                  : AppTheme.appTheme.textTheme.headline1),
                        ),

                      if (widget.completedWorkouts.isNotEmpty)
                        for (var i = 0; i < widget.usedSensors.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: EdgeInsets.fromLTRB(6, 12, 6, 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.colorScheme.surface
                                  : AppTheme.appTheme.colorScheme.surface,
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(left: 8),
                                        color: Get.isDarkMode
                                            ? AppTheme.appDarkTheme.colorScheme
                                                .surface
                                            : AppTheme
                                                .appTheme.colorScheme.surface,
                                        height: 8,
                                        // width: 240,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const SizedBox(width: 12),
                                          CircleAvatar(
                                            backgroundColor: Get.isDarkMode
                                                ? Colors.white.withOpacity(0.05)
                                                : Colors.black
                                                    .withOpacity(0.05),
                                            radius: 22,
                                            child: SvgPicture.asset(
                                                'assets/icons/callibri_device-${widget.usedSensors[i].color}.svg',
                                                width: 16,
                                                semanticsLabel: 'Sensor'),
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
                                                      : AppTheme.appTheme
                                                          .textTheme.caption
                                                          ?.copyWith(
                                                              color: const Color(
                                                                  0xff444547))),
                                              Text(
                                                widget.usedSensors[i]
                                                    .sensorPlacement.muscleName,
                                                style: Get.isDarkMode
                                                    ? AppTheme.appDarkTheme
                                                        .textTheme.bodyText1
                                                    : AppTheme.appTheme
                                                        .textTheme.bodyText1,
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
                              ],
                            ),
                          ),

                      // RecordVideo(),
                      AppHeaderInfo(
                        title:
                            '${widget.client.name} ${widget.client.surname} ${widget.client.patronymic}',
                        labelPrimary:
                            'Session duration: ${getMinutesAndSecondsFromDurationWithSign(duration: Duration(seconds: DateTime.parse(widget.sessionEndedAt).difference(DateTime.parse(widget.sessionStartedAt)).inSeconds))}',
                      ),

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
                      const SizedBox(height: 24),
                      AppBottom(
                        onPressed: () async {
                          var clientOperations = ClientOperations();
                          var sessionOperations = SessionOperations();
                          var workoutReportOperations =
                              WorkoutReportOperations();

                          /// Save Session to DB and get the added session (row) ID
                          Session? completedSession = Session(
                            startedAt: widget.sessionStartedAt,
                            endedAt: widget.sessionEndedAt,
                            name: _textEditingControllerTitle.text,
                            description: _textEditingControllerDescription.text,
                            clientId: widget.client.id,
                            bodyRegionId: widget
                                .usedSensors.first.sensorPlacement.bodyRegionId,
                          );

                          var idOfLastAddedSession = await sessionOperations
                              .createSession(completedSession);

                          /// Inserts a WorkoutReport to the DB and gets it ID.
                          for (var workout in widget.completedWorkouts) {
                            var workoutReport = WorkoutReport(
                              startedAt: workout.startedAt!.toIso8601String(),
                              endedAt: workout.finishedAt!.toIso8601String(),
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

                              int? sensorPlacementOfRegisteredAndUsedSensor =
                                  widget
                                      .usedSensors
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
                                registeredSensorId: registeredUsedSensor!.id!,
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

                          completedSession = null;
                          _endSessionAndMoveToHomeScreen();
                        },
                        mainText: 'Save and close',
                        secondaryText: 'Close without saving',
                        secondaryTextColor: Theme.of(context).colorScheme.error,
                        onSecondaryButtonPressed: () =>
                            Get.off(() => const HomeScreen()),
                      )
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

  _endSessionAndMoveToHomeScreen() {
    // Clear data from buffer
    widget.completedWorkouts.clear();

    Get.off(() => const HomeScreen());
  }
}

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
