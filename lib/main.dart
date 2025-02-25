import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:soochi/authentication/login_page.dart';
import 'package:soochi/authentication/signup_page.dart';
import 'package:soochi/views/admin_home_page.dart';
import 'package:soochi/views/assigned_task_page.dart';
import 'package:soochi/views/attendance_page.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/views/assign_areas.dart';
import 'package:soochi/views/areas_page_admin.dart';
import 'package:soochi/views/checklist_overview.dart';
import 'package:soochi/views/checklist_page_admin.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: AssignedTasksPage(),
    );
  }
}