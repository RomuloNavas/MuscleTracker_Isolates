
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/database.dart';

class SessionOperations {
  SessionOperations? sessionOperations;

  final dbProvider = DatabaseRepository.instance;

  Future<int> createSession(Session session) async {
    final db = await dbProvider.database;
    int idOfTheLastInsertedRow = await db.insert('session', session.toJson());
    return idOfTheLastInsertedRow;
  }

  Future<Session?> getSessionById(int sessionId) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db
        .query('session', where: 'sessionId = ?', whereArgs: [sessionId]);

    List<Session> session =
        allRows.map((session) => Session.fromJson(session)).toList();
    if (session.isNotEmpty) {
      return session.first;
    } else {
      return null;
    }
  }

  deleteSession(Session session) async {
    final db = await dbProvider.database;
    await db.delete('session', where: 'sessionId = ?', whereArgs: [session.id]);
  }

  Future<List<Session>> getAllSessions() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('session');
    List<Session> categories =
        allRows.map((session) => Session.fromJson(session)).toList();
    return categories;
  }

  Future<List<Session>> getAllSessionsByClientID(Client client) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM session 
    WHERE session.FK_Session_clientId = ${client.id}
    ''');
    List<Session> sessions =
        allRows.map((sessionJson) => Session.fromJson(sessionJson)).toList();
    return sessions;
  }

  Future<List<Session>> getAllSessionsByClientIDAndBodyRegionId(
      {required Client client, required int bodyRegionId}) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM session 
    WHERE session.FK_Session_clientId = ${client.id} AND session.FK_Session_bodyRegionId = $bodyRegionId
    ''');
    List<Session> sessions =
        allRows.map((sessionJson) => Session.fromJson(sessionJson)).toList();
    return sessions;
  }
}

class Session {
  int? id;
  late String name;
  String description;
  late String startedAt;
  late String endedAt;
  int? bodyRegionId;
  int? clientId;

  Session({
    this.id,
    required this.name,
    this.description = '',
    required this.startedAt,
    required this.endedAt,
    required this.bodyRegionId,
    required this.clientId,
  });

  factory Session.fromJson(Map<String, dynamic> obj) => Session(
        id: obj['sessionId'],
        name: obj['sessionName'],
        description: obj['sessionDescription'],
        startedAt: obj['sessionStartedAt'],
        endedAt: obj['sessionEndedAt'],
        bodyRegionId: obj['FK_Session_bodyRegionId'],
        clientId: obj['FK_Session_clientId'],
      );

  Map<String, dynamic> toJson() {
    // TODO: Remove sessionId
    var map = <String, dynamic>{
      'sessionId': id,
      'sessionName': name,
      'sessionDescription': description,
      'sessionStartedAt': startedAt,
      'sessionEndedAt': endedAt,
      'FK_Session_bodyRegionId': bodyRegionId,
      'FK_Session_clientId': clientId,
    };

    return map;
  }
}
