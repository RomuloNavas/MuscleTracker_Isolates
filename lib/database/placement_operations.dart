import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/database.dart';

class PlacementOperations {
  PlacementOperations? placementOperations;

  final dbProvider = DatabaseRepository.instance;

  createMuscle(Placement placement) async {
    final db = await dbProvider.database;
    await db.insert("placement", placement.toJson());
  }

  Future<Placement> getPlacementById(int? placementId) async {
    if(placementId == 0 ||  placementId == null){
      return Placement(muscleName: 'Not assigned muscle');
    }
    final db = await dbProvider.database;
    var allRows =
        await db.query("placement", where: "placementId = ?", whereArgs: [placementId]);
    List<Placement> placements = allRows
        .map((placementJson) => Placement.fromMap(placementJson))
        .toList();
    return placements.first;
  }

  Future<List<Placement>> getAllPlacementsByBodyRegion(
      BodyRegionEnum bodyRegion) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM placement 
    WHERE placement.FK_Placement_bodyRegionId = ${bodyRegionToId(bodyRegion)}
    ''');
    List<Placement> placements =
        allRows.map((contact) => Placement.fromMap(contact)).toList();
    return placements;
  }

  Future<List<Placement>> getAllPlacements() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('placement');
    List<Placement> placements = allRows
        .map((placementJson) => Placement.fromMap(placementJson))
        .toList();
    return placements;
  }

  Future<List<Map<String, Object?>>> getAllPlacementsInJson() async {
    final db = await dbProvider.database;
    var res = await db.query("placement");
    return res;
  }

  initPlacements() async {
    try {
      final db = await dbProvider.database;
      //Check if databases are empty to initialize them:
      var allRows = await db.query("placement");
      if (allRows.isEmpty) {
        final String jsonString =
            await rootBundle.loadString('lib/database/sensor_placement.json');
        final jsonMap = jsonDecode(jsonString);

        for (var i = 0; i < jsonMap.length; i++) {
          await db.insert("placement", jsonMap[i]);
        }
        log('✅Placements initialized', name: 'DBSensorPlacements');
      }
    } catch (e) {
      log('ERROR $e', name: 'DBSensorPlacements');
    }
  }

  Future<void> deleteAllPlacements() async {
    final db = await dbProvider.database;
    await db.delete('placement');
  }
}

// -PLACEMENT MODEL
class Placement {
  int? id;
  String muscleName;
  String? action;
  String? muscleInsertions;
  String? locationDescription;
  String? behavioralTest;
  late int bodyRegionId;

  Placement({
    this.id,
    required this.muscleName,
    this.action,
    this.muscleInsertions,
    this.locationDescription,
    this.behavioralTest,
    this.bodyRegionId = 0,
  });

  factory Placement.fromMap(Map<String, dynamic> json) => Placement(
        id: json["placementId"],
        muscleName: json["placementMuscleName"],
        action: json["placementAction"],
        muscleInsertions: json["placementMuscleInsertions"],
        locationDescription: json["placementLocationDescription"],
        behavioralTest: json["placementBehavioralTest"],
        bodyRegionId: json["FK_Placement_bodyRegionId"],
      );

  Map<String, dynamic> toJson() => {
        "placementMuscleName": muscleName,
        "placementAction": action,
        "placementMuscleInsertions": muscleInsertions,
        "placementLocationDescription": locationDescription,
        "placementBehavioralTest": behavioralTest,
        "FK_Placement_bodyRegionId": bodyRegionId,
      };
}
