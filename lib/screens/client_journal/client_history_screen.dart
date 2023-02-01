import 'dart:developer';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/sensor_report_operations.dart';
import 'package:neuro_sdk_isolate_example/database/session_operations.dart';
import 'package:neuro_sdk_isolate_example/database/workout_operations.dart';
import 'package:neuro_sdk_isolate_example/database/workout_report_operations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/session/session_setup_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/client_journal/widgets/percentage_box.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:neuro_sdk_isolate_example/utils/build_from_sensor.dart';
import 'package:neuro_sdk_isolate_example/utils/extension_methods.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_bottom.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_client_avatar.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_muscle_side.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_text_field.dart';

class UsedSensorResults {
  UsedSensorResults({
    required this.muscleName,
    required this.bodyRegion,
    this.side,
    required this.color,
    required this.sensorId,
  });
  late String muscleName;
  late String bodyRegion;
  String? side;
  late String color;
  late int sensorId;
}

class MuscleActivityComparison {
  MuscleActivityComparison({
    required this.workoutName,
    required this.workoutReport,
    required this.sensorReport,
    required this.sensor,
  });
  late String workoutName;
  late WorkoutReport workoutReport;
  late SensorReport sensorReport;
  late RegisteredSensor sensor;
}

class ClientHistoryScreen extends StatefulWidget {
  final Client client;
  const ClientHistoryScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  final GetxControllerServices servicesManager =
      Get.put(GetxControllerServices());

  List<Client> allRegisteredClients = [];
  int sortColumnIndex = 0;
  bool isAscending = true;

  List<Client> searchedClients = [];
  Session? selectedSession;
  List<WorkoutReport> allWorkoutReports = [];
  List<UsedSensorResults> allUsedSensors = [];

  late Future initCurrentSelectedSession;
  late Future initUsedSensors;

  @override
  void initState() {
    super.initState();
    servicesManager.requestBluetoothAndGPS();

    initCurrentSelectedSession = getWorkoutReportFromSelectedSession();
    initUsedSensors = getUsedSensors();
  }

  Future<List<MuscleActivityComparison>> getAllSensorReportsFromSensorId(
      int sensorId) async {
    List<MuscleActivityComparison> listMuscleActivityComparison = [];
    var registeredSensor =
        await RegisteredSensorOperations().getRegisteredSensorById(sensorId);

    for (var wr in allWorkoutReports) {
      var allSensorReport = await SensorReportOperations()
          .getAllSensorReportsByWorkoutReportIdAndSensorId(wr.id!, sensorId);
      String workoutName = 'Unknown';
      if (wr.workoutId != 0) {
        var workout = await ExerciseOperations().getWorkoutById(wr.workoutId);
        workoutName = workout.name;
      }

      for (var sensorReport in allSensorReport) {
        listMuscleActivityComparison.add(MuscleActivityComparison(
            workoutReport: wr,
            workoutName: workoutName,
            sensorReport: sensorReport,
            sensor: registeredSensor!));
      }
    }
    return listMuscleActivityComparison;
  }

