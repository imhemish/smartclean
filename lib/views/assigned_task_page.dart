import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soochi/utils/cached_data.dart';
import 'package:intl/intl.dart';

class AssignedTasksPage extends StatefulWidget {
  final DateTime selectedDate;
  
  const AssignedTasksPage({
    super.key,
    required this.selectedDate,
  });

  @override
  State<AssignedTasksPage> createState() => _AssignedTasksPageState();
}

class _AssignedTasksPageState extends State<AssignedTasksPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? currentUserID = FirebaseAuth.instance.currentUser?.uid;

  String? area;
  bool loading = true;
  String selectedTimeSlot = '';
  Timer? _stateTimer;
  
  // Cache for checklist data
  List<Map<String, dynamic>> _checklistsCache = [];
  bool _dataFetched = false;
  
  // Define time slots
  final List<String> timeSlots = [
    '9-10 AM', 
    '10-11 AM', 
    '11 AM-12 PM', 
    '12-1 PM', 
    '1-2 PM', 
    '2-3 PM', 
    '3-4 PM'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupCurrentTimeSlot();
    _setupStateTimer();
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      loading = true;
    });
    
    // First get the area
    await _setupArea();
    
    // Then fetch checklists only after we have the area
    if (area != null) {
      await _fetchChecklists();
    }
    
    setState(() {
      loading = false;
    });
  }

  Future<void> _setupArea() async {
    // Try to get area from cache first
    var cachedArea = (await CachedData.getCachedNameRoleAndArea()).$3;
    
    if (cachedArea == null) {
      // Only fetch from Firestore if not in cache
      final snapshot = await _firestore.collection("users")
          .where("googleAuthID", isEqualTo: currentUserID)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final user = snapshot.docs.first;
        try {
          cachedArea = user.get("area");
          if (cachedArea != null) {
            CachedData.setArea(cachedArea);
          }
        } catch (e) {
          print("area does not exist for supervisor");
        }
      }
    }

    setState(() {
      area = cachedArea;
    });
  }

  Future<void> _fetchChecklists() async {
    if (area == null) return; // Don't fetch if area is not set
    
    try {
      final snapshot = await _firestore
          .collection('checklists')
          .where('area', isEqualTo: area)
          .get();
      
      // Create a new list for cached checklists
      List<Map<String, dynamic>> newCache = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      setState(() {
        _checklistsCache = newCache;
        _dataFetched = true;
      });
      
      print("Fetched ${_checklistsCache.length} checklists for area: $area");
    } catch (error) {
      print("Error fetching checklists: $error");
      setState(() {
        _dataFetched = false;
      });
    }
  }

  void _setupStateTimer() {
    // Cancel existing timer if any
    _stateTimer?.cancel();
    
    // Calculate time until next hour
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final timeUntilNextHour = nextHour.difference(now);
    
    // Set up timer for next hour change
    _stateTimer = Timer(timeUntilNextHour, () {
      // Refresh the UI when the hour changes
      setState(() {
        _setupCurrentTimeSlot();
      });
      
      // Set up the next timer
      _setupStateTimer();
    });
  }

  void _setupCurrentTimeSlot() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Set the current time slot based on the current hour
    if (hour >= 9 && hour < 16) {
      String slot;
      if (hour == 9) slot = '9-10 AM';
      else if (hour == 10) slot = '10-11 AM';
      else if (hour == 11) slot = '11 AM-12 PM';
      else if (hour == 12) slot = '12-1 PM';
      else if (hour == 13) slot = '1-2 PM';
      else if (hour == 14) slot = '2-3 PM';
      else slot = '3-4 PM';
      
      setState(() {
        selectedTimeSlot = slot;
      });
    } else if (selectedTimeSlot.isEmpty) {
      // Default to first time slot if current time is outside working hours
      setState(() {
        selectedTimeSlot = timeSlots[0];
      });
    }
  }

  // Check if a timeslot is currently active
  bool _isCurrentTimeSlot(String timeSlot) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    
    if (todayDate != selectedDate) return false;
    
    final hour = now.hour;
    
    switch (timeSlot) {
      case '9-10 AM': return hour == 9;
      case '10-11 AM': return hour == 10;
      case '11 AM-12 PM': return hour == 11;
      case '12-1 PM': return hour == 12;
      case '1-2 PM': return hour == 13;
      case '2-3 PM': return hour == 14;
      case '3-4 PM': return hour == 15;
      default: return false;
    }
  }
  
  // Convert timeslot to hour range for database queries
  int _getStartHourFromTimeSlot(String timeSlot) {
    switch (timeSlot) {
      case '9-10 AM': return 9;
      case '10-11 AM': return 10;
      case '11 AM-12 PM': return 11;
      case '12-1 PM': return 12;
      case '1-2 PM': return 13;
      case '2-3 PM': return 14;
      case '3-4 PM': return 15;
      default: return 9; // Default to 9 AM
    }
  }

  // Toggle the state of a checklist
  Future<void> _toggleState(String checklistId, String currentState) async {
    // Cycle through states: "notClean" -> "inProgress" -> "clean" -> "notClean"
    String newState;
    switch (currentState) {
      case "notClean":
        newState = "inProgress";
        break;
      case "inProgress":
        newState = "clean";
        break;
      default:
        newState = "notClean";
        break;
    }
    
    // Create timestamp for the current time
    final timestamp = Timestamp.now();
    
    try {
      // Update local cache first for immediate UI response
      int index = _checklistsCache.indexWhere((item) => item['id'] == checklistId);
      if (index != -1) {
        if (!_checklistsCache[index].containsKey('states')) {
          _checklistsCache[index]['states'] = [];
        }
        
        (_checklistsCache[index]['states'] as List).add({
          'timestamp': timestamp,
          'state': newState,
        });
        
        // Update UI
        setState(() {});
      }
      
      // Then update Firestore
      await _firestore.collection('checklists').doc(checklistId).update({
        'states': FieldValue.arrayUnion([
          {
            'timestamp': timestamp,
            'state': newState,
          }
        ])
      });
      
      print("State updated successfully to $newState");
    } catch (error) {
      print("Failed to update state: $error");
      
      // Roll back the local change if Firestore update fails
      _fetchChecklists();
    }
  }
  
  // Get the current state of a checklist based on the selected date and timeslot
  String _getCurrentState(Map<String, dynamic> checklist) {
    if (!checklist.containsKey('states') || !(checklist['states'] is List)) {
      return "notClean";  // Default to "notClean" instead of "clean"
    }
    
    List states = checklist['states'];
    if (states.isEmpty) {
      return "notClean";
    }
    
    // Get the hour range for the selected time slot
    int startHour = _getStartHourFromTimeSlot(selectedTimeSlot);
    DateTime slotStartTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      startHour
    );
    DateTime slotEndTime = slotStartTime.add(Duration(hours: 1));
    
    // Find the most recent state update within the selected time slot
    dynamic latestState;
    Timestamp latestTimestamp = Timestamp.fromDate(DateTime(1970));
    
    for (var stateEntry in states) {
      if (stateEntry['timestamp'] is Timestamp) {
        Timestamp stateTimestamp = stateEntry['timestamp'];
        DateTime stateDateTime = stateTimestamp.toDate();
        
        // Check if the state update is within the selected time slot
        if (stateDateTime.isAfter(slotStartTime) && 
            stateDateTime.isBefore(slotEndTime) && 
            stateTimestamp.compareTo(latestTimestamp) > 0) {
          latestTimestamp = stateTimestamp;
          latestState = stateEntry;
        }
      }
    }
    
    return latestState != null ? latestState['state'] : "notClean";
  }
  
  // Check if a state can be toggled based on date and time
  bool _canToggleState() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    
    // Can only toggle if it's today and the current timeslot
    return todayDate == selectedDate && _isCurrentTimeSlot(selectedTimeSlot);
  }
  
  // Get color for state indicator
  Color _getStateColor(String state) {
    switch (state) {
      case "clean": return Colors.green;
      case "inProgress": return Colors.orange;
      case "notClean": return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildChecklistList() {
    if (_checklistsCache.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(
              'No checklists assigned yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checklistsCache.length,
      itemBuilder: (context, index) {
        var checklistData = _checklistsCache[index];
        String checklistId = checklistData['id'];
        String currentState = _getCurrentState(checklistData);
        bool canToggle = _canToggleState();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.shade900, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checklistData['name'] ?? 'Unnamed Checklist',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Area: ${checklistData['area'] ?? 'Unassigned'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade600,
                            ),
                          ),
                          if (checklistData['latitude'] != null && checklistData['longitude'] != null)
                          Text(
                            'Location: ${checklistData['latitude']}, ${checklistData['longitude']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: canToggle ? () {
                        _toggleState(checklistId, currentState);
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: canToggle 
                              ? _getStateColor(currentState)
                              : _getStateColor(currentState).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: canToggle 
                                ? _getStateColor(currentState).withOpacity(0.7)
                                : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          currentState == 'notClean' ? "Not Clean" : currentState == "inProgress" ? "In Progress" : "Clean",
                          style: TextStyle(
                            color: canToggle ? Colors.white : Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String dateFormatted = DateFormat('MMM d, yyyy').format(widget.selectedDate);
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Tasks Assigned',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            Text(
              dateFormatted,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: timeSlots.map((slot) {
                  bool isSelected = selectedTimeSlot == slot;
                  bool isCurrentSlot = _isCurrentTimeSlot(slot);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTimeSlot = slot;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.orange.shade700
                            : Colors.orange.shade100,
                        foregroundColor: isSelected
                            ? Colors.white
                            : Colors.orange.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (loading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                ),
              ),
            )
          else if (area == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.orange.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No area assigned',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchChecklists,
                color: Colors.orange.shade700,
                child: _buildChecklistList(),
              ),
            ),
        ],
      ),
    );
  }
}

// Extension to check if a DateTime is today
extension DateTimeExtension on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}