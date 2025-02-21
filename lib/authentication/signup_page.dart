import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/authentication/login_page.dart';
import 'package:soochi/views/attendance_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _selectedRole = 'Supervisor';
  final List<String> _roles = ['Supervisor', 'Attendant', 'Coordinator'];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRole = prefs.getString('user_role') ?? 'Supervisor';
    });
  }

  Future<void> _saveRole(String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

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

  Future<void> _storeUserData(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'googleAuthID': FirebaseAuth.instance.currentUser?.uid,
        'uid': _uidController.text,
        'name': _nameController.text,
        'role': _selectedRole,
      }, SetOptions(merge: true));

      await _saveRole(_selectedRole);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error storing user data: ${error.toString()}')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        userCredential = await _signInWithGoogleOnWeb();
      } else {
        userCredential = await _signInWithGoogleOnMobile();
      }

      if (userCredential?.user != null) {
        await _storeUserData(userCredential!.user!);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
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
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.orange,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange),
          ),
          labelStyle: const TextStyle(color: Colors.orange),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _uidController,
                  decoration: const InputDecoration(
                    labelText: "UID",
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your UID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your Name' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: "Role",
                  ),
                  items: _roles.map((String role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Please select a role' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_icon.png',
                    height: 24,
                    width: 24,
                  ),
                  label: const Text("Sign up with Google"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AttendancePage()),
                  ),
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
