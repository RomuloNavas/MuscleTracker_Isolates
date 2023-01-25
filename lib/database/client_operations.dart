import 'dart:convert';
import 'dart:developer';
import 'package:neuro_sdk_isolate_example/database/database.dart';

import 'package:flutter/services.dart';

class ClientOperations {
  ClientOperations? clientOperations;

  final dbProvider = DatabaseRepository.instance;

  createClient(Client client) async {
    try {
      final db = await dbProvider.database;
      db.insert('client', client.toJson());

      log('✅Client added', name: 'client_operations');
    } catch (e) {
      log('❌Error while adding client. $e');
    }
  }

  updateClient(Client client) async {
    try {
      final db = await dbProvider.database;
      db.update('client', client.toJson(),
          where: "ClientId = ?", whereArgs: [client.id]);

      log('✅Client updated', name: 'client_operations');
    } catch (e) {
      log('❌ Error while updating client. $e');
    }
  }

  deleteClient(Client client) async {
    try {
      final db = await dbProvider.database;
      await db.delete('client', where: 'ClientId = ?', whereArgs: [client.id]);

      log('✅✅✅Client DELETED');
    } catch (e) {
      log('❌Error while deleting client. $e', name: 'client_operations');
    }
  }

  Future<List<Client>> getAllClients() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('client');
    List<Client> clients =
        allRows.map((client) => Client.fromJson(client)).toList();
    return clients;
  }

  Future<List<Client>> getLastAddedClients() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM client 
    ORDER BY clientId DESC
    LIMIT 5

    ''');
    List<Client> lastAdded =
        allRows.map((clientJson) => Client.fromJson(clientJson)).toList();
    return lastAdded;
  }

  Future<List<Client>> getAllFavoriteClients() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows =
        await db.query('client', where: "clientIsFavorite = 1");
    // log('RAW' + allRows.toString());
    List<Client> favoriteClients =
        allRows.map((client) => Client.fromJson(client)).toList();
    return favoriteClients;
  }

  Future<Client> getClient(Client client) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows =
        await db.query('client', where: "id = ?", whereArgs: [client.id]);
    List<Client> clients =
        allRows.map((client) => Client.fromJson(client)).toList();
    return clients.first;
  }

  Future<List<Client>> searchClients(String keyword) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db
        .query('client', where: 'clientName LIKE ?', whereArgs: ['%$keyword%']);
    List<Client> clients =
        allRows.map((client) => Client.fromJson(client)).toList();
    return clients;
  }

  Future<void> initTestClients() async {
    try {
      final db = await dbProvider.database;
      //Check if databases are empty to initialize them:
      List<Map<String, dynamic>> allRows = await db.query('client', limit: 2);
      if (allRows.isEmpty) {
        final String jsonString =
            await rootBundle.loadString('lib/database/test_clients.json');
        final jsonMap = jsonDecode(jsonString);

        for (var i = 0; i < jsonMap.length; i++) {
          await db.insert("client", jsonMap[i]);
        }
        log('TestClients initialized', name: 'client_operations');
      }
    } catch (e) {
      log('ERROR $e', name: 'client_operations');
    }
  }
}

// - CLIENT MODEL
class Client {
  int? id;
  late String name;
  late String surname;
  late String birthday;
  late String registrationDate;
  late String patronymic;
  String? mobile;
  String? email;
  double? height;
  double? weight;
  late int isFavorite;
  String? lastVisit;

  Client({
    this.id,
    required this.name,
    required this.surname,
    required this.birthday,
    required this.registrationDate,
    this.patronymic = '',
    this.mobile,
    this.email,
    this.height,
    this.weight,
    this.isFavorite = 0,
    this.lastVisit,
  });

  Client.fromJson(Map<String, dynamic> json) {
    id = json['clientId'];
    name = json['clientName'];
    surname = json['clientSurname'];
    birthday = json['clientBirthday'];
    patronymic = json['clientPatronymic'];
    mobile = json['clientMobile'];
    email = json['clientEmail'];
    height = json['clientHeight'];
    weight = json['clientWeight'];
    isFavorite = json['clientIsFavorite'];
    // DateTime as Iso8601String
    registrationDate = json['clientRegisteredDate'];
    lastVisit = json['clientLastVisitDate'];
  }

  Map<String, dynamic> toJson() => {
        "clientName": name,
        "clientSurname": surname,
        "clientBirthday": birthday,
        "clientPatronymic": patronymic,
        "clientMobile": mobile,
        "clientEmail": email,
        "clientHeight": height,
        "clientWeight": weight,
        "clientIsFavorite": isFavorite,
        "clientRegisteredDate": registrationDate,
        "clientLastVisitDate": lastVisit,
      };
}
