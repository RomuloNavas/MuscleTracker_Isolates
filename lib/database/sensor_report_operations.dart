

import 'package:neuro_sdk_isolate_example/database/database.dart';
import 'package:neuro_sdk_isolate_example/database/workout_report_operations.dart';

class SensorReportOperations {
  SensorReportOperations? sensorReportOperations;

  final dbProvider = DatabaseRepository.instance;

  createSensorReport(SensorReport sensorReport) async {
    final db = await dbProvider.database;
    db.insert('sensorReport', sensorReport.toJson());
  }

  deleteSensorReport(SensorReport sensorReport) async {
    final db = await dbProvider.database;
    await db.delete('sensorReport',
        where: 'sensorReportId = ?', whereArgs: [sensorReport.id]);
  }

  Future<List<SensorReport>> getAllSensorReportsByWorkoutReportId(
      WorkoutReport workoutReport) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM sensorReport 
    WHERE sensorReport.workoutReportId = ${workoutReport.id}
    ''');
    List<SensorReport> sensorReports = allRows
        .map((sessionJson) => SensorReport.fromJson(sessionJson))
        .toList();
    return sensorReports;
  }

  Future<List<SensorReport>> getAllSensorReportsByWorkoutReportIdAndSensorId(
      int workoutReportId, int registeredSensorId) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM sensorReport 
    WHERE sensorReport.workoutReportId = $workoutReportId AND sensorReport.registeredSensorId = $registeredSensorId
    ''');
    List<SensorReport> sensorReports = allRows
        .map((sessionJson) => SensorReport.fromJson(sessionJson))
        .toList();
    return sensorReports;
  }
}

class SensorReport {
  int? id;
  late double maxAmp;
  late double minAmp;
  late double avrAmp;
  late double area;
  late int registeredSensorId;
  int? placementId;

  late int workoutReportId;

  SensorReport({
    this.id,
    required this.maxAmp,
    required this.minAmp,
    required this.avrAmp,
    required this.area,
    required this.registeredSensorId,
    this.placementId,
    required this.workoutReportId,
  });

  factory SensorReport.fromJson(Map<String, dynamic> json) => SensorReport(
        id: json['sensorReportId'],
        maxAmp: json['sensorReportMaxAmp'],
        minAmp: json['sensorReportMinAmp'],
        avrAmp: json['sensorReportAvrAmp'],
        area: json['sensorReportArea'],
        registeredSensorId: json['registeredSensorId'],
        placementId: json['placementId'],
        workoutReportId: json['workoutReportId'],
      );

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{
      'sensorReportMaxAmp': maxAmp,
      'sensorReportMinAmp': minAmp,
      'sensorReportAvrAmp': avrAmp,
      'sensorReportArea': area,
      'registeredSensorId': registeredSensorId,
      'placementId': placementId,
      'workoutReportId': workoutReportId,
    };

    return map;
  }
}
