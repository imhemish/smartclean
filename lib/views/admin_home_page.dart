import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/views/areas_page_admin.dart';
import 'package:soochi/views/checklist_overview.dart';
import 'package:soochi/views/profile_page_admin.dart';

import 'attendance_page.dart';
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  // would be initialised later
  final List<Widget> _pages = [];

  // just specify any adminrole value at first, would be given later by initstate
  UserRole adminRole = UserRole.Coordinator;
  String? area;
  // because coordinator wouldnt have any area, so it is nullable
  bool loading = true;

  void _setupRoleAndAreaAndPages() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    if (role == 'Supervisor') {
      adminRole = UserRole.Supervisor;
    } else if (role == 'Coordinator') {
      adminRole = UserRole.Coordinator;
    }

    area = prefs.getString('area');

    // if area is null, it could be coordinator
    // but if area is not null, it is supervisor who hasnt been assigned an area yet
    // but maybe recently he is assigned area, which is not in shared preferences
    // so we get that from firebase
    if (area == null && adminRole == UserRole.Supervisor) {
      final snapshot = await FirebaseFirestore.instance.collection("users").where("googleAuthID", isEqualTo: FirebaseAuth.instance.currentUser!.uid).get();
        if (snapshot.docs.isNotEmpty) {
          final user = snapshot.docs.first;
          area = user.get("area");
          if (area != null) {
            prefs.setString("area", area!);
          }
            
        }
  
    }

    _pages.add(AttendancePage());
    
    if (adminRole == UserRole.Supervisor) {
      _pages.add(ChecklistOverviewPage(area: area ?? "", adminRole: UserRole.Supervisor,));
    } else if (adminRole == UserRole.Coordinator) {
      _pages.add(AreasPage());
    }
    _pages.add(ProfilePageAdmin());
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _setupRoleAndAreaAndPages();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    if (adminRole == UserRole.Supervisor && area == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            children: [
              Icon(Icons.error, color: Colors.red, size: 50),
              Center(
          
                child: Text("You are not assigned any area yet"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange[700],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.orange[50],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: adminRole == UserRole.Coordinator ? "Areas" : 'Checklists'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
