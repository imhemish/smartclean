import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/authentication/login_page.dart';
import 'package:soochi/utils/cached_data.dart';
import 'package:soochi/views/areas_page_admin.dart';
import 'package:soochi/views/profile_page.dart';
import 'package:soochi/views/records.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  bool isAdmin = false;

  // would be initialised later
  final List<Widget> _pages = [ChecklistRecordsPage(), AreasPage(), ProfilePage()];

  _figureOutAdmin() async {
    if (await CachedData.getAdminState()) {
      setState(() {
        isAdmin = true;
      });
    } else {
      // cache says not admin, but we are double checking from database
      // if the user is an admin (newly set which was not in cache)
      // then also set in cache
      final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = snapshot.data() as Map<String, dynamic>;
    print(data);
    
    if (data['admin'] == true) {
      await CachedData.setAdminStateTrue();
      setState(() {
        isAdmin = true;
      });
    }
    }
    
  }
  @override
  void initState() {
    super.initState();
    _figureOutAdmin();

  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              Text('You are not an admin'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  SharedPreferences.getInstance().then((value) {
                      value.clear();
                    });
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> LoginPage()));
                },
                child: const Text('Sign Out'),
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
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
