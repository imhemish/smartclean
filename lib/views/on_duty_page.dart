import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soochi/views/assigned_task_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:soochi/views/profile_page.dart';

class OnDutyPage extends StatefulWidget {
  final DateTime? testDate; // Optional parameter for testing
  
  const OnDutyPage({
    super.key, 
    this.testDate, // For testing purposes
  });

  @override
  State<OnDutyPage> createState() => _OnDutyPageState();
}

class _OnDutyPageState extends State<OnDutyPage> {
  late DateTime today;
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  bool loading = true;
  Timer? _midnightTimer;
  bool isTestMode = false;

  // Map to store attendance records by date (using date string as key for easy lookup)
  Map<String, bool> attendanceByDate = {};

  @override
  void initState() {
    super.initState();
    // Use test date if provided, otherwise use actual current date
    isTestMode = widget.testDate != null;
    today = widget.testDate ?? DateTime.now();
    _selectedDate = today;
    _focusedDate = today;
    _getOnDutyStatus();
    
    // Only set up midnight timer if not in test mode
    if (!isTestMode) {
      _setupMidnightTimer();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  // Setup timer to trigger state refresh at midnight
  void _setupMidnightTimer() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      setState(() {
        today = DateTime.now();
      });
      _getOnDutyStatus();
      // Setup the next timer
      _setupMidnightTimer();
    });
  }

  // Format date to use as a key for the attendance map
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Format date for display
  String _formatDateForDisplay(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    // Get day name (weekday is 1-7, where 1 is Monday)
    String dayName = days[date.weekday - 1];
    String monthName = months[date.month - 1];
    
    return '$dayName, $monthName ${date.day}, ${date.year}';
  }

  // Check if a specific date is the current day
  bool _isCurrentDay(DateTime date) {
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  // Get on duty status for all dates from Firebase
  Future<void> _getOnDutyStatus() async {
    try {
      setState(() {
        loading = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('userID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      // Clear existing records and populate with new data
      Map<String, bool> newAttendanceByDate = {};
      
      for (var doc in snapshot.docs) {
        Timestamp timestamp = doc['datentime'];
        DateTime dateTime = timestamp.toDate();
        String dateKey = _formatDateKey(dateTime);
        
        // If date already exists in map, it means there's already an attendance record
        newAttendanceByDate[dateKey] = true;
      }

      setState(() {
        attendanceByDate = newAttendanceByDate;
        loading = false;
      });
    } catch (e) {
      print("Error fetching attendance data: $e");
      setState(() {
        loading = false;
      });
    }
  }

  // Mark attendance for current day
  Future<void> _markAttendance() async {
    try {
      String currentDateKey = _formatDateKey(today);
      
      // For test mode, use the test date timestamp instead of now
      final timestamp = isTestMode 
          ? Timestamp.fromDate(today)
          : Timestamp.now();
      
      // Add record to Firebase
      await FirebaseFirestore.instance.collection('attendance').add({
        'userID': FirebaseAuth.instance.currentUser!.uid,
        'datentime': timestamp,
      });

      // Update local state
      setState(() {
        attendanceByDate[currentDateKey] = true;
      });

      Fluttertoast.showToast(
        msg: "Marked On Duty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.green[600],
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      print("Error marking attendance: $e");
      Fluttertoast.showToast(
        msg: "Failed to mark attendance",
        backgroundColor: Colors.red,
      );
    }
  }

  // Unmark attendance for current day
  Future<void> _unmarkAttendance() async {
    try {
      String currentDateKey = _formatDateKey(today);
      
      // Find and delete today's attendance record
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection("attendance")
          .where('userID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('datentime', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('datentime', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
          .orderBy('datentime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("attendance")
            .doc(querySnapshot.docs.first.id)
            .delete();

        // Update local state
        setState(() {
          attendanceByDate[currentDateKey] = false;
        });

        Fluttertoast.showToast(
          msg: "Marked Not On Duty",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.red[600],
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: "No attendance record found for today",
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      print("Error unmarking attendance: $e");
      Fluttertoast.showToast(
        msg: "Failed to update attendance",
        backgroundColor: Colors.red,
      );
    }
  }

  // For testing - changes the test date
  void _changeTestDate(DateTime newDate) {
    if (isTestMode) {
      setState(() {
        today = newDate;
        _selectedDate = today;
        _focusedDate = today;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          
          title: const Text('Cleaning Routine'),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.orange[600],
          ),
        ),
      );
    }

    // Check if selected date has an attendance record
    final selectedDateKey = _formatDateKey(_selectedDate);
    final isOnDuty = attendanceByDate[selectedDateKey] ?? false;
    final isToday = _isCurrentDay(_selectedDate);

    return Scaffold(
      appBar: AppBar(

        title: const Text('Cleaning Routine'),
        actions: isTestMode ? [
            
          // Test mode indicator and controls
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () {
              // Go back one day for testing
              _changeTestDate(today.subtract(const Duration(days: 1)));
            },
            tooltip: 'Previous Day (Test)',
          ),
          IconButton(
            icon: const Icon(Icons.next_plan),
            onPressed: () {
              // Go forward one day for testing
              _changeTestDate(today.add(const Duration(days: 1)));
            },
            tooltip: 'Next Day (Test)',
          ),
        ] : [IconButton(onPressed: () => Navigator.push(context, 
            MaterialPageRoute(builder: (context) => ProfilePage())), icon: Icon(Icons.person,),)]
        ,
      ),
      body: Column(
        children: [
          // Test mode indicator
          if (isTestMode)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'TEST MODE: Current date set to ${_formatDateForDisplay(today)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          
          // Calendar widget
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
              firstDay: DateTime.utc(2025, 03, 01),
              lastDay: DateTime.now().add(const Duration(days: 3650)),
              focusedDay: _focusedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDate = focusedDay;
                });
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
                // Mark dates with attendance
                markerDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final dateKey = _formatDateKey(date);
                  final hasAttendance = attendanceByDate[dateKey] ?? false;
                  
                  if (hasAttendance) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green[600],
                        ),
                      ),
                    );
                  }
                  return null;
                },
                todayBuilder: (context, date, _) {
                  final isSelected = isSameDay(date, _selectedDate);
                  
                  // In test mode, highlight the test date instead of the actual today
                  if (isTestMode && isSameDay(date, today)) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange[700] : Colors.orange[300],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return null; // Use default today marker when not in test mode
                },
              ),
            ),
          ),
          
          // Duty status display and toggle
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    
                    Text(
                      _formatDateForDisplay(_selectedDate),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnDuty ? Colors.green[600] : Colors.red[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOnDuty ? 'Present' : 'Absent',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOnDuty ? Colors.green[600] : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'On Duty',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    Opacity(
                  opacity: isToday ? 1.0 : 0.5,
                  child: Switch(
                    value: isOnDuty,
                    onChanged: isToday 
                        ? (value) {
                            if (value) {
                              _markAttendance();
                            } else {
                              _unmarkAttendance();
                            }
                          }
                        : null,
                    activeColor: Colors.green[600],
                    activeTrackColor: Colors.green[200],
                    inactiveThumbColor: Colors.red[600],
                    inactiveTrackColor: Colors.red[200],
                  ),
                ),
                    
                  ],
                ),
                
                // Toggle switch for current day only
                
                if (!isToday)
                  Text(
                    'Note: Attendance can only be marked for the current day',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                
                if (!isToday) const SizedBox(height: 5),
                SizedBox(height: 5),
                Center(child: ElevatedButton(onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AssignedTasksPage(selectedDate: _selectedDate)));
                }, child: Text("Manage cleaning")))
              ],
            ),
          ),
        ],
      ),
    );
  }
}