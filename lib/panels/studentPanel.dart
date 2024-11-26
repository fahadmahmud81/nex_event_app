import 'package:flutter/material.dart';

class StudentApp extends StatefulWidget {
  const StudentApp({super.key});

  @override
  _StudentAppState createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  String title = "Student Panel";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(title, style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
