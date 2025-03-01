import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:soochi/dialogs/delete_dialog.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/widgets/popup_menu_item.dart';
import 'package:uuid/uuid.dart';

class ChecklistOverviewPage extends StatefulWidget {
  final String area;
  final UserRole adminRole;

  const ChecklistOverviewPage(
      {super.key, required this.area, required this.adminRole});

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
                        'items': [],
                        'assignedToUserIDs': [],
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
                  leading: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.red,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      checklist['items'].length.toString(),
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
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
                      } else if (value == 'Assign') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AssignCheckListToAttendantPage(
                                        checklistId: checklist.id,
                                        checklistName: checklist['name'],
                                        area: widget.area)));
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItemWithIcon(
                          textValue: "Delete",
                          icon: Icons.delete_outline,
                          color: Colors.red),
                      PopupMenuItemWithIcon(
                          textValue: "Assign",
                          icon: Icons.person_add,
                          color: Colors.blue)
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChecklistDetailPage(
                          checklistId: checklist.id,
                          name: checklist['name'],
                          adminRole: widget.adminRole),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.adminRole == UserRole.Supervisor
          ? FloatingActionButton(
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
          : null,
    );
  }
}

class ChecklistDetailPage extends StatelessWidget {
  final String checklistId;
  final UserRole adminRole;
  final String name;

  const ChecklistDetailPage(
      {super.key,
      required this.checklistId,
      required this.adminRole,
      required this.name});

  void _showAddTaskDialog(BuildContext context) {
    TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: taskController,
            decoration:
                const InputDecoration(hintText: 'Enter task description'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (taskController.text.isNotEmpty) {
                  DocumentReference checklistRef = FirebaseFirestore.instance
                      .collection('checklists')
                      .doc(checklistId);
                  await checklistRef.update({
                    'items': FieldValue.arrayUnion([
                      {'task': taskController.text, 'itemID': Uuid().v4()}
                    ]),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist: $name', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange[700],
      ),
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
          var items = (checklist['items'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return Container(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(item['task'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  trailing: adminRole == UserRole.Coordinator ? Icon(Icons.history) : PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'Delete') {
                          showDeleteConfirmationDialog(
                                  context, "task ${item['task']}?")
                              .then((value) {
                            if (value == true) {
                              FirebaseFirestore.instance
                                  .collection("checklists")
                                  .doc(checklistId)
                                  .update({
                                'items': FieldValue.arrayRemove([item])
                              });
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
                                color: Colors.red)
                          ]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          print(item['itemID']);
                          return CheckHistoryPage(itemId: item['itemID']);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: adminRole == UserRole.Supervisor
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context),
              child: const Icon(Icons.add_task),
            )
          : null,
    );
  }
}

class AssignCheckListToAttendantPage extends StatefulWidget {
  final String checklistName;
  final String checklistId;
  final String area;

  const AssignCheckListToAttendantPage(
      {super.key,
      required this.checklistId,
      required this.checklistName,
      required this.area});

  @override
  State<AssignCheckListToAttendantPage> createState() =>
      _AssignCheckListToAttendantPageState();
}

class _AssignCheckListToAttendantPageState
    extends State<AssignCheckListToAttendantPage> {
  List<String> assignedIDs = [];

  @override
  void initState() {
    FirebaseFirestore.instance
        .collection('checklists')
        .doc(widget.checklistId)
        .get()
        .then((doc) {
      setState(() {
        assignedIDs = (doc.data()!['assignedToUserIDs'] as List<dynamic>)
            .map((id) => id as String)
            .toList();
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign checklist: ${widget.checklistName}')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: UserRole.Attendant.name)
            .where('area', isEqualTo: widget.area)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No attendants found.'));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                title: Text(user['name']),
                trailing: IconButton(
                  icon: assignedIDs.contains(user['googleAuthID'])
                      ? const Icon(Icons.check_box)
                      : const Icon(Icons.check_box_outline_blank),
                  onPressed: () {
                    setState(() {
                      if (assignedIDs.contains(user['googleAuthID'])) {
                        assignedIDs.remove(user['googleAuthID']);
                      } else {
                        assignedIDs.add(user['googleAuthID']);
                      }

                      FirebaseFirestore.instance
                          .collection("checklists")
                          .doc(widget.checklistId)
                          .update({
                        'assignedToUserIDs': assignedIDs,
                      });
                    });
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

class CheckHistoryPage extends StatelessWidget {
  final String itemId;

  const CheckHistoryPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange[700],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('checks')
            .where('itemID', isEqualTo: itemId)
            //.orderBy('datentime', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No check records found.'));
          }

          var checks =
              snapshot.data!.docs; // No need to check ConnectionState.done

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
