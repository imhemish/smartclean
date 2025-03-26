import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChecklistRecordsPage extends StatefulWidget {
  const ChecklistRecordsPage({super.key});

  @override
  State<ChecklistRecordsPage> createState() => _ChecklistRecordsPageState();
}

class _ChecklistRecordsPageState extends State<ChecklistRecordsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Timeslots for matrix rows
  final List<String> timeSlots = [
    '9-10 AM', 
    '10-11 AM', 
    '11 AM-12 PM', 
    '12-1 PM', 
    '1-2 PM', 
    '2-3 PM', 
    '3-4 PM'
  ];

  DateTime? _selectedDate = DateTime.now();
  String? _selectedArea;
  List<String> _availableAreas = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableAreas();
  }

  // Fetch unique areas from Firestore
  void _fetchAvailableAreas() async {
    final areasSnapshot = await _firestore.collection('areas').get();
    
    final areas = areasSnapshot.docs
      .map((doc) => doc['name'] as String?)
      .where((area) => area != null)
      .toList();
    
    setState(() {
      _availableAreas = areas.cast<String>();
      _selectedArea = _availableAreas.isNotEmpty ? _availableAreas.first : null;
    });
  }

  // Get state color
  Color _getStateColor(String state) {
    switch (state) {
      case "clean": return Colors.green;
      case "inProgress": return Colors.orange;
      case "notClean": return Colors.grey;
      default: return Colors.grey;
    }
  }

  // Get the most recent state for a specific time slot
  String _getMostRecentState(List<dynamic> states, DateTime selectedDate, String timeSlot) {
    if (states.isEmpty) return "notClean";

    // Get time range for the selected time slot
    final timeRange = _getTimeSlotHours(timeSlot);
    
    // Filter states within the selected date and time slot
    final filteredStates = states.where((state) {
      if (state['timestamp'] is! Timestamp) return false;
      
      final stateTime = (state['timestamp'] as Timestamp).toDate();
      
      // Check if the state is on the selected date and within the time slot
      return stateTime.year == selectedDate.year &&
             stateTime.month == selectedDate.month &&
             stateTime.day == selectedDate.day &&
             stateTime.hour >= timeRange['start']! &&
             stateTime.hour < timeRange['end']!;
    }).toList();

    // If no states found, return default
    if (filteredStates.isEmpty) return "notClean";

    // Sort states by timestamp and get the most recent
    filteredStates.sort((a, b) => 
      (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp)
    );

    return filteredStates.first['state'] ?? "notClean";
  }

  // Get start and end time for the selected time slot
  Map<String, int> _getTimeSlotHours(String timeSlot) {
    switch (timeSlot) {
      case '9-10 AM': return {'start': 9, 'end': 10};
      case '10-11 AM': return {'start': 10, 'end': 11};
      case '11 AM-12 PM': return {'start': 11, 'end': 12};
      case '12-1 PM': return {'start': 12, 'end': 13};
      case '1-2 PM': return {'start': 13, 'end': 14};
      case '2-3 PM': return {'start': 14, 'end': 15};
      case '3-4 PM': return {'start': 15, 'end': 16};
      default: return {'start': 0, 'end': 24};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checklist Records',
        ),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date and Area Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Date Picker
                ElevatedButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade700,
                    ),
                    child: Text(
                      _selectedDate == null 
                        ? 'Select Date' 
                        : DateFormat('MMM d, yyyy').format(_selectedDate!),
                    ),
                  ),
                
                const SizedBox(width: 4),
                
                // Area Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    value: _selectedArea,
                    hint: const Text('Select Area'),
                    items: _availableAreas.map((area) {
                      return DropdownMenuItem(
                        value: area,
                        child: Text(area),
                      );
                    }).toList(),
                    
                    onChanged: (value) {
                      setState(() {
                        _selectedArea = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Matrix View
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('checklists')
                .where('area', isEqualTo: _selectedArea)
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No records found',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 18,
                      ),
                    ),
                  );
                }

                // Get all checklist names
                final checklistDocs = snapshot.data!.docs;
                final checklistNames = checklistDocs.map((doc) => 
                  (doc.data() as Map<String, dynamic>)['name'] as String
                ).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.orange.shade100
                    ),
                    columns: [
                      const DataColumn(label: Text('Time Slot', style: TextStyle(fontWeight: FontWeight.bold))),
                      ...checklistNames.map((name) => 
                        DataColumn(label: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)))
                      ),
                    ],
                    rows: timeSlots.map((timeSlot) {
                      return DataRow(cells: [
                        DataCell(Text(timeSlot)),
                        ...checklistDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final selectedDate = _selectedDate ?? DateTime.now();
                          
                          // Get the most recent state for this checklist and time slot
                          final state = _getMostRecentState(
                            data['states'] ?? [], 
                            selectedDate, 
                            timeSlot
                          );

                          return DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStateColor(state).withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                state == 'inProgress' ? 'In Progress' : state == 'clean' ? 'Clean' : 'Not Clean',
                                style: TextStyle(
                                  color: _getStateColor(state),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}