import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/authentication/login_page.dart';
import 'package:soochi/utils/cached_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: CachedData.getCachedNameRoleAndArea(),
      builder: (context, snapshot) { 
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
          child: CircularProgressIndicator(
            color: Colors.orange[600],
          ),
        );

        } else {
        return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.orange[700],
          title: const Text(
            'Profile',
            
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.orange.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50,),
              ),
              const SizedBox(height: 16),
              Text(
                snapshot.data?.$1 ?? "Not available",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                snapshot.data?.$2?.name ?? "Unassigned role",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              if (!(snapshot.data?.$2?.name == 'Coordinator')) Text(
                snapshot.data?.$3 ?? "Unassigned area",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text('Logout'),
                  onTap: () {
                    SharedPreferences.getInstance().then((value) {
                      value.clear();
                    });
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> LoginPage()));
                  },
                ),
              ),
            ],
          ),
        ),
      );
      }
      }
    );
  }
}
