import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/views/checklist_overview.dart';

class AreasPage extends StatelessWidget {
  const AreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Areas')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('areas').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No areas found.'));
          }

          var areas = snapshot.data!.docs
              .map((doc) => doc['name'] as String)
              .toList();

          return ListView.builder(
            itemCount: areas.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(areas[index]),
                trailing: Icon(Icons.list),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChecklistOverviewPage(area: areas[index], adminRole: UserRole.Coordinator,),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? newArea = await _showAddAreaDialog(context);
          if (newArea != null && newArea.trim().isNotEmpty) {
            FirebaseFirestore.instance.collection('areas').add({'name': newArea.trim()});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String?> _showAddAreaDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Area'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter area name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
