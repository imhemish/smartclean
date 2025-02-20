import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  attendant, supervisor, coordinator 
}

var _firestore = FirebaseFirestore.instance;
var users = _firestore.collection("users");

class User {
  final String name;
  final String googleAuthID;
  final String? area;
  final UserRole role;

  User({
    required this.name,
    required this.googleAuthID,
    required this.area,
    required this.role
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'googleAuthID': googleAuthID,
      'area': area,
      'role': role.name
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'],
      googleAuthID: map['googleAuthID'],
      area: map['area'],
      role: UserRole.values.firstWhere((e) => e.name == map['role'])
    );
  }

  static Future<void> addUser(User user) async {
    try {
      await _firestore.collection('users').add(user.toMap());
      print('User saved to Firestore');
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  static Future<User?> getUser(String documentId) async {
    try {
      DocumentSnapshot doc = await users.doc(documentId).get();
      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }
}