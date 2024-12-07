import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final String userId; // The user ID passed from StudentApp

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _categoryController;
  late TextEditingController _educationController;
  late TextEditingController _phoneController;

  // Variables to store user data
  String name = '';
  String imageUrl = '';
  String category = '';
  String education = '';
  String phone = '';
  String university = '';

  final String imageBBApiKey = '9b0fc2dd74bc6240f21869b39ef5929c';

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _educationController = TextEditingController();
    _phoneController = TextEditingController();
    _getUserData();
  }

  // Fetch user data from Firestore
  Future<void> _getUserData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId) // Use userId passed from StudentApp
        .get();

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        name = data['name'] ?? 'No name available';
        imageUrl = data['imageUrl'] ?? 'https://example.com/default-image.jpg'; // Provide a default image URL
        category = data['category'] ?? '';
        education = data['education'] ?? '';
        phone = data['phone'] ?? '';
        university = data['university'] ?? 'No university available';

        // Set initial values for editing
        _categoryController.text = category;
        _educationController.text = education;
        _phoneController.text = phone;
      });
    }
  }

  // Upload image to imgBB and get the URL
  Future<String?> _uploadImageToImageBB(File image) async {
    try {
      final url = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['key'] = imageBBApiKey;
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['data']['url'];
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null;
  }

  // Pick image from gallery or camera
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final uploadedUrl = await _uploadImageToImageBB(file);

      if (uploadedUrl != null) {
        setState(() {
          imageUrl = uploadedUrl;
        });

        // Update Firestore with the new image URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'imageUrl': imageUrl});

        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile photo updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo. Please try again.')),
        );
      }
    }
  }

  // Update user data in Firestore
  Future<void> _updateUserData() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'category': _categoryController.text,
      'education': _educationController.text,
      'phone': _phoneController.text,
    });

    // Show confirmation message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Successful!'),
          content: Text('Profile Updated Successfully'),
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
  }

  @override
  Widget build(BuildContext context) {

    Future<String> _loadImage(String imageUrl) async {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return imageUrl; // Return the valid image URL
        } else {
          throw Exception('Failed to load image');
        }
      } catch (e) {
        return ''; // Return empty if there's an error
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: FutureBuilder(
                future: _loadImage(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      radius: 50,
                      child: CircularProgressIndicator(), // Show loader while image loads
                    );
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/default_image.png'), // Default local image
                    );
                  } else {
                    return CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(snapshot.data as String),
                    );
                  }
                },
              ),
            ),

            SizedBox(height: 20),
            Text('Name: $name', style: TextStyle(fontSize: 18)),
            Text('University: $university', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: '''Account Category [student, event admin, sponsor]'''),
            ),
            TextField(
              controller: _educationController,
              decoration: InputDecoration(labelText: 'Educational Status [Student, Undergraduate, Graduate]'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUserData,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
