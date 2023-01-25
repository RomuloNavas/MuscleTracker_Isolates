import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:neuro_sdk_isolate_example/database/database.dart';

class BodyRegionOperations {
  BodyRegionOperations? bodyRegionOperations;

  final dbProvider = DatabaseRepository.instance;

  createBodyRegion(BodyRegion bodyRegion) async {
    final db = await dbProvider.database;
    db.insert('bodyRegion', bodyRegion.toJson());
  }

  Future<BodyRegion?> getBodyRegionById(int bodyRegionId) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('bodyRegion',
        where: 'bodyRegionId = ?', whereArgs: [bodyRegionId]);

    List<BodyRegion> bodyRegion =
        allRows.map((bodyRegion) => BodyRegion.fromJson(bodyRegion)).toList();
    if (bodyRegion.isNotEmpty) {
      return bodyRegion.first;
    } else {
      return null;
    }
  }

  Future<List<BodyRegion>> getAllBodyRegions() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('bodyRegion');
    List<BodyRegion> bodyRegions = allRows
        .map((bodyRegionJson) => BodyRegion.fromJson(bodyRegionJson))
        .toList();
    return bodyRegions;
  }

  initBodyRegions() async {
    try {
      final db = await dbProvider.database;
      //Check if databases are empty to initialize them:
      var allRows = await db.query("bodyRegion", limit: 2);
      if (allRows.isEmpty) {
        List<BodyRegion> bodyRegions = [
          BodyRegion(
              id: Constants.back,
              name: idToBodyRegionString(bodyRegionId: Constants.back)),
          BodyRegion(
              id: Constants.upperLimb,
              name: idToBodyRegionString(bodyRegionId: Constants.upperLimb)),
          BodyRegion(
              id: Constants.headAndNeck,
              name: idToBodyRegionString(bodyRegionId: Constants.headAndNeck)),
          BodyRegion(
              id: Constants.thorax,
              name: idToBodyRegionString(bodyRegionId: Constants.thorax)),
          BodyRegion(
              id: Constants.abdomen,
              name: idToBodyRegionString(bodyRegionId: Constants.abdomen)),
          BodyRegion(
              id: Constants.pelvisAndPerineum,
              name: idToBodyRegionString(
                  bodyRegionId: Constants.pelvisAndPerineum)),
          BodyRegion(
              id: Constants.lowerLimb,
              name: idToBodyRegionString(bodyRegionId: Constants.lowerLimb)),
          BodyRegion(
              id: Constants.allBodyRegions,
              name:
                  idToBodyRegionString(bodyRegionId: Constants.allBodyRegions)),
        ];

        for (var i = 0; i < bodyRegions.length; i++) {
          await db.insert("bodyRegion", bodyRegions[i].toJson());
        }
        log('✅ BodyRegion initialized', name: 'DBSensorPlacements');
      }
    } catch (e) {
      log('ERROR $e', name: 'DBSensorPlacements');
    }
  }
}

// - ENUM BODY REGION
enum BodyRegionEnum<T> {
  back,
  upperLimb,
  headAndNeck,
  thorax,
  abdomen,
  pelvisAndPerineum,
  lowerLimb,
  all
}

class Constants {
  static const allBodyRegions = 0x00;
  static const back = 0x01;
  static const upperLimb = 0x02;
  static const headAndNeck = 0x03;
  static const thorax = 0x04;
  static const abdomen = 0x05;
  static const pelvisAndPerineum = 0x06;
  static const lowerLimb = 0x07;
}

int bodyRegionToId(BodyRegionEnum bodyRegion) {
  var bodyRegionId = Constants.allBodyRegions;
  switch (bodyRegion) {
    case BodyRegionEnum.headAndNeck:
      bodyRegionId = Constants.headAndNeck;
      break;
    case BodyRegionEnum.back:
      bodyRegionId = Constants.back;
      break;
    case BodyRegionEnum.upperLimb:
      bodyRegionId = Constants.upperLimb;
      break;
    case BodyRegionEnum.thorax:
      bodyRegionId = Constants.thorax;
      break;
    case BodyRegionEnum.abdomen:
      bodyRegionId = Constants.abdomen;
      break;
    case BodyRegionEnum.pelvisAndPerineum:
      bodyRegionId = Constants.pelvisAndPerineum;
      break;
    case BodyRegionEnum.lowerLimb:
      bodyRegionId = Constants.lowerLimb;
      break;
    case BodyRegionEnum.all:
      bodyRegionId = Constants.allBodyRegions;
      break;
  }
  return bodyRegionId;
}

// Assets images has and these strings must be the same.
String idToBodyRegionString({int? bodyRegionId}) {
  var bodyRegion = 'Unsigned';
  switch (bodyRegionId) {
    case Constants.back:
      bodyRegion = 'Back';
      break;
    case Constants.upperLimb:
      bodyRegion = 'Upper Limb';
      break;
    case Constants.headAndNeck:
      bodyRegion = 'Head and Neck';
      break;
    case Constants.thorax:
      bodyRegion = 'Thorax';
      break;
    case Constants.abdomen:
      bodyRegion = 'Abdomen';
      break;
    case Constants.pelvisAndPerineum:
      bodyRegion = 'Pelvis and Perineum';
      break;
    case Constants.lowerLimb:
      bodyRegion = 'Lower Limb';
      break;
    case Constants.allBodyRegions:
      bodyRegion = 'All';
      break;
  }
  return bodyRegion;
}

// - BODY REGION MODEL
class BodyRegion {
  late int id;
  late String name;

  BodyRegion({
    required this.id,
    required this.name,
  });

  BodyRegion.fromJson(dynamic obj) {
    id = obj['bodyRegionId'];
    name = obj['bodyRegionName'];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{
      'bodyRegionId': id,
      'bodyRegionName': name,
    };

    return map;
  }
}
