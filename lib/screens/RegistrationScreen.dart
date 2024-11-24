import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:file_picker/file_picker.dart'; // For web file picker

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

    // Role assignment logic based on credentials
    // if (_emailController.text == 'fahadmahmud.icte@gmail.com' &&
    //     _passwordController.text == '123456@Pp') {
    //   _role = 'super_admin';
    // }

    setState(() {
      _isUploading = true;
    });

    final imageUrl = await _uploadImageToImageBB();

    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed.')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    await FirebaseFirestore.instance.collection('registrations').add({
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'category': _category,
      'role': _role, // Store the role
      'current_education_status': _educationController.text,
      'university_name': _universityController.text,
      'password': _passwordController.text,
      'image_url': imageUrl,
      'timestamp': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration successful!')),

    );

    setState(() {
      _isUploading = false;
      _formKey.currentState!.reset();
      _image = null;
      _webImage = null;
      _uploadedImageUrl = null;
      _webImage?.clear();
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _educationController.clear();
      _universityController.clear();
      _passwordController.clear();
      _retypePasswordController.clear();



    });


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
                // Category Dropdown
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
                // Password Field with Visibility Toggle
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitForm,
                    child: _isUploading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Register'),
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
      validator: (value) =>
      value == null || value.isEmpty ? 'Enter your $label' : null,
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
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
      ),
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter your $label';
        } else if (value != _passwordController.text &&
            label == 'Retype Password') {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}
