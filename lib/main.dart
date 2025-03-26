import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:soochi/authentication/signup_page.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/utils/cached_data.dart';
import 'package:soochi/views/admin_home_page.dart';
import 'package:soochi/views/on_duty_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(MyApp(userRole: (await CachedData.getCachedNameRoleAndArea()).$2,));
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
    } else if (widget.userRole == UserRole.Coordinator) {
      
      setState(() => homePage = AdminHomePage());
    } else if (widget.userRole == UserRole.Supervisor) {
      setState(() => homePage = OnDutyPage());
    } else {
      // Base case
      setState(() => homePage = SignUpPage());
    }
    
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartClean',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.orange[50],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.orange[800],
        elevation: 0,
        
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
          titleTextStyle: TextStyle(letterSpacing: 2, fontSize: 23, color: Colors.white, fontWeight: FontWeight.w600)
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.orange[700]
        ),
        
      ),
      home: homePage
    );
  }
}