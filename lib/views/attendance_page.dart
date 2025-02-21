import 'package:flutter/material.dart';
import 'package:soochi/views/profile_page_admin.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'checklist_page_admin.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  Map<String, bool> attendanceStatus = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
  }

  Stream<QuerySnapshot> _getAttendants() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Attendant')
        .snapshots();
  }

  Future<void> _markAttendance(String uid, String name, bool isPresent) async {
    setState(() {
      attendanceStatus[uid] = isPresent;
    });

    await FirebaseFirestore.instance.collection('attendance').add({
      'userID': uid,
      'name': name,
      'datentime': Timestamp.now(),
      'present': isPresent,
      'date': DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
    });

    Fluttertoast.showToast(
      msg: isPresent ? "Marked Present" : "Marked Absent",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: isPresent ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _loadAttendanceStatus() async {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    setState(() {
      attendanceStatus.clear();
      for (var doc in attendanceSnapshot.docs) {
        attendanceStatus[doc['userID']] = doc['present'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Attendance Record',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white, letterSpacing: 2),
        ),
        backgroundColor: Colors.orange[700],
        elevation: 5,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              rowHeight: 45,
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDate = focusedDay;
                });
                _loadAttendanceStatus();
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.orange[700],
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange[300],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search by Name or UID",
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Colors.orange[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getAttendants(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((user) {
                  final String name = user['name'].toLowerCase();
                  final String uid = user['uid'].toLowerCase();
                  return name.contains(_searchQuery) || uid.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No attendants found.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final String uid = user['uid'];
                    final String name = user['name'];
                    final bool isPresent = attendanceStatus[uid] ?? false;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        subtitle: Text('UID: $uid', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                        trailing: Switch(
                          value: isPresent,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.orange,
                          onChanged: (value) => _markAttendance(uid, name, value),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
