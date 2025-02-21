import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:soochi/models/user.dart';

class AdminPage extends StatelessWidget {
  final UserRole adminRole;
  const AdminPage({super.key, required this.adminRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Areas')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: [if (adminRole == UserRole.Supervisor) UserRole.Attendant.name else UserRole.Supervisor.name])
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No ${adminRole == UserRole.Supervisor ? 'attendants' : 'supervisors'} found.'));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                title: Text(user['name']),
                subtitle: Text('Role: ${user['role']}     Area: ${user['area']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignAreaPage(userId: user.id, role: user['role']),
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

class AssignAreaPage extends StatelessWidget {
  final String userId;
  final String role;

  const AssignAreaPage({super.key, required this.userId, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Area to $role')),
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
                  await FirebaseFirestore.instance.collection('users').doc(userId).update({
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