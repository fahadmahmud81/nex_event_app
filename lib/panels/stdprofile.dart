import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//StudentProfile Info

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
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(imageUrl),
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
