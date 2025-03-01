import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:soochi/dialogs/delete_dialog.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/views/assign_areas.dart';
import 'package:soochi/views/checklist_overview.dart';
import 'package:soochi/widgets/popup_menu_item.dart';

class AreasPage extends StatelessWidget {
  const AreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Areas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_pin),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignAreasOverviewPage(adminRole: UserRole.Coordinator,),
                ),
              );
            },
          ),
        ],
        ),
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
                trailing: PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'Delete') {
                      showDeleteConfirmationDialog(context, 'area ${areas[index]}? It would remove all the checklists associated with it. This should not be done unless absolutely necessary!').then((value) {
                        if (value == null || !value) {
                          return;

                        }
                        FirebaseFirestore.instance.collection("checklists").where('area', isEqualTo: areas[index]).get().then((snapshot) {
                          for (DocumentSnapshot doc in snapshot.docs) {
                            doc.reference.delete();
                          }
                        });
                        FirebaseFirestore.instance.collection("users").where('area', isEqualTo: areas[index]).get().then((snapshot) {
                          for (DocumentSnapshot doc in snapshot.docs) {
                            doc.reference.update({'area': FieldValue.delete()});
                          }
                        });
                        FirebaseFirestore.instance.collection('areas').doc(snapshot.data!.docs[index].id).delete();
                      });
                      
                    } 
                  },
                  icon: Icon(Icons.more_vert),
                  itemBuilder: (context) {
                  return [
                    PopupMenuItemWithIcon(
                      icon: Icons.delete_outline,
                      textValue: 'Delete',
                      color: Colors.red,

                    )
                  ];
                }),
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
