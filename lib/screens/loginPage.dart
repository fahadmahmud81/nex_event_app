import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:nex_event_app/screens/splashscreen.dart';
import 'forgotPassword.dart'; // Ensure this page is implemented
import 'package:nex_event_app/panels/adminPanel.dart';
import 'package:nex_event_app/panels/studentPanel.dart';
import 'package:nex_event_app/panels/superAdmin.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false; // Toggle password visibility
  bool _isLoading = false;

  Future<void> _loginAndSyncPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Sign in the user
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Update Firestore with the new password
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .update({'password': password}); // Sync password
      }

      // Determine the user role and navigate
      final userDoc = querySnapshot.docs.first;
      String role = userDoc['role'];

      if (role == 'student') {
        Get.to(() => StudentApp());
      } else if (role == 'super_admin') {
        Get.to(() => SuperApp());
      } else if (role == 'event_admin') {
        Get.to(() => AdminApp());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown role assigned.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Check your credentials.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToForgotPassword() {
    Get.to(() => ForgotPasswordPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),
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
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _navigateToForgotPassword,
                    child: Text('Forgot Password?'),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginAndSyncPassword,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Login'),
                  ),
                ),
                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [ Text("Don't have an account?"),
                    TextButton(onPressed: (){
                      Get.to(() => SplashScreen());
                    }, child: Text("Register"))


                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
