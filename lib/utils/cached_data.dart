import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/models/user.dart';

class CachedData {
  static Future<(String?, UserRole?, String?)> getCachedNameRoleAndArea() async {
    final prefs = await SharedPreferences.getInstance();
    String? name;
    String? role;
    String? area;
    try {
      name = prefs.getString('name');
      role = prefs.getString('role');
      area = prefs.getString('area');
    } catch (error) {
      print(error);
    }
    if (FirebaseAuth.instance.currentUser == null) {
      return (null, null, null);
    }

    var userDoc = (await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser!.uid).get());
    if (!userDoc.exists) {
      return (null, null, null);
    }
    if (name == null) {
      name = userDoc.get('name');
      await prefs.setString('name', name!);
    }
    if (role == null) {
      role = userDoc.get('role');
      await prefs.setString('role', role!);
    }
    if (area == null) {
      try {
        area = userDoc.get('area');
        await prefs.setString('area', area!);
      } catch (error) {
        print("area is not listed");
      }
    }

    return (name, UserRole.values.firstWhere((element) => element.name == role), area);

  }
}