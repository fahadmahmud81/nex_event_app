import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

final String imageBBApiKey = '9b0fc2dd74bc6240f21869b39ef5929c';

class SponsorPage extends StatefulWidget {
  @override
  _SponsorPageState createState() => _SponsorPageState();
}

class _SponsorPageState extends State<SponsorPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Listen for changes in the search box
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search Sponsors',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Add Sponsor Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddSponsorPage()),
                );
              },
              child: Text('Add a Sponsor'),
            ),
          ),
          // Sponsor List with Cards
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('sponsor').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return Center(child: Text('No sponsors available.'));
                }

                var sponsorDocs = snapshot.data!.docs;
                // Filter sponsors based on the search query
                var filteredSponsors = sponsorDocs.where((sponsorDoc) {
                  var sponsor = sponsorDoc.data() as Map<String, dynamic>;
                  String name = sponsor['name'] ?? '';
                  String interest = sponsor['interest'] ?? '';
                  return name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      interest.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                return Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredSponsors.length,
                    itemBuilder: (context, index) {
                      var sponsor = filteredSponsors[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 5,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue,
                              backgroundImage: NetworkImage(sponsor['imageUrl'] ?? ''),
                              child: sponsor['imageUrl'] == null
                                  ? Icon(Icons.business, color: Colors.white)
                                  : null,
                            ),
                            SizedBox(height: 10),
                            Text(sponsor['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(sponsor['email'] ?? ''),
                            Text(sponsor['phone'] ?? ''),
                            Text(sponsor['interest'] ?? ''),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                        builder: (context) => EditSponsorPage(
                                      sponsorId: sponsorDocs[index].id,
                                      name: sponsor['name'] ?? '',
                                      interest: sponsor['interest'] ?? '',
                                      email: sponsor['email'] ?? '',
                                      phone: sponsor['phone'] ?? '',
                                      imageUrl: sponsor['imageUrl'] ?? '',
                                    ),
                                        ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('sponsor')
                                        .doc(filteredSponsors[index].id)
                                        .delete();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class EditSponsorPage extends StatefulWidget {
  final String sponsorId;
  final String name;
  final String interest;
  final String email;
  final String phone;
  final String imageUrl;

  EditSponsorPage({
    required this.sponsorId,
    required this.name,
    required this.interest,
    required this.email,
    required this.phone,
    required this.imageUrl,
  });

  @override
  _EditSponsorPageState createState() => _EditSponsorPageState();
}

class _EditSponsorPageState extends State<EditSponsorPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _imageFile;

  // Image Picker to select an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Upload image to imgbb
  Future<String?> _uploadImageToImageBB(File image) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = imageBBApiKey
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (jsonResponse['status'] == 200) {
        return jsonResponse['data']['url'];  // Return the image URL
      } else {
        print('Failed to upload image: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Error uploading image to imgbb: $e');
      return null;
    }
  }

  // Update sponsor details in Firestore
  void _updateSponsor() async {
    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImageToImageBB(_imageFile!);
    }

    FirebaseFirestore.instance.collection('sponsor').doc(widget.sponsorId).update({
      'name': _nameController.text,
      'interest': _interestController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'imageUrl': imageUrl ?? widget.imageUrl, // Update imageUrl if a new image is selected
    });

    // Navigate back to SponsorPage after saving
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _interestController.text = widget.interest;
    _emailController.text = widget.email;
    _phoneController.text = widget.phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Sponsor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Sponsor Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _interestController,
              decoration: InputDecoration(labelText: 'Interest Areas'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueGrey,
                backgroundImage: _imageFile == null
                    ? (widget.imageUrl.isEmpty ? null : NetworkImage(widget.imageUrl))
                    : FileImage(_imageFile!),
                child: _imageFile == null && widget.imageUrl.isEmpty
                    ? Icon(Icons.add_a_photo, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateSponsor,
              child: Text('Update Sponsor'),
            ),
          ],
        ),
      ),
    );
  }
}


class AddSponsorPage extends StatefulWidget {
  @override
  _AddSponsorPageState createState() => _AddSponsorPageState();
}

class _AddSponsorPageState extends State<AddSponsorPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _imageFile;

  // Image Picker to select an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Upload image to imgbb
  Future<String?> _uploadImageToImageBB(File image) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = imageBBApiKey
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (jsonResponse['status'] == 200) {
        return jsonResponse['data']['url'];  // Return the image URL
      } else {
        print('Failed to upload image: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Error uploading image to imgbb: $e');
      return null;
    }
  }

  // Save sponsor details to Firestore
  void _saveSponsor() async {
    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImageToImageBB(_imageFile!);
    }

    FirebaseFirestore.instance.collection('sponsor').add({
      'name': _nameController.text,
      'interest': _interestController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'imageUrl': imageUrl ?? '', // Store the imgbb URL in Firestore
    });

    // Navigate back to SponsorPage after saving
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Sponsor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Sponsor Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _interestController,
              decoration: InputDecoration(labelText: 'Interest Areas'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueGrey,
                backgroundImage: _imageFile == null
                    ? null
                    : FileImage(_imageFile!),
                child: _imageFile == null
                    ? Icon(Icons.add_a_photo, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSponsor,
              child: Text('Save Sponsor'),
            ),
          ],
        ),
      ),
    );
  }
}
