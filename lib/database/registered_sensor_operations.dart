import 'dart:developer';

import 'package:neuro_sdk_isolate_example/database/database.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';

class RegisteredSensorOperations {
  RegisteredSensorOperations? registeredSensorOperations;
  final dbProvider = DatabaseRepository.instance;

  Future<void> insertNewSensor(RegisteredSensor registeredSensor) async {
    final db = await dbProvider.database;
    db.insert('registeredSensor', registeredSensor.toJson());
  }

  Future<List<RegisteredSensor>> getAllRegisteredSensors() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('registeredSensor');
    List<RegisteredSensor> registeredSensors =
        allRows.map((rsJson) => RegisteredSensor.fromJson(rsJson)).toList();
    return registeredSensors;
  }

  Future<RegisteredSensor?> getRegisteredSensorByAddress(String address) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('registeredSensor',
        where: 'registeredSensorAddress=?', whereArgs: [address]);
    List<RegisteredSensor> registeredSensors =
        allRows.map((rsJson) => RegisteredSensor.fromJson(rsJson)).toList();
    if (registeredSensors.isNotEmpty) {
      return registeredSensors.first;
    } else {
      return null;
    }
  }

  Future<List<RegisteredSensor>> getAllRegisteredSensorsByUser(
      User user) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM registeredSensor 
    WHERE registeredSensor.user_id = ${user.id}
    ''');
    List<RegisteredSensor> registeredSensors =
        allRows.map((rsJson) => RegisteredSensor.fromJson(rsJson)).toList();

    return registeredSensors;
  }

  Future<List<RegisteredSensor>> getRegisteredSensorsUsedByUser(
      User user) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM registeredSensor 
    WHERE registeredSensor.user_id = ${user.id} AND registeredSensor.registered_sensor_is_being_used = 1
    ''');
    List<RegisteredSensor> registeredSensors =
        allRows.map((rsJson) => RegisteredSensor.fromJson(rsJson)).toList();

    return registeredSensors;
  }

  Future<void> updateRegisteredSensorBattery(
      RegisteredSensor registeredSensor) async {
    final db = await dbProvider.database;
    User? loggedInUser;
    try {
      loggedInUser = await UserOperations().getLoggedInUser();
    } catch (e) {
      log("Could't get logged user to update sensor");
    }
    if (loggedInUser != null) {
      registeredSensor.userId = loggedInUser.id!;
      await db.update('registeredSensor', registeredSensor.toJson(),
          where: 'registeredSensorId=?', whereArgs: [registeredSensor.id]);
    }
  }

  Future<void> updateUserUsedSensors() async {
    final db = await dbProvider.database;
    User? loggedInUser;
    try {
      loggedInUser = await UserOperations().getLoggedInUser();
    } catch (e) {
      log('$e',
          name:
              'registered_sensor_operations, updateUserUsedSensors, loggedInUse');
    }

    if (loggedInUser != null) {
      try {
        int id = await db.rawUpdate('''
    UPDATE registeredSensor 
    SET registered_sensor_is_being_used = 0
    WHERE registeredSensor.user_id = ${loggedInUser.id}
    ''');
      } catch (e) {
        log('$e',
            name:
                'registered_sensor_operations, updateUserUsedSensors, loggedInUser');
      }
    }
  }

  Future<RegisteredSensor?> getRegisteredSensorById(
      int registeredSensorId) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('registeredSensor',
        where: 'registeredSensorId = ?', whereArgs: [registeredSensorId]);
    List<RegisteredSensor> registeredSensors =
        allRows.map((rsJson) => RegisteredSensor.fromJson(rsJson)).toList();
    if (registeredSensors.isNotEmpty) {
      return registeredSensors.first;
    } else {
      return null;
    }
  }
}

// - REGISTERED SENSOR MODEL

class RegisteredSensor {
  int? id;
  String serialNumber;
  String address;
  String color;
  int userId;
  int? battery;
  int isBeingUsed;

  bool? isSelectedToAssignPlacement;

  RegisteredSensor({
    this.id,
    required this.serialNumber,
    required this.address,
    required this.color,
    required this.userId,
    required this.isBeingUsed,
    this.battery,

    // This parameter doesn't go to database. It is used in SessionSetupScreen.
    this.isSelectedToAssignPlacement,
  });

  factory RegisteredSensor.fromJson(Map<String, dynamic> json) =>
      RegisteredSensor(
        id: json["registeredSensorId"],
        serialNumber: json["registeredSensorSerialNumber"],
        address: json["registeredSensorAddress"],
        color: json["registeredSensorColor"],
        battery: json["registeredSensorBattery"],
        isBeingUsed: json["registered_sensor_is_being_used"],
        userId: json["user_id"],
      );

  Map<String, dynamic> toJson() => {
        "registeredSensorSerialNumber": serialNumber,
        "registeredSensorAddress": address,
        "registeredSensorColor": color,
        "registeredSensorBattery": battery,
        "registered_sensor_is_being_used": isBeingUsed,
        "user_id": userId,
      };
}
