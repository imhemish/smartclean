import 'package:cloud_firestore/cloud_firestore.dart';

var _firestore = FirebaseFirestore.instance;
var checklists = _firestore.collection("checklists");

enum StateType {
  clean,
  notClean,
  inProgress,
}

class State {
  final DateTime timestamp;
  final StateType state;

  State({
    required this.timestamp,
    required this.state,
  });
}

class Checklist {
  final String name;
  final String area;
  final double latitude;
  final double longitude;
  final List<State> states;

  Checklist({
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.states,
  });

}