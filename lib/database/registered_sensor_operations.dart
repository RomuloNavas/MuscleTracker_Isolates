import 'package:neuro_sdk_isolate_example/database/database.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';

class RegisteredSensorOperations {
  RegisteredSensorOperations? registeredSensorOperations;
  final dbProvider = DatabaseRepository.instance;

  Future<void>insertNewSensor(RegisteredSensor registeredSensor) async {
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

  Future<List<RegisteredSensor>> getRegisteredSensorsByUser(User user) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM registeredSensor 
    WHERE registeredSensor.user_id = ${user.id}
    ''');
    List<RegisteredSensor> registeredSensors =
        allRows.map((rsJson) => RegisteredSensor.fromJson(rsJson)).toList();

    return registeredSensors;
  }

  Future<void> updateRegisteredSensorBatteryByAddress(
      String address, RegisteredSensor registeredSensor) async {
    final db = await dbProvider.database;
    await db.update('registeredSensor', registeredSensor.toJson(),
        where: 'registeredSensorAddress=?', whereArgs: [address]);
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
  String gain;
  String dataOffset;
  String adcInput;
  String hardwareFilters;
  String samplingFrequency;
  int userId;
  int? battery;

  bool? isSelectedToAssignPlacement;

  RegisteredSensor({
    this.id,
    required this.serialNumber,
    required this.address,
    required this.color,
    required this.gain,
    required this.dataOffset,
    required this.adcInput,
    required this.hardwareFilters,
    required this.samplingFrequency,
    required this.userId,
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
        gain: json["registeredSensorGain"],
        dataOffset: json["registeredSensorDataOffset"],
        adcInput: json["registeredSensorADCinput"],
        hardwareFilters: json["registeredSensorHardwareFilters"],
        samplingFrequency: json["registeredSensorSamplingFrequency"],
        battery: json["registeredSensorBattery"],
        userId: json["user_id"],
      );

  Map<String, dynamic> toJson() => {
        "registeredSensorSerialNumber": serialNumber,
        "registeredSensorAddress": address,
        "registeredSensorColor": color,
        "registeredSensorGain": gain,
        "registeredSensorDataOffset": dataOffset,
        "registeredSensorADCinput": adcInput,
        "registeredSensorHardwareFilters": hardwareFilters,
        "registeredSensorSamplingFrequency": samplingFrequency,
        "registeredSensorBattery": battery,
        "user_id": userId,
      };
}
