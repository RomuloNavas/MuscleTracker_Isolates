import 'package:neuro_sdk_isolate_example/database/database.dart';
import 'package:neuro_sdk_isolate_example/database/session_operations.dart';

class WorkoutReportOperations {
  WorkoutReportOperations? workoutReportOperations;

  final dbProvider = DatabaseRepository.instance;

  Future<int> createWorkoutReport(WorkoutReport workoutReport) async {
    final db = await dbProvider.database;
    int idOfTheLastInsertedRow =
        await db.insert('workoutReport', workoutReport.toJson());
    return idOfTheLastInsertedRow;
  }

  // Session contains the workout report Id
  Future<WorkoutReport?> getWorkoutReportById(int workoutReportId) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('workoutReport',
        where: 'workoutReportId = ?', whereArgs: [workoutReportId]);

    List<WorkoutReport> workoutReport = allRows
        .map((workoutReport) => WorkoutReport.fromJson(workoutReport))
        .toList();
    if (workoutReport.isNotEmpty) {
      return workoutReport.first;
    } else {
      return null;
    }
  }

  deleteWorkoutReport(WorkoutReport workoutReport) async {
    final db = await dbProvider.database;
    await db.delete('workoutReport',
        where: 'workoutReportId = ?', whereArgs: [workoutReport.id]);
  }

  Future<List<WorkoutReport>> getAllWorkoutReports() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('workoutReport');
    List<WorkoutReport> categories = allRows
        .map((workoutReport) => WorkoutReport.fromJson(workoutReport))
        .toList();
    return categories;
  }

  Future<WorkoutReport> getLastAddedWorkoutReport() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM workoutReport ORDER BY workoutReportId DESC LIMIT 1;
    ''');
    WorkoutReport lastAddedWorkoutReport = allRows
        .map((sessionJson) => WorkoutReport.fromJson(sessionJson))
        .toList()
        .first;
    return lastAddedWorkoutReport;
  }

  Future<List<WorkoutReport>> getAllWorkoutReportsBySessionId(
      Session session) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM workoutReport 
    WHERE workoutReport.FK_WorkoutReport_sessionId = ${session.id}
    ''');
    List<WorkoutReport> workoutReports = allRows
        .map((sessionJson) => WorkoutReport.fromJson(sessionJson))
        .toList();
    return workoutReports;
  }
}

class WorkoutReport {
  int? id;
  late String startedAt;
  late String endedAt;

  late int sessionId;
  late int workoutId;

  WorkoutReport({
    this.id,
    required this.startedAt,
    required this.endedAt,
    required this.sessionId,
    required this.workoutId,
  });

  factory WorkoutReport.fromJson(Map<String, dynamic> obj) => WorkoutReport(
        id: obj['workoutReportId'],
        startedAt: obj['workoutReportStartedAt'],
        endedAt: obj['workoutReportEndedAt'],
        sessionId: obj['FK_WorkoutReport_sessionId'],
        workoutId: obj['FK_WorkoutReport_workoutId'],
      );

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{
      'workoutReportStartedAt': startedAt,
      'workoutReportEndedAt': endedAt,
      'FK_WorkoutReport_sessionId': sessionId,
      'FK_WorkoutReport_workoutId': workoutId,
    };

    return map;
  }
}
