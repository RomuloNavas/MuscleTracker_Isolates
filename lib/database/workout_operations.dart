import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:neuro_sdk_isolate_example/database/database.dart';

class ExerciseOperations {
  ExerciseOperations? workoutOperations;

  final dbProvider = DatabaseRepository.instance;

  createWorkout(Exercise workout) async {
    final db = await dbProvider.database;
    await db.insert("workout", workout.toJson());
  }

  Future<Exercise> getWorkoutById(int id) async {
    final db = await dbProvider.database;
    var allRows =
        await db.query("workout", where: "workoutId = ?", whereArgs: [id]);
    List<Exercise> workouts =
        allRows.map((workoutJson) => Exercise.fromMap(workoutJson)).toList();
    return workouts.first;
  }

  Future<List<Exercise>> getAllWorkouts() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('workout');
    List<Exercise> workouts =
        allRows.map((workoutJson) => Exercise.fromMap(workoutJson)).toList();
    return workouts;
  }

  initWorkouts() async {
    try {
      final db = await dbProvider.database;
      //Check if databases are empty to initialize them:
      var allRows = await db.query("workout", limit: 2);
      if (allRows.isEmpty) {
        final String jsonString =
            await rootBundle.loadString('lib/database/workouts.json');
        final jsonMap = jsonDecode(jsonString);

        for (var i = 0; i < jsonMap.length; i++) {
          await db.insert("workout", jsonMap[i]);
        }
        log('✅Workouts initialized', name: 'DBSensorWorkouts');
      }
    } catch (e) {
      log('ERROR $e', name: 'DBSensorWorkouts');
    }
  }

  Future<void> deleteAllWorkouts() async {
    final db = await dbProvider.database;
    await db.delete('workout');
  }
}

// -Workout MODEL
class Exercise {
  int? id; 
  String name;

  Exercise({
    this.id,
    required this.name,
  });

  factory Exercise.fromMap(Map<String, dynamic> json) => Exercise(
        id: json["workoutId"],
        name: json["workoutName"],
      );

  Map<String, dynamic> toJson() => {
        "workoutName": name,
      };
}
