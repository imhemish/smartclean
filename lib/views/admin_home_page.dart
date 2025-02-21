import 'package:flutter/material.dart';
import 'package:soochi/views/profile_page_admin.dart';
import 'package:soochi/views/checklist_page_admin.dart';
import 'attendance_page.dart';
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AttendancePage(),
    const ChecklistPageAdmin(),
    const ProfilePageAdmin(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Checklist'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
