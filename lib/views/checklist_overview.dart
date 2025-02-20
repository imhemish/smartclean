import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChecklistOverviewPage extends StatelessWidget {
  final String area;

  const ChecklistOverviewPage({super.key, required this.area});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checklists for $area')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('checklists')
            .where('area', isEqualTo: area)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No checklists found.'));
          }

          var checklists = snapshot.data!.docs;

          return ListView.builder(
            itemCount: checklists.length,
            itemBuilder: (context, index) {
              var checklist = checklists[index];
              return ListTile(
                title: Text(checklist['name']),
                trailing: Container(
                  height: 20,
                  width: 20,

                  child: Text(checklist['items'].length.toString(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                  decoration: BoxDecoration(
                    
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.red,
                    
                  ),
                  
                
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChecklistDetailPage(checklistId: checklist.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChecklistDetailPage extends StatelessWidget {
  final String checklistId;

  const ChecklistDetailPage({super.key, required this.checklistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist Details')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('checklists')
            .doc(checklistId)
            .snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No checklist found.'));
          }

          var checklist = snapshot.data!.data() as Map<String, dynamic>;
          var items = (checklist['items'] as List<dynamic>).map((item) => item as Map<String, dynamic>).toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('checks')
                    .where('itemID', isEqualTo: item['itemID'])
                    .orderBy('datentime', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> checkSnapshot) {
                  if (checkSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  String lastCheckedBy = 'Not checked yet';
                  String lastCheckedTime = '';

                  if (checkSnapshot.hasData && checkSnapshot.data!.docs.isNotEmpty) {
                    var lastCheck = checkSnapshot.data!.docs.first;
                    lastCheckedBy = lastCheck['userName'];
                    lastCheckedTime = lastCheck['datentime'].toDate().toString();
                  }

                  return ListTile(
                    title: Text(item['task']),
                    trailing: Text(lastCheckedTime),
                    subtitle: Text(lastCheckedBy),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckHistoryPage(itemId: item['itemID']),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CheckHistoryPage extends StatelessWidget {
  final String itemId;

  const CheckHistoryPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check History')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('checks')
            .where('itemID', isEqualTo: itemId)
            .orderBy('datentime', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No check records found.'));
          }

          var checks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: checks.length,
            itemBuilder: (context, index) {
              var check = checks[index];
              return ListTile(
                title: Text('${check['userName']} checked this item'),
                subtitle: Text('${check['datentime'].toDate()}'),
              );
            },
          );
        },
      ),
    );
  }
}