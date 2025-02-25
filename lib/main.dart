import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/authentication/signup_page.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/views/admin_home_page.dart';
import 'package:soochi/views/attendant_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  String? stringRole = (await SharedPreferences.getInstance()).getString('role');
  UserRole? userRole;
  if (stringRole != null) {
    userRole = UserRole.values.firstWhere((element) => element.name == stringRole);
  }
  FlutterNativeSplash.remove();
  runApp(MyApp(userRole: userRole,));
}

class MyApp extends StatefulWidget {
  final UserRole? userRole;
  const MyApp({super.key, required this.userRole});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? homePage;
  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      
      setState(() => homePage = SignUpPage());
    } else if (widget.userRole == UserRole.Coordinator || widget.userRole == UserRole.Supervisor) {
      setState(() => homePage = AdminHomePage());
    } else if (widget.userRole == UserRole.Attendant) {
      setState(() => homePage = AttendantPage());
    } else {
      // Base case
      setState(() => homePage = SignUpPage());
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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