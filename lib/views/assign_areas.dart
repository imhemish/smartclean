import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:soochi/models/user.dart';

class AssignAreasOverviewPage extends StatelessWidget {
  const AssignAreasOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Areas')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: UserRole.Supervisor.name)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No supervisors found'));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                title: Text(user['name']),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignAreaPage(userId: user.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AssignAreaPage extends StatefulWidget {
  final String userId;

  const AssignAreaPage({super.key, required this.userId});

  @override
  State<AssignAreaPage> createState() => _AssignAreaPageState();
}

class _AssignAreaPageState extends State<AssignAreaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Area to Supervisor')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('areas').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No areas available.'));
          }

          var areas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: areas.length,
            itemBuilder: (context, index) {
              var area = areas[index];
              return ListTile(
                title: Text(area['name']),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
                    'area': area['name'],
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}