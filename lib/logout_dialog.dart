import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:soochi/authentication/signup_page.dart";

showSignOutDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Sign Out"),
          content: Text("Do you want to sign out?"),
          actions: [
            TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  SharedPreferences.getInstance().then((prefs) {
                    try {
                      prefs.remove("role");
                      prefs.remove("area");
                    } catch (e) {
                      print("error removing role and area: $e.toString()");
                    }
                  });
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => SignUpPage()));
                },
                child: Text("Yes"))
          ],
        );
      });
}
