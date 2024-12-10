import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrganizationPage extends StatefulWidget {
  @override
  _OrganizationPageState createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); // Search controller
  final TextEditingController _facebookLinkController = TextEditingController(); // Added field
  String _selectedOrgType = 'NGO'; // Default selection
  String _searchQuery = '';
  File? _selectedImageFile; // Variable to store the selected image

  final List<String> _orgTypes = ['NGO', 'Govt', 'University Clubs', 'NonProfit', 'Others'];

  Future<void> _deleteOrganization(String id) async {
    // Show confirmation dialog before deleting
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this organization?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User selected 'No'
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User selected 'Yes'
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      // If confirmed, delete the organization
      await FirebaseFirestore.instance.collection('organization').doc(id).delete();
      // Optionally, you can show a message or update UI here if needed.
    }
  }


  // Method to handle image selection
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Organization',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase(); // Set search query to filter
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('organization').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No organizations added yet."));
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = docs.where((doc) {
                  final name = doc['name'].toLowerCase();
                  return name.contains(_searchQuery); // Filter organizations by name
                }).toList();

                return GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2 / 3,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index];
                    return Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              data['logo'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          ListTile(
                            title: Text(data['name']),
                            subtitle: Text(data['contact']),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _navigateToUpdatePage(context, data),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteOrganization(data.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUpdatePage(BuildContext context, QueryDocumentSnapshot data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateOrganizationPage(organizationData: data),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    // Reset the form controllers and image when opening the dialog
    _nameController.clear();
    _contactController.clear();
    _emailController.clear();
    _facebookLinkController.clear();
    setState(() {
      _selectedImageFile = null; // Clear the selected image
      _selectedOrgType = 'NGO'; // Default dropdown value
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Organization"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage, // Image picker
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: _selectedImageFile == null
                        ? Icon(Icons.add_a_photo, size: 50)
                        : Image.file(_selectedImageFile!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Organization Name'),
                  validator: (value) => value!.isEmpty ? 'Enter organization name' : null,
                ),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(labelText: 'Contact Number'),
                  validator: (value) => value!.isEmpty ? 'Enter contact number' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Enter email address' : null,
                ),
                TextFormField(
                  controller: _facebookLinkController,
                  decoration: InputDecoration(labelText: 'Facebook/Website Link'),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedOrgType,
                  items: _orgTypes.map((String orgType) {
                    return DropdownMenuItem<String>(
                      value: orgType,
                      child: Text(orgType),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedOrgType = newValue!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Organization Type'),
                  validator: (value) => value == null ? 'Select an organization type' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (_selectedImageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select an image!')),
                  );
                  return;
                }
                // Image upload logic
                String? imageUrl = await _uploadImageToImageBB(_selectedImageFile!);
                if (imageUrl != null) {
                  await FirebaseFirestore.instance.collection('organization').add({
                    'name': _nameController.text.trim(),
                    'contact': _contactController.text.trim(),
                    'email': _emailController.text.trim(),
                    'facebookLink': _facebookLinkController.text.trim(),
                    'organizationType': _selectedOrgType,
                    'logo': imageUrl,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Organization added successfully!')),
                  );
                  Navigator.pop(context); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Image upload failed!')),
                  );
                }
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadImageToImageBB(File image) async {
    try {
      final url = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['key'] = '9b0fc2dd74bc6240f21869b39ef5929c'
        ..files.add(await http.MultipartFile.fromPath('image', image.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = jsonDecode(await response.stream.bytesToString());
        return responseData['data']['url'];
      }
    } catch (e) {
      print('Image upload failed: $e');
    }
    return null;
  }
}


class UpdateOrganizationPage extends StatefulWidget {
  final QueryDocumentSnapshot organizationData;
  UpdateOrganizationPage({required this.organizationData});

  @override
  _UpdateOrganizationPageState createState() =>
      _UpdateOrganizationPageState();
}

class _UpdateOrganizationPageState extends State<UpdateOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _facebookLinkController = TextEditingController(); // Added field
  File? _updatedImageFile;
  String existingImageUrl = '';
  String _selectedOrgType = 'NGO'; // Default selection

  final List<String> _orgTypes = ['NGO', 'Govt', 'University Clubs', 'NonProfit', 'Others'];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.organizationData['name'];
    _contactController.text = widget.organizationData['contact'];
    _emailController.text = widget.organizationData['email'];
    _facebookLinkController.text = widget.organizationData['facebookLink'] ?? ''; // Handle existing field
    existingImageUrl = widget.organizationData['logo'];
    _selectedOrgType = widget.organizationData['organizationType'] ?? 'NGO';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Organization')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: _updatedImageFile == null
                        ? existingImageUrl.isEmpty
                        ? Icon(Icons.add_a_photo, size: 50)
                        : Image.network(existingImageUrl, fit: BoxFit.cover)
                        : Image.file(_updatedImageFile!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Organization Name'),
                  validator: (value) => value!.isEmpty ? 'Enter organization name' : null,
                ),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(labelText: 'Contact Number'),
                  validator: (value) => value!.isEmpty ? 'Enter contact number' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Enter email address' : null,
                ),
                TextFormField(
                  controller: _facebookLinkController,
                  decoration: InputDecoration(labelText: 'Facebook/Website Link'),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedOrgType,
                  items: _orgTypes.map((String orgType) {
                    return DropdownMenuItem<String>(
                      value: orgType,
                      child: Text(orgType),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedOrgType = newValue!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Organization Type'),
                  validator: (value) => value == null ? 'Select an organization type' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String? imageUrl = existingImageUrl;
                      if (_updatedImageFile != null) {
                        imageUrl = await _uploadImageToImageBB(_updatedImageFile!);
                      }
                      if (imageUrl != null) {
                        await FirebaseFirestore.instance.collection('organization').doc(widget.organizationData.id).update({
                          'name': _nameController.text.trim(),
                          'contact': _contactController.text.trim(),
                          'email': _emailController.text.trim(),
                          'facebookLink': _facebookLinkController.text.trim(),
                          'organizationType': _selectedOrgType,
                          'logo': imageUrl,
                        });
        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Organization updated successfully!')),
                        );
                        Navigator.pop(context); // Close the update page
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Image upload failed!')),
                        );
                      }
                    }
                  },
                  child: Text('Update Organization'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _updatedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToImageBB(File image) async {
    try {
      final url = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['key'] = '9b0fc2dd74bc6240f21869b39ef5929c'
        ..files.add(await http.MultipartFile.fromPath('image', image.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = jsonDecode(await response.stream.bytesToString());
        return responseData['data']['url'];
      }
    } catch (e) {
      print('Image upload failed: $e');
    }
    return null;
  }
}

