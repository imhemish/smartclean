// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  Supervisor, Coordinator
}

var _firestore = FirebaseFirestore.instance;
var users = _firestore.collection("users");

class User {
  final String name;
  final String googleAuthID;
  final String? area;
  final String uid;
  final UserRole role;

  User({
    required this.name,
    required this.googleAuthID,
    required this.area,
    required this.uid,
    required this.role
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'googleAuthID': googleAuthID,
      'area': area,
      'uid': uid,
      'role': role.name
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'],
      googleAuthID: map['googleAuthID'],
      area: map.containsKey('area') ? map['area'] : null,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      uid: map['uid']
    );
  }

}