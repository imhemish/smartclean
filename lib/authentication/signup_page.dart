import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soochi/authentication/login_page.dart';

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
      _selectedRole = prefs.getString('role') ?? 'Supervisor';
    });
  }

  Future<void> _saveRole(String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  Future<UserCredential?> _signInWithGoogleOnWeb() async {
    try {
      return await _auth.signInWithPopup(GoogleAuthProvider());
    } catch (error) {
      _showSnackBar(error.toString());
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
      _showSnackBar(error.toString());
      return null;
    }
  }

  Future<bool> _storeUserData(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User already exists, please sign in")));
          return false;
        }
      });
      await _firestore.collection('users').doc(user.uid).set({
        'googleAuthID': FirebaseAuth.instance.currentUser?.uid,
        'uid': _uidController.text,
        'name': _nameController.text,
        'role': _selectedRole,
      }, SetOptions(merge: true));

      await _saveRole(_selectedRole);
      return true;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error storing user data: ${error.toString()}')),
      );
      return false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signInWithGoogle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential =
      kIsWeb ? await _signInWithGoogleOnWeb() : await _signInWithGoogleOnMobile();

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
      _showSnackBar(error.toString());
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
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.orange),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add,
                  size: 60,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 10),
                Text(
                  "Create an Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Sign up to continue",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _uidController,
                        decoration: const InputDecoration(labelText: "UID"),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter your UID' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Name"),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter your Name' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(labelText: "Role"),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ),
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
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
