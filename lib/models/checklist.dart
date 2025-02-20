import 'package:cloud_firestore/cloud_firestore.dart';

var _firestore = FirebaseFirestore.instance;
var checklists = _firestore.collection("checklists");
var checks = _firestore.collection("checks");

class Check {
  final String userID;
  final String userName;
  final String itemID;
  final DateTime datentime;

  Check({
    required this.userID,
    required this.userName,
    required this.itemID,
    required this.datentime,
  });

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'userName': userName,
      'itemID': itemID,
      'datentime': Timestamp.fromDate(datentime),
    };
  }

  static Check fromMap(Map<String, dynamic> map) {
    return Check(
      userID: map['userID'],
      userName: map['userName'],
      itemID: map['itemID'],
      datentime: (map['datentime'] as Timestamp).toDate(),
    );
  }

  static Future<void> addCheck(String userID, String itemID) async {
    try {
      await checks.add({
        'userID': userID,
        'itemID': itemID,
        'datentime': FieldValue.serverTimestamp(),
      });
      print("Check added successfully.");
    } catch (e) {
      print("Error adding check: $e");
    }
  }

  static Future<void> deleteCheck(String userID, String itemID) async {
    try {
      await checks
          .where('userID', isEqualTo: userID)
          .where('itemID', isEqualTo: itemID)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.delete();
        }
      });
      print("Check deleted successfully.");
    } catch (e) {
      print("Error deleting check: $e");
    }
  }
}

class ChecklistItem {
  final String itemID;
  final String task;

  ChecklistItem({
    required this.itemID,
    required this.task,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemID': itemID,
      'task': task,
    };
  }

  static ChecklistItem fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      itemID: map['itemID'],
      task: map['task'],
    );
  }
}

class Checklist {
  final String name;
  final String area;
  final double latitude;
  final double longitude;
  final List<ChecklistItem> items;
  final List<String> assignedToUserIDs;
  final Duration? period; // Moved period here

  Checklist({
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.items,
    required this.assignedToUserIDs,
    required this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'items': items.map((item) => item.toMap()).toList(),
      'assignedToUserIDs': assignedToUserIDs,
      'period': period?.inMilliseconds, // Store period in milliseconds
    };
  }

  static Checklist fromMap(Map<String, dynamic> map) {
    return Checklist(
      name: map['name'],
      area: map['area'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      items: (map['items'] as List).map((item) => ChecklistItem.fromMap(item)).toList(),
      assignedToUserIDs: List<String>.from(map['assignedToUserIDs']),
      period: map['period'] != null ? Duration(milliseconds: map['period']) : null,
    );
  }

  static Future<void> addChecklist(Checklist checklist) async {
    try {
      await checklists.add(checklist.toMap());
      print('Checklist saved to Firestore');
    } catch (e) {
      print('Error saving checklist: $e');
    }
  }

  static Future<Checklist?> getChecklist(String documentId) async {
    try {
      DocumentSnapshot doc = await checklists.doc(documentId).get();
      if (doc.exists) {
        return Checklist.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting checklist: $e');
    }
    return null;
  }

  static Future<void> deleteChecklist(String documentId) async {
    try {
      await checklists.doc(documentId).delete();
      print('Checklist deleted from Firestore');
    } catch (e) {
      print('Error deleting checklist: $e');
    }
  }

  static Future<void> deleteChecklistItem(String checklistId, String itemId) async {
    try {
      DocumentSnapshot doc = await checklists.doc(checklistId).get();
      if (doc.exists) {
        Checklist checklist = Checklist.fromMap(doc.data() as Map<String, dynamic>);
        checklist.items.removeWhere((item) => item.itemID == itemId);
        await checklists.doc(checklistId).update(checklist.toMap());
        print('Checklist item deleted from Firestore');
      }
    } catch (e) {
      print('Error deleting checklist item: $e');
    }
  }

  static Future<void> addChecklistItem(String checklistId, ChecklistItem item) async {
    try {
      DocumentSnapshot doc = await checklists.doc(checklistId).get();
      if (doc.exists) {
        Checklist checklist = Checklist.fromMap(doc.data() as Map<String, dynamic>);
        checklist.items.add(item);
        await checklists.doc(checklistId).update(checklist.toMap());
        print('Checklist item added to Firestore');
      }
    } catch (e) {
      print('Error adding checklist item: $e');
    }
  }
}