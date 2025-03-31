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
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 2),
  ));
  await remoteConfig.fetchAndActivate();

  final allowedVersions = remoteConfig.getString('versions').split(';');
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;
  print('Current version: $currentVersion');
  print('Allowed versions: $allowedVersions');

  if (!allowedVersions.contains(currentVersion)) {
    runApp(const UpgradeAppPage());
  } else {
    runApp(MyApp(
      userRole: (await CachedData.getCachedNameRoleAndArea()).$2,
    ));
  }
}

class UpgradeAppPage extends StatefulWidget {
  const UpgradeAppPage({Key? key}) : super(key: key);

  @override
  State<UpgradeAppPage> createState() => _UpgradeAppPageState();
}

class _UpgradeAppPageState extends State<UpgradeAppPage> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download, size: 100, color: Colors.orange[800],),
              const SizedBox(height: 20),
              Text("Upgrade Required", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.orange[800])),

                
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final remoteConfig = FirebaseRemoteConfig.instance;
                  final allowedVersions = remoteConfig.getString('versions').split(';');
                  final latestVersion = allowedVersions.last;
                  final url = 'https://github.com/imhemish/soochi/releases/download/$latestVersion/SmartClean.apk';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  
                ),
                child: const Text('Download Latest Version', textAlign: TextAlign.left, style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
              titleTextStyle: TextStyle(
                  letterSpacing: 2,
                  fontSize: 23,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.orange[700]),
        ),
        home: homePage);
  }
}
