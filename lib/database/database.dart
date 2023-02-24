import 'dart:developer';
import 'dart:io';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/workout_operations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class DatabaseRepository {
  DatabaseRepository.privateConstructor();

  static final DatabaseRepository instance =
      DatabaseRepository.privateConstructor();

  final _databaseName = 'database16';
  final _databaseVersion = 1;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDatabase();
      return _database!;
    }
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: onCreate,
    );
  }

  Future onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE user (
            user_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_name TEXT NOT NULL,
            user_email TEXT NOT NULL UNIQUE,
            user_password TEXT NOT NULL,
            user_is_logged_in BOOLEAN NOT NULL
          )
          ''');
    await db.execute('''
          CREATE TABLE registeredSensor (
            registeredSensorId INTEGER PRIMARY KEY AUTOINCREMENT,
            registeredSensorSerialNumber TEXT,
            registeredSensorAddress TEXT,
            registeredSensorColor TEXT,
            registeredSensorBattery INTEGER,
            registered_sensor_is_being_used BOOLEAN,

            user_id INT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES user (user_id)
          )
          ''');

    await db.execute('''
          CREATE TABLE client (
            clientId INTEGER PRIMARY KEY AUTOINCREMENT,
            clientName TEXT NOT NULL,
            clientSurname TEXT NOT NULL,
            clientPatronymic TEXT,
            clientMobile TEXT UNIQUE,
            clientEmail TEXT UNIQUE,
            clientBirthday TEXT NOT NULL,
            clientHeight REAL,
            clientWeight REAL,
            clientIsFavorite BOOLEAN,
            clientRegisteredDate TEXT NOT NULL,
            clientLastVisitDate TEXT,   

            user_id INT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES user (user_id)

          )
          ''');

    await db.execute('''
         CREATE INDEX idx_client_user_id
            ON client (user_id);

          ''');

    await db.execute('''
          CREATE TABLE session (
            sessionId INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionName TEXT NOT NULL,
            sessionStartedAt TEXT NOT NULL,
            sessionEndedAt TEXT NOT NULL,
            sessionDescription TEXT,

            FK_Session_bodyRegionId INT,
            FK_Session_clientId INT NOT NULL,
            FOREIGN KEY (FK_Session_bodyRegionId) REFERENCES bodyRegion (bodyRegionId),
            FOREIGN KEY (FK_Session_clientId) REFERENCES client (clientId)

          )
          ''');

    await db.execute('''
          CREATE TABLE workout (
            workoutId INTEGER PRIMARY KEY AUTOINCREMENT,           
            workoutName TEXT NOT NULL

          )
          ''');

    //sensorOne= "red,max12,min2,avr5,area10"
    //sensorTwo= "yellow,max12,min2,avr5,area10"
    await db.execute('''
          CREATE TABLE workoutReport (
            workoutReportId INTEGER PRIMARY KEY AUTOINCREMENT,
            workoutReportStartedAt String NOT NULL,
            workoutReportEndedAt String NOT NULL,

            FK_WorkoutReport_sessionId INTEGER NOT NULL,
            FK_WorkoutReport_workoutId INTEGER NOT NULL,
            FOREIGN KEY (FK_WorkoutReport_sessionId) REFERENCES session (sessionId),
            FOREIGN KEY (FK_WorkoutReport_workoutId) REFERENCES workout (workoutId) 

          )
          ''');

    await db.execute('''
          CREATE TABLE sensorReport (
            sensorReportId INTEGER PRIMARY KEY AUTOINCREMENT,
            sensorReportMaxAmp  REAL NOT NULL,
            sensorReportMinAmp  REAL NOT NULL,
            sensorReportAvrAmp  REAL NOT NULL,
            sensorReportArea REAL NOT NULL,
            registeredSensorId INTEGER NOT NULL,
            placementId INTEGER,
            workoutReportSide TEXT,

            workoutReportId INTEGER NOT NULL,
            FOREIGN KEY (workoutReportId) REFERENCES workoutReport (workoutReportId)

          )
          ''');

    await db.execute('''
          CREATE TABLE bodyRegion (
            bodyRegionId INTEGER PRIMARY KEY,
            bodyRegionName TEXT NOT NULL
            
          )
          ''');

    await db.execute('''
          CREATE TABLE placement (
            placementId INTEGER PRIMARY KEY,
            placementMuscleName TEXT NOT NULL,
            placementAction TEXT,
            placementMuscleInsertions TEXT,
            placementLocationDescription TEXT,
            placementBehavioralTest TEXT,
            placementSide TEXT,

            FK_Placement_bodyRegionId INT NOT NULL,
            FOREIGN KEY (FK_Placement_bodyRegionId) REFERENCES bodyRegion (bodyRegionId) 


          )
          ''');
  }
}
