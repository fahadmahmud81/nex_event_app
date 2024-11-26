import 'package:flutter/material.dart';

class SuperApp extends StatefulWidget {
  const SuperApp({super.key});

  @override
  _SuperAppState createState() => _SuperAppState();
}

class _SuperAppState extends State<SuperApp> {
  String title = "Super Admin";

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
