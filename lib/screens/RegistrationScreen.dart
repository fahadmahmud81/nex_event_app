import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Please verify your email.')),
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
      return Center(child: Text('No image selected'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField('Name', _nameController),
                SizedBox(height: 16),
                _buildTextField('Email', _emailController),
                SizedBox(height: 16),
                _buildTextField('Phone', _phoneController),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'sponsor', child: Text('Sponsor')),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null ? 'Please select a category' : null,
                ),
                SizedBox(height: 16),
                _buildTextField('Current Educational Status', _educationController),
                SizedBox(height: 16),
                _buildTextField('University Name', _universityController),
                SizedBox(height: 16),
                _buildPasswordField('Password', _passwordController),
                SizedBox(height: 16),
                _buildPasswordField('Retype Password', _retypePasswordController),
                SizedBox(height: 20),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.teal),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),
                SizedBox(height: 20),
                _isUploading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitForm,
                  child: Container(
                    height: 200,
                      width: 80,

                      child: Text('Register',style:TextStyle(color:Colors.white),)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
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
        border: OutlineInputBorder(),
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
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }
}
