import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/authentication/signup_page.dart';
import 'package:soochi/models/user.dart';
import 'package:soochi/views/admin_home_page.dart';
import 'package:soochi/views/attendant_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> _signInWithGoogleOnWeb() async {
    try {
      UserCredential credential =
      await _auth.signInWithPopup(GoogleAuthProvider());
      return credential;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return null;
    }
  }

  Future<UserCredential?> _signInWithGoogleOnMobile() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return null;
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential;
      if (kIsWeb) {
        userCredential = await _signInWithGoogleOnWeb();
      } else {
        userCredential = await _signInWithGoogleOnMobile();
      }

      if (userCredential?.user != null) {
        final userInFirebase = await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential!.user!.uid)
            .get();

        if (userInFirebase.exists) {
          final prefs = await SharedPreferences.getInstance();
          final userRole = userInFirebase.get('role');
          String? userArea;
          try {
            userArea = userInFirebase.get('area');
          } catch (stateError) {
            userArea = null;
            print("area is not listed");
          }
          await prefs.setString('role', userRole);
          if (userArea != null) {
            await prefs.setString('area', userArea);
          }
          if (userRole == UserRole.Supervisor.name ||
              userRole == UserRole.Coordinator.name) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => AdminHomePage()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => AttendantPage()));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("User does not exist, please sign up"),
            action: SnackBarAction(
                label: "Sign Up",
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => SignUpPage()))),
          ));
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.orange,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.orange.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.orange.shade800),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.orange.shade700),
                  const SizedBox(height: 10),
                  Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _signInWithGoogle,
                    child: const Text("Login with Google"),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                      );
                    },
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
