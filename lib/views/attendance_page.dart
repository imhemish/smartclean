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
      'date':
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
    });

    Fluttertoast.showToast(
      msg: isPresent ? "Marked Present" : "Marked Absent",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: isPresent ? Colors.green[600] : Colors.red[600],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _loadAttendanceStatus() async {
    final startOfDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
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
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.orange[800],
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              rowHeight: 48,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: Colors.orange[700]),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: Colors.orange[700]),
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
                weekendTextStyle: TextStyle(color: Colors.orange[900]),
                outsideTextStyle: TextStyle(color: Colors.orange[200]),
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
                hintStyle: TextStyle(color: Colors.orange[300]),
                prefixIcon: Icon(Icons.search, color: Colors.orange[600]),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.orange[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.orange[600]!),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getAttendants(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange[600],
                    ),
                  );
                }

                final users = snapshot.data!.docs.where((user) {
                  final String name = user['name'].toLowerCase();
                  final String uid = user['uid'].toLowerCase();
                  return name.contains(_searchQuery) ||
                      uid.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search,
                            size: 48, color: Colors.orange[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No attendants found',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final String uid = user['uid'];
                    final String name = user['name'];
                    final bool isPresent = attendanceStatus[uid] ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isPresent
                              ? Colors.green[100]
                              : Colors.orange[100],
                          child: Icon(
                            Icons.person,
                            color: isPresent
                                ? Colors.green[600]
                                : Colors.orange[600],
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'UID: $uid',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Switch(
                          value: isPresent,
                          activeColor: Colors.green[600],
                          activeTrackColor: Colors.green[100],
                          inactiveThumbColor: Colors.orange[600],
                          inactiveTrackColor: Colors.orange[100],
                          onChanged: (value) =>
                              _markAttendance(uid, name, value),
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
