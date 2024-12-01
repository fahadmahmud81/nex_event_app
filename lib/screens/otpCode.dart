import 'dart:async';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'loginPage.dart'; // Import GetX for navigation

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String? category;
  final String role;
  final String education;
  final String university;
  final String password;
  final String imageUrl;

  EmailVerificationPage({
    required this.email,
    required this.name,
    required this.phone,
    this.category,
    required this.role,
    required this.education,
    required this.university,
    required this.password,
    required this.imageUrl, required Map registrationData,
  });

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  late FirebaseAuth _auth;
  bool _isEmailVerified = false;
  bool _isLoading = true;
  Timer? _verificationCheckTimer;



  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _registerUserAndSendVerification();
  }

  void _registerUserAndSendVerification() async {
    try {
      // Register user temporarily to send email verification
      await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // Send email verification
      User? user = _auth.currentUser;
      await user?.sendEmailVerification();

      // Start checking for email verification status
      _startEmailVerificationCheck();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        // SnackBar(content: Text('Failed to send verification email: $e')),
        SnackBar(content: Text('Check your Email. Waiting for the Process!')),
      );
    }
  }

  void _startEmailVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      User? user = _auth.currentUser;
      await user?.reload();
      if (user?.emailVerified ?? false) {
        setState(() {
          _isEmailVerified = true;
          _verificationCheckTimer?.cancel();
        });
        _saveUserToDatabase();
      }
    });
  }

  void _saveUserToDatabase() async {

    try {


      // Save user data to Firestore users collection
      await FirebaseFirestore.instance.collection('users').add({
        'name': widget.name,
        'email': widget.email,
        'phone': widget.phone,
        'category': widget.category,
        'role': widget.role,
        'education': widget.education,
        'university': widget.university,
        'password': widget.password, // Ensure secure storage in production
        'imageUrl': widget.imageUrl,
        'emailVerified': true,
      });

      // Now delete the user data from the 'registrations' collection where name and email match
      await FirebaseFirestore.instance
          .collection('registrations')
          .where('name', isEqualTo: widget.name)
          .where('email', isEqualTo: widget.email)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.delete(); // Delete the matching document
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email verified successfully!')),

      );

      // Navigate to LoginPage using GetX
      Get.to(() => LoginPage());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save user data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('Email Verification')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _isEmailVerified
          ? Center(child: Text('Email verified! Redirecting...'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A verification email has been sent to ${widget.email}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Please check your email and verify your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                User? user = _auth.currentUser;
                await user?.reload();
                if (user?.emailVerified ?? false) {
                  setState(() {
                    _isEmailVerified = true;
                  });
                  _saveUserToDatabase();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Click Again if Email not verified yet!')),
                  );
                }
              },
              child: Text('I have verified my email'),
            ),

            SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                User? user = _auth.currentUser;
                await user?.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Verification email resent!')),
                );
              },
              child: Text('Resend Verification Email'),
            ),
          ],
        ),
      ),
    );
  }
}