  Widget buildSensorPlacementCard({
    required String sensorColor,
    required String muscleName,
    required String bodyRegionName,
    String? side,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 260,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: Get.isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              radius: 22,
              child: SvgPicture.asset(
                  'assets/icons/callibri_device-$sensorColor.svg',
                  width: 16,
                  semanticsLabel: 'Sensor'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bodyRegionName,
                    style: Get.isDarkMode
                        ? AppTheme.appDarkTheme.textTheme.bodyText2
                        : AppTheme.appTheme.textTheme.bodyText2),
                Text(
                  muscleName,
                  style: Get.isDarkMode
                      ? AppTheme.appDarkTheme.textTheme.bodyText1
                      : AppTheme.appTheme.textTheme.bodyText1,
                ),
                if (side != null) AppMuscleSideIndicator(side: side!)
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        body: Row(
          children: [
            SidePanel(
              notifyParentSessionSelected: (session) async {
                selectedSession = session;
                allWorkoutReports = await WorkoutReportOperations()
                    .getAllWorkoutReportsBySessionId(session);
                setState(() {});
              },
              client: widget.client,
            ),
            Flexible(
              flex: 1,
              child: ListView(
                children: [
                  if (allWorkoutReports.isNotEmpty && selectedSession != null)
                    Container(
                      margin:
                          const EdgeInsets.only(top: 24, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      DateFormat.yMMMEd().add_jm().format(
                                          DateTime.parse(
                                              selectedSession!.startedAt)),
                                      style: Get.isDarkMode
                                          ? AppTheme
                                              .appDarkTheme.textTheme.headline5
                                          : AppTheme
                                              .appTheme.textTheme.headline5),
                                  Text(
                                      'Duration: ${getMinutesAndSecondsFromDurationWithSign(duration: Duration(seconds: DateTime.parse(selectedSession!.endedAt).difference(DateTime.parse(selectedSession!.startedAt)).inSeconds))}',
                                      style: Get.isDarkMode
                                          ? AppTheme
                                              .appDarkTheme.textTheme.headline6
                                              ?.copyWith(
                                                  color: Color(0xff878787))
                                          : AppTheme
                                              .appTheme.textTheme.headline6
                                              ?.copyWith(
                                                  color: Color(0xff7a7575))),
                                ],
                              ),
                              Wrap(
                                spacing: 12,
                                children: [
                                  AppIconButton(
                                    iconData: Icons.delete,
                                    iconColor:
                                        Theme.of(context).colorScheme.error,
                                    onPressed: () async {
                                      setState(() {
                                        SessionOperations()
                                            .deleteSession(selectedSession!);
                                      });
                                    },
                                  ),
                                  AppIconButton(
                                    iconData: Icons.edit,
                                    onPressed: () => null,
                                  ),
                                  AppIconButton(
                                    iconData: Icons.compare,
                                    onPressed: () => null,
                                  ),
                                  AppIconButton(
                                    iconData: Icons.ios_share,
                                    onPressed: () => null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 26),
                          Text(
                              selectedSession!.name.isNotEmpty
                                  ? selectedSession!.name.toCapitalized()
                                  : 'Unnamed Session',
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.headline1
                                  : AppTheme.appTheme.textTheme.headline1),
                          if (selectedSession!.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                  'Description: ${selectedSession!.description.toCapitalized()}',
                                  style: Get.isDarkMode
                                      ? AppTheme.appDarkTheme.textTheme.caption
                                      : AppTheme.appTheme.textTheme.caption),
                            ),
                          const SizedBox(height: 36),
                          Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Text("• ",
                                            style: AppTheme.appDarkTheme
                                                .textTheme.headline1
                                                ?.copyWith(
                                                    color: const Color(
                                                        0xffe40031))),
                                        Expanded(
                                          child: Text('Used sensors',
                                              style: Get.isDarkMode
                                                  ? AppTheme.appDarkTheme
                                                      .textTheme.headline4
                                                      ?.copyWith(
                                                          color: Colors.white)
                                                  : AppTheme.appTheme.textTheme
                                                      .headline4),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (allWorkoutReports.isNotEmpty)
                                      // - USED SENSORS
                                      FutureBuilder(
                                          future: getUsedSensors(),
                                          builder: (context,
                                              AsyncSnapshot<
                                                      List<UsedSensorResults>?>
                                                  snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Wrap(
                                                runSpacing: 20,
                                                spacing: 20,
                                                children: [
                                                  for (var sensor
                                                      in snapshot.data!)
                                                    buildSensorPlacementCard(
                                                      sensorColor: sensor.color,
                                                      muscleName:
                                                          sensor.muscleName,
                                                      bodyRegionName:
                                                          sensor.bodyRegion,
                                                      side: sensor.side,
                                                    )
                                                ],
                                              );
                                            } else {
                                              return Text('no data');
                                            }
                                          }),
                                    const SizedBox(height: 36),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Text("• ",
                                            style: AppTheme.appDarkTheme
                                                .textTheme.headline1
                                                ?.copyWith(
                                                    color: const Color(
                                                        0xffe40031))),
                                        Expanded(
                                          child: Text(
                                              'Muscles activity comparison',
                                              style: Get.isDarkMode
                                                  ? AppTheme.appDarkTheme
                                                      .textTheme.headline4
                                                      ?.copyWith(
                                                          color: Colors.white)
                                                  : AppTheme.appTheme.textTheme
                                                      .headline4),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              // - MUSCLES ACTIVITY COMPARISON

                              FutureBuilder(
                                future: getUsedSensors(),
                                builder: (context,
                                    AsyncSnapshot<List<UsedSensorResults>?>
                                        snapshotSensorReport) {
                                  if (snapshotSensorReport.connectionState ==
                                          ConnectionState.done &&
                                      snapshotSensorReport.hasData) {
                                    List<Widget> column = [];

                                    for (var usedSensor
                                        in snapshotSensorReport.data!) {
                                      column.add(SizedBox(
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            buildSensorPlacementCard(
                                              sensorColor: usedSensor.color,
                                              muscleName: usedSensor.muscleName,
                                              bodyRegionName:
                                                  usedSensor.bodyRegion,
                                              side: usedSensor.side,
                                            ),
                                            FutureBuilder(
                                              future:
                                                  getAllSensorReportsFromSensorId(
                                                      usedSensor.sensorId),
                                              builder: (context,
                                                  AsyncSnapshot<
                                                          List<
                                                              MuscleActivityComparison>>
                                                      snapshot) {
                                                if (snapshot.connectionState ==
                                                        ConnectionState.done &&
                                                    snapshot.hasData) {
                                                  var listAllSensorValuesFromAvrAmp =
                                                      <double>[];
                                                  var listAllSensorValuesFromMaxAmp =
                                                      <double>[];
                                                  var listAllSensorValuesFromMinAmp =
                                                      <double>[];
                                                  var listAllSensorValuesFromArea =
                                                      <double>[];

                                                  for (var muscleActivityComparison
                                                      in snapshot.data!) {
                                                    listAllSensorValuesFromAvrAmp
                                                        .add(
                                                            muscleActivityComparison
                                                                .sensorReport
                                                                .avrAmp);
                                                    listAllSensorValuesFromMaxAmp
                                                        .add(
                                                            muscleActivityComparison
                                                                .sensorReport
                                                                .maxAmp);
                                                    listAllSensorValuesFromMinAmp
                                                        .add(
                                                            muscleActivityComparison
                                                                .sensorReport
                                                                .minAmp);
                                                    listAllSensorValuesFromArea.add(
                                                        muscleActivityComparison
                                                            .sensorReport.area);
                                                  }
                                                  listAllSensorValuesFromAvrAmp
                                                      .sort();
                                                  listAllSensorValuesFromMaxAmp
                                                      .sort();
                                                  listAllSensorValuesFromMinAmp
                                                      .sort();
                                                  listAllSensorValuesFromArea
                                                      .sort();
                                                  return Column(
                                                    children: [
// TABLE
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                bottom: 24,
                                                                top: 8),
                                                        child: SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: DataTable(
                                                            sortColumnIndex:
                                                                sortColumnIndex,
                                                            sortAscending:
                                                                isAscending,
                                                            horizontalMargin:
                                                                10,
                                                            columnSpacing: 0,
                                                            dataRowHeight: 60,
                                                            columns: [
                                                              DataColumn(
                                                                  label: Text(
                                                                      'Exercise name',
                                                                      style: Get.isDarkMode
                                                                          ? AppTheme
                                                                              .appDarkTheme
                                                                              .textTheme
                                                                              .headline5
                                                                          : AppTheme
                                                                              .appTheme
                                                                              .textTheme
                                                                              .headline5)),
                                                              DataColumn(
                                                                  label: Text(
                                                                      'A(avr), µV',
                                                                      style: Get.isDarkMode
                                                                          ? AppTheme
                                                                              .appDarkTheme
                                                                              .textTheme
                                                                              .headline5
                                                                          : AppTheme
                                                                              .appTheme
                                                                              .textTheme
                                                                              .headline5)),
                                                              DataColumn(
                                                                  label: Text(
                                                                      'A(max), µV',
                                                                      style: Get.isDarkMode
                                                                          ? AppTheme
                                                                              .appDarkTheme
                                                                              .textTheme
                                                                              .headline5
                                                                          : AppTheme
                                                                              .appTheme
                                                                              .textTheme
                                                                              .headline5)),
                                                              DataColumn(
                                                                  label: Text(
                                                                      'A(min), µV',
                                                                      style: Get.isDarkMode
                                                                          ? AppTheme
                                                                              .appDarkTheme
                                                                              .textTheme
                                                                              .headline5
                                                                          : AppTheme
                                                                              .appTheme
                                                                              .textTheme
                                                                              .headline5)),
                                                              DataColumn(
                                                                  label: Text(
                                                                      'S, mV*ms',
                                                                      style: Get.isDarkMode
                                                                          ? AppTheme
                                                                              .appDarkTheme
                                                                              .textTheme
                                                                              .headline5
                                                                          : AppTheme
                                                                              .appTheme
                                                                              .textTheme
                                                                              .headline5)),
                                                            ],
                                                            rows: [
                                                              for (var muscleActivityComparison
                                                                  in snapshot
                                                                      .data!)
                                                                DataRow(
                                                                  cells: [
                                                                    DataCell(
                                                                      Container(
                                                                        width:
                                                                            150,
                                                                        child:
                                                                            Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(muscleActivityComparison.workoutName,
                                                                                style: Get.isDarkMode ? AppTheme.appDarkTheme.textTheme.bodyText1 : AppTheme.appTheme.textTheme.bodyText1),
                                                                            Text(getMinutesAndSecondsFromDurationWithSign(duration: Duration(seconds: DateTime.parse(muscleActivityComparison.workoutReport.endedAt).difference(DateTime.parse(muscleActivityComparison.workoutReport.startedAt)).inSeconds)),
                                                                                style: Get.isDarkMode ? AppTheme.appDarkTheme.textTheme.overline : AppTheme.appTheme.textTheme.overline)
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      AppDataCellPercentageBox(
                                                                          cellWidth:
                                                                              90,
                                                                          value: muscleActivityComparison
                                                                              .sensorReport
                                                                              .avrAmp,
                                                                          maxValue:
                                                                              listAllSensorValuesFromAvrAmp.last),
                                                                    ),
                                                                    DataCell(
                                                                      AppDataCellPercentageBox(
                                                                          cellWidth:
                                                                              90,
                                                                          value: muscleActivityComparison
                                                                              .sensorReport
                                                                              .maxAmp,
                                                                          maxValue:
                                                                              listAllSensorValuesFromMaxAmp.last),
                                                                    ),
                                                                    DataCell(
                                                                      AppDataCellPercentageBox(
                                                                          cellWidth:
                                                                              90,
                                                                          value: muscleActivityComparison
                                                                              .sensorReport
                                                                              .minAmp,
                                                                          maxValue:
                                                                              listAllSensorValuesFromMinAmp.last),
                                                                    ),
                                                                    DataCell(
                                                                      AppDataCellPercentageBox(
                                                                          cellWidth:
                                                                              90,
                                                                          value: muscleActivityComparison
                                                                              .sensorReport
                                                                              .area,
                                                                          maxValue:
                                                                              listAllSensorValuesFromArea.last),
                                                                    ),
                                                                  ],
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  return Text('NADA NDADFA');
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ));
                                    }

                                    return Column(
                                      children: column,
                                    );
                                  } else {
                                    return Text(snapshotSensorReport
                                        .connectionState
                                        .toString());
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> getWorkoutReportFromSelectedSession() async {
    if (selectedSession != null) {
      var allRows = await WorkoutReportOperations()
          .getAllWorkoutReportsBySessionId(selectedSession!);

      allWorkoutReports = allRows;
    }

    setState(() {});
  }

  Future<List<UsedSensorResults>?> getUsedSensors() async {
    List<UsedSensorResults> listUsedSensors = [];
    List<WorkoutReport> allWorkoutReports;
    if (selectedSession != null) {
      allWorkoutReports = await WorkoutReportOperations()
          .getAllWorkoutReportsBySessionId(selectedSession!);
      List<SensorReport> sensorReports = await SensorReportOperations()
          .getAllSensorReportsByWorkoutReportId(allWorkoutReports.first);
      for (var sensorReport in sensorReports) {
        var placement = await PlacementOperations()
            .getPlacementById(sensorReport.placementId);

        var usedSensor = await RegisteredSensorOperations()
            .getRegisteredSensorById(sensorReport.registeredSensorId);

        var usedSensorResults = UsedSensorResults(
            sensorId: usedSensor!.id!,
            muscleName: placement.bodyRegionId == 0
                ? 'Not assigned muscle'
                : placement.muscleName,
            bodyRegion: placement.bodyRegionId == 0
                ? 'Not assigned'
                : idToBodyRegionString(bodyRegionId: placement.bodyRegionId),
            side: sensorReport.side,
            color: buildColorNameFromSensor(
                rawSensorNameAndColor: usedSensor.color));

        listUsedSensors.add(usedSensorResults);
      }

      allUsedSensors = listUsedSensors;
      return listUsedSensors;
    }
  }
}

class SidePanel extends StatefulWidget {
  final Function(Session session) notifyParentSessionSelected;
  final Client client;
  const SidePanel({
    Key? key,
    required this.notifyParentSessionSelected,
    required this.client,
  }) : super(key: key);

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel>
    with SingleTickerProviderStateMixin {
  final sidePanelWidth = 340.0;
  // Data table variables
  int sortColumnIndex = 0;
  bool isAscending = true;

  late TextEditingController _textEditingController;

  Session? selectedSession;
  int selectedBodyRegion = Constants.allBodyRegions;
  // Async load data on init:
  List<Session> searchedClientSessions = [];
  List<Session> allClientSessions = [];
  List<BodyRegion> allBodyRegions = [];

  late Future initAllSessions;
  late Future initBodyRegions;

  @override
  void initState() {
    initAllSessions = _getClientSessionsByBodyRegionIdDBAsync(bodyRegionId: 0);

    initBodyRegions = _getAllBodyRegionsDBAsync();

    // Text Field for Session Searching
    _textEditingController = TextEditingController();
    _textEditingController.addListener(() {
      filterSessions();
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  filterSessions() {
    List<Session>? sessions = [];
    if (_textEditingController.text.isNotEmpty) {
      sessions.addAll(allClientSessions.toList());
      sessions.retainWhere((Session s) {
        String searchTerm = _textEditingController.text.toLowerCase();

        String title = s.name.toLowerCase();

        return title.contains(searchTerm);
      });
      searchedClientSessions.clear();
      searchedClientSessions.addAll(sessions);
      log(searchedClientSessions.length.toString());

      setState(() {});
    }
  }

  int compareString(bool ascending, String value1, String value2) {
    return ascending ? value1.compareTo(value2) : value2.compareTo(value1);
  }

  void onSort(int columnIndex, bool ascending) {
    log('sorted');
    if (columnIndex == 0) {
      allClientSessions.sort((value1, value2) =>
          compareString(ascending, value1.startedAt, value2.startedAt));
    }
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  List<DataRow> getRowsAllSessions(List<Session> sessions) {
    return sessions
        .map((Session session) => DataRow(
              color: MaterialStateColor.resolveWith(
                (states) {
                  if (states.isNotEmpty) {
                    return Get.isDarkMode
                        ? AppTheme.appDarkTheme.highlightColor
                        : AppTheme.appTheme.highlightColor;
                  } else {
                    return Get.isDarkMode
                        ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                        : AppTheme.appTheme.scaffoldBackgroundColor;
                  }
                },
              ),
              selected: selectedSession == session,
              onSelectChanged: (value) {
                selectedSession = session;
                widget.notifyParentSessionSelected(selectedSession!);
                setState(() {});
              },
              cells: [
                DataCell(Text(iso8601StringToDate(session.startedAt),
                    style: Get.isDarkMode
                        ? AppTheme.appDarkTheme.textTheme.bodyText2
                        : AppTheme.appTheme.textTheme.bodyText2)),
                DataCell(
                  Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: Text(
                            session.name.isEmpty
                                ? 'Unnamed'
                                : session.name.toCapitalized(),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: Get.isDarkMode
                                ? AppTheme.appDarkTheme.textTheme.bodyText2
                                : AppTheme.appTheme.textTheme.bodyText2),
                      ),
                    ],
                  ),
                ),
              ],
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sidePanelWidth,
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
              width: 1.0,
              color: Get.isDarkMode
                  ? AppTheme.appDarkTheme.dividerColor
                  : AppTheme.appTheme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        onPressed: Get.back,
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  '${widget.client.surname} ${widget.client.name}',
                                  style: Get.isDarkMode
                                      ? AppTheme
                                          .appDarkTheme.textTheme.headline5
                                      : AppTheme.appTheme.textTheme.headline5),
                              Text(
                                  allClientSessions.length != 1
                                      ? '${allClientSessions.length} sessions'
                                      : '${allClientSessions.length} session',
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
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 16),
            width: sidePanelWidth,
            child: Row(
              children: [
                PopupMenuButton(
                    initialValue: selectedBodyRegion,
                    onSelected: (int value) async {
                      selectedBodyRegion = value;
                      await _getClientSessionsByBodyRegionIdDBAsync(
                          bodyRegionId: value);
                      setState(() {});
                    },
                    constraints: BoxConstraints(minWidth: 200),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                    ),
                    elevation: 0.2,
                    color: Get.isDarkMode
                        ? AppTheme.appDarkTheme.colorScheme.surface
                        : AppTheme.appTheme.colorScheme.surface,
                    position: PopupMenuPosition.under,
                    offset: Offset(24, 4),
                    // offset: Offset(48, -10),
                    splashRadius: 46,
                    icon: Icon(
                      Icons.filter_list,
                      size: 32,
                      color: Get.isDarkMode
                          ? AppTheme.appDarkTheme.colorScheme.shadow
                          : AppTheme.appTheme.colorScheme.shadow,
                    ),
                    itemBuilder: (context) => [
                          for (var bodyRegion in allBodyRegions)
                            PopupMenuItem(
                              value: bodyRegion.id,
                              child: Row(
                                children: [
                                  // CircleAvatar(
                                  //   backgroundColor:
                                  //       Colors.black.withOpacity(0.05),
                                  //   radius: 22,
                                  //   child: Align(
                                  //     alignment: Alignment.center,
                                  //     child: Icon(Icons.dark_mode,
                                  //         size: 22, color: Color(0xffffffff)),
                                  //   ),
                                  // ),
                                  const SizedBox(width: 10),
                                  Text(bodyRegion.name,
                                      style: Get.isDarkMode
                                          ? AppTheme
                                              .appDarkTheme.textTheme.bodyText1
                                          : AppTheme
                                              .appTheme.textTheme.bodyText1),
                                ],
                              ),
                            ),
                        ]),
                Flexible(
                  flex: 1,
                  child: AppTextFieldSearch(
                    textEditingController: _textEditingController,
                    hintText: 'Search session',
                    onCancelButtonPressed: () {
                      if (_textEditingController.text != '') {
                        searchedClientSessions.clear();
                        _textEditingController.text = '';
                        FocusManager.instance.primaryFocus?.unfocus();
                      } else {
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                      setState(() {});
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: AppIconButton(
                    onPressed: () => Get.to(
                      () => SessionSetupScreen(client: widget.client),
                    ),
                    iconData: Icons.sports_gymnastics,
                    size: ButtonSize.small,
                    backgroundColor: Get.isDarkMode
                        ? AppTheme.appDarkTheme.colorScheme.primary
                            .withAlpha(200)
                        : AppTheme.appTheme.colorScheme.primary.withAlpha(200),
                    iconColor: Colors.white,
                  ),
                )
              ],
            ),
          ),
          if (allClientSessions.isEmpty)
            EmptyJournal(
                widget: widget, selectedBodyRegion: selectedBodyRegion),
          if (allClientSessions.isNotEmpty)
            Expanded(
              child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    children: [
                      DataTable(
                        showCheckboxColumn: false,
                        horizontalMargin: 10,
                        dataRowHeight: 70,
                        sortColumnIndex: sortColumnIndex,
                        sortAscending: isAscending,
                        columns: [
                          DataColumn(
                            tooltip: 'Date when client was registered',
                            label: Text('Date',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                    : AppTheme.appTheme.textTheme.headline5),
                            onSort: onSort,
                          ),
                          DataColumn(
                            tooltip: "Client's full name",
                            label: Text('Title',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                    : AppTheme.appTheme.textTheme.headline5),
                          ),
                        ],
                        rows: _textEditingController.text.isNotEmpty
                            ? getRowsAllSessions(searchedClientSessions)
                            : getRowsAllSessions(allClientSessions),
                      ),
                    ],
                  )),
            ),
        ],
      ),
    );
  }

  Future<void> _getAllBodyRegionsDBAsync() async {
    allBodyRegions = await BodyRegionOperations().getAllBodyRegions();
    setState(() {});
  }

  // - All client sessions by body region
  Future<void> _getClientSessionsByBodyRegionIdDBAsync(
      {required int bodyRegionId}) async {
    if (selectedBodyRegion == Constants.allBodyRegions) {
      allClientSessions =
          await SessionOperations().getAllSessionsByClientID(widget.client);
    } else {
      allClientSessions = await SessionOperations()
          .getAllSessionsByClientIDAndBodyRegionId(
              client: widget.client, bodyRegionId: selectedBodyRegion);
    }
    if (allClientSessions.isNotEmpty && selectedSession == null) {
      selectedSession = allClientSessions.last;
      widget.notifyParentSessionSelected(selectedSession!);
    }
    if (allClientSessions.isNotEmpty) {
      allClientSessions.sort(
        (a, b) => b.startedAt.compareTo(a.startedAt),
      );
    }
  }
}

class EmptyJournal extends StatelessWidget {
  const EmptyJournal({
    Key? key,
    required this.widget,
    this.selectedBodyRegion,
  }) : super(key: key);

  final SidePanel widget;
  final int? selectedBodyRegion;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(height: 240),
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.fromLTRB(8, 32, 8, 8),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Column(
        children: [
          if (selectedBodyRegion != null && selectedBodyRegion == 0)
            AppHeaderInfo(
              title: 'The Journal is empty',
              labelPrimary:
                  'Start a new session with ${widget.client.name} by pressing the button below',
            ),
          if (selectedBodyRegion != null && selectedBodyRegion != 0)
            AppHeaderInfo(
              title: 'No sessions',
              labelPrimary:
                  'Any session recorded for ${idToBodyRegionString(bodyRegionId: selectedBodyRegion!)} muscles',
              labelSecondary: 'Start a new session by pressing on the button',
            ),
          Spacer(),
          AppBottom(
              onPressed: () => Get.to(
                    () => SessionSetupScreen(client: widget.client),
                  ),
              mainText: 'Start new Session')
        ],
      ),
    );
  }
}

// Number of sessions
//            Padding(
//   padding:
//       const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
//   child: Row(
//     children: [
//       RichText(
//         text: TextSpan(
//           style: Get.isDarkMode
//               ? AppTheme.appDarkTheme.textTheme.headline3
//                   ?.copyWith(color: Colors.white)
//               : AppTheme.appTheme.textTheme.headline3,
//           children: <TextSpan>[
//             const TextSpan(text: 'Sessions '),
//             TextSpan(
//                 text: '16',
//                 style: Get.isDarkMode
//                     ? AppTheme.appDarkTheme.textTheme.headline3
//                         ?.copyWith(
//                         shadows: [
//                           Shadow(
//                               color: Colors.white,
//                               offset: Offset(0, -2))
//                         ],
//                         color: Colors.transparent,
//                         decorationThickness: 2,
//                         decoration: TextDecoration.underline,
//                         decorationColor: Color(0xffe40031),
//                       )
//                     : AppTheme.appTheme.textTheme.headline3
//                         ?.copyWith(color: Color(0xffe40031))),
//           ],
//         ),
//       ),
//     ],
//   ),
// ),

