import 'package:flutter/material.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  _AdminAppState createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  String title = "Event Admin";

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
