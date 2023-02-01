import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neuro_sdk_isolate_example/database/database.dart';

import 'package:flutter/services.dart';

class UserOperations {
  UserOperations? userOperations;

  final dbProvider = DatabaseRepository.instance;

  createUser(User user) async {
    final db = await dbProvider.database;
    try {
      await db.insert('user', user.toJson());
      log('✅User added', name: 'user_operations');
    } catch (e) {
      log('❌Error while adding user. $e');
      Fluttertoast.showToast(
        msg: "Email already exists",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        backgroundColor: Color(0xffB85951),
        fontSize: 16.0,
      );
    }
  }

  updateUser(User user) async {
    final db = await dbProvider.database;
    try {
      db.update('user', user.toJson(),
          where: "user_id = ?", whereArgs: [user.id]);

      log('✅User updated', name: 'user_operations');
    } catch (e) {
      log('❌ Error while updating user. $e');
    }
  }

  deleteUser(User user) async {
    final db = await dbProvider.database;
    try {
      await db.delete('user', where: 'user_id = ?', whereArgs: [user.id]);

      log('✅✅✅User DELETED');
    } catch (e) {
      log('❌Error while deleting user. $e', name: 'user_operations');
    }
  }

  Future<List<User>> getAllUsers() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.query('user');
    List<User> clients = allRows.map((user) => User.fromJson(user)).toList();
    return clients;
  }

  Future<User?> getUser(
      {required String email, required String password}) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> allRows = await db.rawQuery('''
    SELECT * FROM user 
    WHERE user.user_email = $email AND WHERE user.user_password = $password
    ''');
    List<User> users = allRows.map((user) => User.fromJson(user)).toList();
    if (users.isNotEmpty) {
      return users.first;
    } else {
      return null;
    }
  }
}

// - USER MODEL
class User {
  int? id;
  late String name;
  late String email;
  late String password;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['user_id'];
    name = json['user_name'];
    email = json['user_email'];
    password = json['user_password'];
  }

  Map<String, dynamic> toJson() => {
        "user_name": name,
        "user_email": email,
        "user_password": password,
      };
}
