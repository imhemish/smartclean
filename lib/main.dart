import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/authentication/signup_page.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/views/admin_home_page.dart';
import 'package:soochi/views/attendant_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  String? stringRole = (await SharedPreferences.getInstance()).getString('role');
  UserRole? userRole;
  if (stringRole != null) {
    userRole = UserRole.values.firstWhere((element) => element.name == stringRole);
  }
  
  runApp(MyApp(userRole: userRole,));
}

class MyApp extends StatelessWidget {
  final UserRole? userRole;
  const MyApp({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    Widget? homePage;
    if (FirebaseAuth.instance.currentUser == null) {
      homePage = SignUpPage();
    } else if (userRole == UserRole.Coordinator || userRole == UserRole.Supervisor) {
      homePage = AdminHomePage();
    } else if (userRole == UserRole.Attendant) {
      homePage = AttendantPage();
    } else {
      // Base case
      homePage = SignUpPage();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Soochi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.orange[700],
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 25)
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.orange[700]
        ),
        
      ),
      home: homePage
    );
  }
}