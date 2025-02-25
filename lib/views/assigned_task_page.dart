import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AssignedTasksPage extends StatefulWidget {
  const AssignedTasksPage({super.key});

  @override
  State<AssignedTasksPage> createState() => _AssignedTasksPageState();
}

class _AssignedTasksPageState extends State<AssignedTasksPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? currentUserID = FirebaseAuth.instance.currentUser?.uid;
  String userArea = '';

  @override
  void initState() {
    super.initState();
    _loadUserArea();
    print(currentUserID);
  }

  Future<void> _loadUserArea() async {
    if (currentUserID != null) {
      final userDoc = await _firestore.collection('users').doc(currentUserID).get();
      if (userDoc.exists && mounted) {
        setState(() {
          userArea = userDoc.data()?['area'] ?? '';
        });
      }
    }
  }

  Future<void> _toggleTaskStatus(String itemID, bool currentStatus, String checklistId) async {
    if (currentUserID == null) return;

    print('Toggling Task - itemID: $itemID, checklistId: $checklistId, currentStatus: $currentStatus');

    try {
      if (!currentStatus) {
        await _firestore.collection('checks').add({
          'userID': currentUserID,
          'itemID': itemID,
          'datentime': Timestamp.now(),
          'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown User',
          'checklistId': checklistId,
          'Status': true,
        });

        print('Task Marked as Completed');
      } else {
        var checksQuery = await _firestore
            .collection('checks')
            .where('itemID', isEqualTo: itemID)
            .where('userID', isEqualTo: currentUserID)
            .where('checklistId', isEqualTo: checklistId)
            .get();

        for (var doc in checksQuery.docs) {
          await doc.reference.delete();
          print('Task Unchecked: ${doc.id}');
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error updating task status: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Tasks Assigned',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 2,
          ),
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
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('checklists')
                  .where('assignedToUserIDs', arrayContains: currentUserID)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.orange.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks assigned yet',
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
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var checklist = snapshot.data!.docs[index];
                    var items = (checklist['items'] as List<dynamic>);
                    String checklistId = checklist.id;

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
                                        checklist['name'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Area: ${checklist['area']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${items.length} task',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder(
                            stream: _firestore
                                .collection('checks')
                                .where('userID', isEqualTo: currentUserID)
                                .where('checklistId', isEqualTo: checklistId)
                                .snapshots(),
                            builder: (context, AsyncSnapshot<QuerySnapshot> checksSnapshot) {
                              Map<String, bool> checkedItems = {};
                              if (checksSnapshot.hasData) {
                                checkedItems.clear();
                                for (var doc in checksSnapshot.data!.docs) {
                                  checkedItems[doc['itemID'] as String] = true;
                                }
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (context, itemIndex) {
                                  var item = items[itemIndex];
                                  String itemID = item['itemID'];
                                  bool isCompleted = checkedItems.containsKey(itemID);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      title: Text(
                                        item['task'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isCompleted
                                              ? Colors.black
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                      trailing: Checkbox(
                                        value: isCompleted,
                                        onChanged: (value) => _toggleTaskStatus(
                                          itemID,
                                          isCompleted,
                                          checklistId,
                                        ),
                                        activeColor: Colors.orange.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: Colors.orange.shade800),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
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