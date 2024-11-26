import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  /// Check if the user exists in the Firestore 'users' collection
  Future<bool> _doesUserExistInFirestore(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false; // Treat exceptions as non-existing user
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();

      // Check if user exists in Firestore
      final userExists = await _doesUserExistInFirestore(email);

      if (!userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user found with this email.')),
        );
      } else {
        // Send password reset email through Firebase Auth
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent! Check your inbox.')),
        );

        // Optionally navigate back to login screen
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendPasswordResetEmail,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Send Reset Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
