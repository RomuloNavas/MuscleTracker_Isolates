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
import 'package:timeago/timeago.dart' as timeago;

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
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppTheme.appDarkTheme.colorScheme.surface
            : AppTheme.appTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      width: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
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
                  SizedBox(height: 2),
                  if (side != null) AppMuscleSideIndicator(side: side),
                ],
              ),
            ],
          ),
          SizedBox(width: 12),
          Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.contain,
                    image: AssetImage(
                      'assets/images/sensor_placements/$bodyRegionName/$muscleName.png',
                    )),
              ))
        ],
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
                          Text(
                            '${widget.client.surname} ${widget.client.name} ${widget.client.patronymic}',
                            style: Get.isDarkMode
                                ? AppTheme.appDarkTheme.textTheme.headline1
                                : AppTheme.appTheme.textTheme.headline1,
                          ),
                          SizedBox(height: 36),
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
                                    svgIconPath: 'trash',
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
                                    svgIconPath: 'edit',
                                    onPressed: () => null,
                                  ),
                                  AppIconButton(
                                    svgIconPath: 'compare', // compare
                                    onPressed: () => null,
                                  ),
                                  AppIconButton(
                                    svgIconPath: 'share',
                                    onPressed: () => null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          Text(
                            selectedSession!.name.isNotEmpty
                                ? 'Title: ${selectedSession!.name.toCapitalized()}'
                                : 'Unnamed Session',
                            style: Get.isDarkMode
                                ? AppTheme.appDarkTheme.textTheme.headline2
                                : AppTheme.appTheme.textTheme.headline2,
                          ),
                          if (selectedSession!.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                  'Description: ${selectedSession!.description.toCapitalized()}',
                                  style: Get.isDarkMode
                                      ? AppTheme.appDarkTheme.textTheme.caption
                                      : AppTheme.appTheme.textTheme.caption),
                            ),
                          const SizedBox(height: 48),
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
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary)),
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
                                    const SizedBox(height: 48),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Text("• ",
                                            style: AppTheme.appDarkTheme
                                                .textTheme.headline1
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary)),
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
                                      column.add(Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 12, top: 24),
                                        padding:
                                            EdgeInsets.fromLTRB(6, 12, 6, 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Get.isDarkMode
                                              ? AppTheme.appDarkTheme
                                                  .colorScheme.surface
                                              : AppTheme
                                                  .appTheme.colorScheme.surface,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              buildSensorPlacementCard(
                                                sensorColor: usedSensor.color,
                                                muscleName:
                                                    usedSensor.muscleName,
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
                                                          ConnectionState
                                                              .done &&
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
                                                      listAllSensorValuesFromArea
                                                          .add(
                                                              muscleActivityComparison
                                                                  .sensorReport
                                                                  .area);
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
                                                                            ? AppTheme.appDarkTheme.textTheme.headline5
                                                                            : AppTheme.appTheme.textTheme.headline5)),
                                                                DataColumn(
                                                                    label: Text(
                                                                        'A(avr), µV',
                                                                        style: Get.isDarkMode
                                                                            ? AppTheme.appDarkTheme.textTheme.headline5
                                                                            : AppTheme.appTheme.textTheme.headline5)),
                                                                DataColumn(
                                                                    label: Text(
                                                                        'A(max), µV',
                                                                        style: Get.isDarkMode
                                                                            ? AppTheme.appDarkTheme.textTheme.headline5
                                                                            : AppTheme.appTheme.textTheme.headline5)),
                                                                DataColumn(
                                                                    label: Text(
                                                                        'A(min), µV',
                                                                        style: Get.isDarkMode
                                                                            ? AppTheme.appDarkTheme.textTheme.headline5
                                                                            : AppTheme.appTheme.textTheme.headline5)),
                                                                DataColumn(
                                                                    label: Text(
                                                                        'S, mV*ms',
                                                                        style: Get.isDarkMode
                                                                            ? AppTheme.appDarkTheme.textTheme.headline5
                                                                            : AppTheme.appTheme.textTheme.headline5)),
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
                                                                              Text(muscleActivityComparison.workoutName, style: Get.isDarkMode ? AppTheme.appDarkTheme.textTheme.bodyText1 : AppTheme.appTheme.textTheme.bodyText1),
                                                                              Text(getMinutesAndSecondsFromDurationWithSign(duration: Duration(seconds: DateTime.parse(muscleActivityComparison.workoutReport.endedAt).difference(DateTime.parse(muscleActivityComparison.workoutReport.startedAt)).inSeconds)), style: Get.isDarkMode ? AppTheme.appDarkTheme.textTheme.overline : AppTheme.appTheme.textTheme.overline)
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      DataCell(
                                                                        AppDataCellPercentageBox(
                                                                            cellWidth:
                                                                                90,
                                                                            value:
                                                                                muscleActivityComparison.sensorReport.avrAmp,
                                                                            maxValue: listAllSensorValuesFromAvrAmp.last),
                                                                      ),
                                                                      DataCell(
                                                                        AppDataCellPercentageBox(
                                                                            cellWidth:
                                                                                90,
                                                                            value:
                                                                                muscleActivityComparison.sensorReport.maxAmp,
                                                                            maxValue: listAllSensorValuesFromMaxAmp.last),
                                                                      ),
                                                                      DataCell(
                                                                        AppDataCellPercentageBox(
                                                                            cellWidth:
                                                                                90,
                                                                            value:
                                                                                muscleActivityComparison.sensorReport.minAmp,
                                                                            maxValue: listAllSensorValuesFromMinAmp.last),
                                                                      ),
                                                                      DataCell(
                                                                        AppDataCellPercentageBox(
                                                                            cellWidth:
                                                                                90,
                                                                            value:
                                                                                muscleActivityComparison.sensorReport.area,
                                                                            maxValue: listAllSensorValuesFromArea.last),
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
                                                    return Text('Nothing');
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
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
  final _sidePanelWidth = 320.0;
  // Data table variables
  int sortColumnIndex = 0;
  bool isAscending = true;

  late TextEditingController _textEditingController;

  Session? selectedSession;
  int selectedBodyRegion = Constants.allBodyRegions;
  // Async load data on init:
  List<Session> _searchedClientSessions = [];
  List<Session> _allClientSessions = [];
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
      sessions.addAll(_allClientSessions.toList());
      sessions.retainWhere((Session s) {
        String searchTerm = _textEditingController.text.toLowerCase();

        String title = s.name.toLowerCase();

        return title.contains(searchTerm);
      });
      _searchedClientSessions.clear();
      _searchedClientSessions.addAll(sessions);
      log(_searchedClientSessions.length.toString());

      setState(() {});
    }
  }

  int compareString(bool ascending, String value1, String value2) {
    return ascending ? value1.compareTo(value2) : value2.compareTo(value1);
  }

  void onSort(int columnIndex, bool ascending) {
    log('sorted');
    if (columnIndex == 0) {
      _allClientSessions.sort((value1, value2) =>
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
                        ? AppTheme.appDarkTheme.colorScheme.surfaceVariant
                        : AppTheme.appTheme.colorScheme.surfaceVariant;
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
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(iso8601StringToDate(session.startedAt),
                        style: Get.isDarkMode
                            ? AppTheme.appDarkTheme.textTheme.bodyText2
                            : AppTheme.appTheme.textTheme.bodyText2),
                    Text(timeago.format(DateTime.parse(session.startedAt)),
                        style: AppTheme.appDarkTheme.textTheme.caption),
                  ],
                )),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                        session.name.isEmpty
                            ? 'Unnamed'
                            : session.name.toCapitalized(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Get.isDarkMode
                            ? AppTheme.appDarkTheme.textTheme.bodyText2
                            : AppTheme.appTheme.textTheme.bodyText2),
                  ),
                ),
              ],
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _sidePanelWidth,
      padding: const EdgeInsets.only(
        top: 16,
        left: 6,
        right: 6,
      ),
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
      child: Column(
        children: [
          SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AppIconButton(
                      size: ButtonSize.big,
                      svgIconPath: 'arrow-left',
                      onPressed: Get.back,
                    ),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Client's Journal",
                            textAlign: TextAlign.left,
                            style: Get.isDarkMode
                                ? AppTheme.appDarkTheme.textTheme.headline2
                                : AppTheme.appTheme.textTheme.headline2),
                        SizedBox(
                          child: Text(
                              '${widget.client.surname} ${widget.client.name} ${widget.client.patronymic}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              textAlign: TextAlign.right,
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.overline
                                  : AppTheme.appTheme.textTheme.overline),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: AppTextFieldSearch(
                        textEditingController: _textEditingController,
                        hintText: _allClientSessions.length == 1
                            ? '${_allClientSessions.length} session'
                            : '${_allClientSessions.length} sessions',
                        onCancelButtonPressed: () {
                          if (_textEditingController.text != '') {
                            _searchedClientSessions.clear();
                            _textEditingController.text = '';
                            FocusManager.instance.primaryFocus?.unfocus();
                          } else {
                            FocusManager.instance.primaryFocus?.unfocus();
                          }
                          setState(() {});
                        },
                      ),
                    ),
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
                        splashRadius: 46,
                        icon: AppIconButton(
                          size: ButtonSize.medium,
                          svgIconPath: 'filter',
                        ),
                        itemBuilder: (context) => [
                              for (var bodyRegion in allBodyRegions)
                                PopupMenuItem(
                                  value: bodyRegion.id,
                                  child: Text(bodyRegion.name,
                                      style: Get.isDarkMode
                                          ? AppTheme
                                              .appDarkTheme.textTheme.bodyText1
                                          : AppTheme
                                              .appTheme.textTheme.bodyText1),
                                ),
                            ]),
                  ],
                ),
              ],
            ),
          ),
          if (_allClientSessions.isEmpty)
            EmptyJournal(
                widget: widget, selectedBodyRegion: selectedBodyRegion),
          if (_allClientSessions.isNotEmpty)
            Expanded(
              child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    children: [
                      SizedBox(height: 8),
                      AppIconButton(
                        onPressed: () => Get.to(
                          () => SessionSetupScreen(client: widget.client),
                        ),
                        svgIconPath: 'activity',
                        text: 'Start new session',
                      ),
                      DataTable(
                        showCheckboxColumn: false,
                        horizontalMargin: 6,
                        dataRowHeight: 60,
                        sortColumnIndex: sortColumnIndex,
                        sortAscending: isAscending,
                        columns: [
                          DataColumn(
                            tooltip: 'Date when session was created',
                            label: Text('Date',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                    : AppTheme.appTheme.textTheme.headline5),
                            onSort: onSort,
                          ),
                          DataColumn(
                            tooltip: "Session's Title",
                            label: Text('Title',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                    : AppTheme.appTheme.textTheme.headline5),
                          ),
                        ],
                        rows: _textEditingController.text.isNotEmpty
                            ? getRowsAllSessions(_searchedClientSessions)
                            : getRowsAllSessions(_allClientSessions),
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
      _allClientSessions =
          await SessionOperations().getAllSessionsByClientID(widget.client);
    } else {
      _allClientSessions = await SessionOperations()
          .getAllSessionsByClientIDAndBodyRegionId(
              client: widget.client, bodyRegionId: selectedBodyRegion);
    }
    if (_allClientSessions.isNotEmpty && selectedSession == null) {
      selectedSession = _allClientSessions.last;
      widget.notifyParentSessionSelected(selectedSession!);
    }
    if (_allClientSessions.isNotEmpty) {
      _allClientSessions.sort(
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
    {
      return Expanded(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Builder(builder: (context) {
              if (selectedBodyRegion != null && selectedBodyRegion == 0) {
                return AppHeaderInfo(
                  title: 'Empty Journal',
                  labelPrimary: "You haven't recorded any session",
                );
              } else if (selectedBodyRegion != null &&
                  selectedBodyRegion != 0) {
                return AppHeaderInfo(
                  title: 'Empty',
                  labelPrimary:
                      'Any session recorded for ${idToBodyRegionString(bodyRegionId: selectedBodyRegion!)} muscles',
                );
              }
              return SizedBox();
            }),
            SizedBox(
              width: 180,
              // height: 220,
              child: SvgPicture.asset(
                'assets/illustrations/empty.svg',
                width: 180,
              ),
            ),
            SizedBox(height: 24),
            AppIconButton(
              onPressed: () => Get.to(
                () => SessionSetupScreen(client: widget.client),
              ),
              svgIconPath: 'activity',
              text: 'Start new session',
            ),
          ],
        ),
      ));
    }
  }
}
