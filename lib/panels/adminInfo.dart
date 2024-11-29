import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminProfileUpdate extends StatefulWidget {
  final String userId;

  AdminProfileUpdate({required this.userId});

  @override
  _AdminProfileUpdateState createState() => _AdminProfileUpdateState();
}

class _AdminProfileUpdateState extends State<AdminProfileUpdate> {
  final _formKey = GlobalKey<FormState>();

  final organizationNameController = TextEditingController();
  final organizationContactController = TextEditingController();
  final organizationEmailController = TextEditingController();
  final designationController = TextEditingController();

  File? _image;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    organizationNameController.dispose();
    organizationContactController.dispose();
    organizationEmailController.dispose();
    designationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final adminOrgRef =
    FirebaseFirestore.instance.collection('adminorg').doc(widget.userId);
    DocumentSnapshot adminOrgSnapshot = await adminOrgRef.get();

    if (adminOrgSnapshot.exists) {
      var adminOrgData = adminOrgSnapshot.data() as Map<String, dynamic>;
      organizationNameController.text = adminOrgData['organizationName'] ?? '';
      organizationContactController.text = adminOrgData['organizationContact'] ?? '';
      organizationEmailController.text = adminOrgData['organizationEmail'] ?? '';
      designationController.text = adminOrgData['designation'] ?? '';
      imageUrl = adminOrgData['imageUrl'];
    } else {
      final userRef =
      FirebaseFirestore.instance.collection('users').doc(widget.userId);
      DocumentSnapshot userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        organizationNameController.text = userData['organizationName'] ?? '';
        organizationContactController.text = userData['organizationContact'] ?? '';
        organizationEmailController.text = userData['organizationEmail'] ?? '';
        designationController.text = userData['designation'] ?? '';
        imageUrl = userData['userImageUrl'];
      }
    }

    setState(() {});
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  final String imageBBApiKey = '9b0fc2dd74bc6240f21869b39ef5929c';

  Future<String?> _uploadImageToImageBB(File image) async {
    try {
      final url = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['key'] = imageBBApiKey;
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['data']['url'];
      } else {
        print('Image upload failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null;
  }

  Future<void> _updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      final String organizationName = organizationNameController.text.trim();
      final String organizationContact = organizationContactController.text.trim();
      final String organizationEmail = organizationEmailController.text.trim();
      final String designation = designationController.text.trim();

      String? uploadedImageUrl;
      if (_image != null) {
        uploadedImageUrl = await _uploadImageToImageBB(_image!);
      }

      final adminOrgRef =
      FirebaseFirestore.instance.collection('adminorg').doc(widget.userId);

      await adminOrgRef.set({
        'organizationName': organizationName,
        'organizationContact': organizationContact,
        'organizationEmail': organizationEmail,
        'designation': designation,
        'imageUrl': uploadedImageUrl ?? imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Successful'),
            content: Text('Profile Updated Successfully'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Admin Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,

                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : imageUrl != null
                        ? NetworkImage(imageUrl!)
                        : AssetImage('assets/default_avatar.png') as ImageProvider,
                    child: _image == null && imageUrl == null
                        ? Icon(Icons.camera_alt, size: 50)
                        : null,
                  ),

                ),
                SizedBox(height: 20),
                Text("Upload Your Organization Logo"),
                SizedBox(height: 20),
                TextFormField(
                  controller: organizationNameController,
                  decoration: InputDecoration(labelText: 'Organization Name'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter organization name' : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: organizationContactController,
                  decoration: InputDecoration(labelText: 'Contact Number'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter contact number' : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: organizationEmailController,
                  decoration: InputDecoration(labelText: 'Email Address'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter email address' : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: designationController,
                  decoration: InputDecoration(labelText: 'Designation'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter designation' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateUserProfile,
                  child: Text('Update Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
