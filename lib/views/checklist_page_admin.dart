import 'package:flutter/material.dart';

class ChecklistPageAdmin extends StatefulWidget {
  const ChecklistPageAdmin({super.key});

  @override
  State<ChecklistPageAdmin> createState() => _ChecklistPageAdminState();
}
class _ChecklistPageAdminState extends State<ChecklistPageAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Checklist',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white,letterSpacing: 2),
        ),
        backgroundColor: Colors.orange[700],
        elevation: 4,
      ),
    );
  }
}
