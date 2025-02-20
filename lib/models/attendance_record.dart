import 'package:cloud_firestore/cloud_firestore.dart';

var _firestore = FirebaseFirestore.instance;
var attendanceRecords = _firestore.collection("attendanceRecords");

class AttendanceRecord {
  final String userID;
  DateTime datentime;
  bool present;
  final String area;

  AttendanceRecord({
    required this.userID,
    required this.datentime,
    required this.present,
    required this.area,
  });

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'datentime': datentime.toIso8601String(),
      'present': present,
      'area': area,
    };
  }

  static AttendanceRecord fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      userID: map['userID'],
      datentime: DateTime.parse(map['datentime']),
      present: map['present'],
      area: map['area'],
    );
  }

  static Future<void> addAttendanceRecord(AttendanceRecord record) async {
    try {
      await attendanceRecords.add(record.toMap());
      print('AttendanceRecord saved to Firestore');
    } catch (e) {
      print('Error saving AttendanceRecord: $e');
    }
  }

  static Future<void> toggleAttendance(String documentId) async {
    try {
      DocumentSnapshot doc = await attendanceRecords.doc(documentId).get();
      if (doc.exists) {
        AttendanceRecord record = AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>);
        record.present = !record.present;
        record.datentime = DateTime.now();
        await attendanceRecords.doc(documentId).update(record.toMap());
        print('AttendanceRecord present property toggled in Firestore');
      }
    } catch (e) {
      print('Error toggling AttendanceRecord: $e');
    }
  }
}