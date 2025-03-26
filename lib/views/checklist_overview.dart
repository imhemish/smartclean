import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:soochi/dialogs/delete_dialog.dart';
import 'package:soochi/widgets/popup_menu_item.dart';

class ChecklistOverviewPage extends StatefulWidget {
  final String area;

  const ChecklistOverviewPage(
      {super.key, required this.area});

  @override
  State<ChecklistOverviewPage> createState() => _ChecklistOverviewPageState();
}

class _ChecklistOverviewPageState extends State<ChecklistOverviewPage> {
  bool dialogLoadingLocation = true;
  Position? _position;

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enable location')));
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please allow location access')));
        return null;
      }
      return null;
    }
    var loc = Geolocator.getCurrentPosition();
    print(loc);
    return loc;
  }

  void _showAddChecklistDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    bool dialogLoadingLocation = true;
    Position? position;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (dialogLoadingLocation) {
              _determinePosition().then((loc) {
                setDialogState(() {
                  position = loc;
                  dialogLoadingLocation = false;
                });
              });
            }

            return AlertDialog(
              title: const Text('Add New Checklist'),
              content: SizedBox(
                height: dialogLoadingLocation
                    ? MediaQuery.sizeOf(context).height / 3
                    : MediaQuery.sizeOf(context).height / 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          hintText: 'Enter checklist name'),
                    ),
                    const SizedBox(height: 10),
                    if (dialogLoadingLocation)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text("Loading location...")
                        ],
                      )
                    else
                      const Text("Location acquired"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && position != null) {
                      await FirebaseFirestore.instance
                          .collection('checklists')
                          .add({
                        'name': nameController.text,
                        'area': widget.area,
                        'states': [],
                        'latitude': position!.latitude,
                        'longitude': position!.longitude,
                      });
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.area, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange[700],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('checklists')
            .where('area', isEqualTo: widget.area)
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
              return Container(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  
                  title: Text(checklist['name'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'Delete') {
                        showDeleteConfirmationDialog(
                                context, "checklist ${checklist['name']}?")
                            .then((value) {
                          if (value == true) {
                            FirebaseFirestore.instance
                                .collection("checklists")
                                .doc(checklist.id)
                                .delete();
                          } else {
                            print("Delete cancelled");
                          }
                        });
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItemWithIcon(
                          textValue: "Delete",
                          icon: Icons.delete_outline,
                          color: Colors.red),
                    ],
                  ),
                  onTap: () {}
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
              onPressed: () {
                _determinePosition().then((position) {
                  setState(() {
                    _position = position;
                    dialogLoadingLocation = false;
                  });
                });
                _showAddChecklistDialog(context);
              },
              child: const Icon(Icons.add),
            )
          
    );
  }
}