import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import 'otpCode.dart'; // For web file picker

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _retypePasswordController = TextEditingController();

  String? _category = 'general'; // Default category
  String _role = 'student'; // Default role
  bool _isPasswordVisible = false; // For toggling password visibility

  File? _image; // For mobile
  Uint8List? _webImage; // For web
  String? _uploadedImageUrl; // For storing the ImageBB URL
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();
  final String _imageBBApiKey = '9b0fc2dd74bc6240f21869b39ef5929c';

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _webImage = result.files.first.bytes;
        });
      }
    } else {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 500,
        maxWidth: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  Future<String?> _uploadImageToImageBB() async {
    final url = Uri.parse('https://api.imgbb.com/1/upload');
    String base64Image;

    if (kIsWeb) {
      if (_webImage == null) return null;
      base64Image = base64Encode(_webImage!);
    } else {
      if (_image == null) return null;
      base64Image = base64Encode(_image!.readAsBytesSync());
    }

    final response = await http.post(
      url,
      body: {
        'key': _imageBBApiKey,
        'image': base64Image,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['data']['url']; // Return the image URL
    } else {
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Check if email already exists
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text)
          .get();

      if (existingUser.docs.isNotEmpty) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This email is already registered!')),
        );
        return;
      }

      // Create user with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim());

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Upload image
      final imageUrl = await _uploadImageToImageBB();
      if (imageUrl == null) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed.')),
        );
        return;
      }

      // Add user details to Firestore
      await FirebaseFirestore.instance.collection('registrations').add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'education': _educationController.text.trim(),
        'university': _universityController.text.trim(),
        'category': _category,
        'role': _role,
        'profileImage': imageUrl,
        'emailVerified': false,
      });

      setState(() {
        _isUploading = false;
      });

      // Navigate to OTP verification screen (or next step)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationPage(
            email: _emailController.text,
            name: _nameController.text,
            phone: _phoneController.text,
            category: _category,
            role: _role,
            education: _educationController.text,
            university: _universityController.text,
            password: _passwordController.text,
            imageUrl: imageUrl,
            registrationData: {},
          ),
        ),
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Registration Successful'),
            content: Text('Email Verification link will be forwarded.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed. Please try again later.')),
      );
    }
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImage != null) {
      return Image.memory(
        _webImage!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && _image != null) {
      return Image.file(
        _image!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Center(child: Text('Click here to select Image!'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue,
                  ),
                ),
                Text('Sign up to continue',style: TextStyle(fontSize: 15),),
                SizedBox(height: 20),

// Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.perm_contact_cal_outlined),
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

// Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

// Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone),
                    labelText: 'Phone',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your phone number';
                    }
                    if (!RegExp(r'^(?:\+88)?01[3-9]\d{8}$').hasMatch(value)) {
                      return 'Enter a valid Bangladeshi phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _category,
                  items: [
                    DropdownMenuItem(value: 'general', child: Text('General',style: TextStyle(fontWeight: FontWeight.bold),)),
                    DropdownMenuItem(value: 'admin', child: Text('Admin',style: TextStyle(fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 'sponsor', child: Text('Sponsor',style: TextStyle(fontWeight: FontWeight.bold))),

                  ],
                  onChanged: (value) => setState(() => _category = value),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder( borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) =>
                  value == null ? 'Please select a category' : null,
                ),
                SizedBox(height: 16),

// Current Educational Status
                TextFormField(
                  controller: _educationController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.co_present),
                    labelText: 'Current Educational Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your current educational status';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

// University Name
                TextFormField(
                  controller: _universityController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined),
                    labelText: 'University Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your university name';
                    }
                    if (value.length < 3) {
                      return 'University name must be at least 3 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildPasswordField('Password', _passwordController),
                SizedBox(height: 16),
                _buildPasswordField('Retype Password', _retypePasswordController),
                SizedBox(height: 20),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.teal),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),
                SizedBox(height: 20),
                _isUploading
                    ? Center(child: CircularProgressIndicator())
                    : Container(
                  height: 45,
                      child: ElevatedButton(

                                        onPressed: _submitForm,
                                        child: Center(


                        child: Text('Register',style:TextStyle(color:Colors.white,fontSize: 18,fontWeight: FontWeight.bold),)
                                        ),

                                        style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      // Change this to your desired color
                      foregroundColor: Colors.white,
                      // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            15), // Optional: Rounded corners
                      ),
                                        ),
                                      ),
                    ),
                SizedBox(height: 10,)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder( borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(
      String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(

        labelText: label,
        prefixIcon: Icon(Icons.password_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder( borderRadius: BorderRadius.circular(10),),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }
}
