import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:nex_event_app/panels/updateEvent.dart';

//admin Home EventsPage ,fms, and Create Event Logic is here



class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final CollectionReference eventsCollection =
  FirebaseFirestore.instance.collection('events');
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final User? user = auth.currentUser;
    if (user != null) {
      setState(() {
        currentUserEmail = user.email;
      });
    }
    _deleteExpiredEvents();
  }

  Future<void> _deleteExpiredEvents() async {
    if (currentUserEmail == null) return;

    final now = Timestamp.now();
    final querySnapshot = await eventsCollection
        .where('adminEmail', isEqualTo: currentUserEmail)
        .where('registrationDeadline', isLessThan: now)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteEvent(String id) async {
    await eventsCollection.doc(id).delete();
    Get.snackbar("Success", "Event deleted successfully",
        snackPosition: SnackPosition.TOP);
  }

  void _updateEvent(Map<String, dynamic> eventData, String docId) {
    Get.to(() => UpdateEvent(eventID: docId), arguments: {
      'eventData': eventData,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentUserEmail == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: eventsCollection
            .where('adminEmail', isEqualTo: currentUserEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No events available.'));
          }
          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index].data() as Map<String, dynamic>;
              final docId = events[index].id;

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  title: Text(
                    event['eventTitle'] ?? 'No Title',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Organization: ${event['organizationName'] ?? 'Unknown'}\n'
                        'Category: ${event['eventCategory'] ?? 'None'}\n'
                        'Deadline: ${(event['registrationDeadline'] as Timestamp).toDate()}',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _updateEvent(event, docId);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteEvent(docId);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => CreateEvent());
        },
        child: Icon(Icons.add),
        tooltip: 'Add Event',
      ),
    );
  }
}

class CreateEvent extends StatefulWidget {
  @override
  _CreateEventState createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _universityShortFormController =
      TextEditingController();
  DateTime? _selectedDeadline;
  String _selectedCategory = "Educational Events";
  String _selectedCoverage = "National";
  String _imageUrl = "";
  File? _imageFile;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();


  // Pick image for event banner
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
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  // Upload image to imgBB
  Future<String> _uploadImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload'),
    );
    request.fields['key'] = '9b0fc2dd74bc6240f21869b39ef5929c';
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final result = json.decode(responseData.body);
    return result['data']['url']; // Extract image URL from the response
  }

  Future<void> _pickDateAndTime() async {
    // Pick date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // Pick time
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          // Combine date and time
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _deadlineController.text =
              '${_selectedDeadline!.toLocal()}'; // Set the deadline input field text
        });
      }
    }
  }

  String? _organizationName; // To store the fetched organization name
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchUserEmailAndOrg();

 // Fetch user information on initialization
  }

  Future<void> _fetchUserEmailAndOrg() async {
    try {
      // Get the current user's email
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final email = user.email;

        setState(() {
          _email = email; // Set the email state
        });

        // Fetch user's organization information from Firestore
        final querySnapshot = await FirebaseFirestore.instance
            .collection('adminorg')
            .where('email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          setState(() {
            _organizationName = data['organizationName']; // Set organization name
          });
        } else {
          setState(() {
            _organizationName = 'Not Found';
          });
        }
      }
    } catch (e) {
      print("Error fetching user email or organization: $e");
    }
  }





  Future<void> _addEvent() async {
    if (_formKey.currentState!.validate()) {
      // Check for duplicate events based on title, organization, and category
      final querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('eventTitle', isEqualTo: _titleController.text)
          .where('organizationName',
              isEqualTo: _organizationName) // Check for the organization name
          .where('eventCategory', isEqualTo: _selectedCategory)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Show duplicate event alert
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Duplicate Event'),
              content: Text(
                  'An event with this title and organization already exists.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Proceed with adding the event
        if (_imageFile != null) {
          _imageUrl = await _uploadImage(_imageFile!);
        }

        String eventID = DateTime.now().millisecondsSinceEpoch.toString();
        final eventData = {
          'universityShortForm': _universityShortFormController.text.isNotEmpty
              ? _universityShortFormController.text
              : null,
          'eventCategory': _selectedCategory,
          'eventCoverageArea': _selectedCoverage,
          'adminEmail': _email,
          // Use the fetched email
          'organizationName': _organizationName,
          // Use the fetched organization name
          'eventID': eventID,
          'eventTitle': _titleController.text,
          'eventDescription': _descriptionController.text,
          'eventImage': _imageUrl,
          'registrationDeadline': _selectedDeadline != null
              ? Timestamp.fromDate(_selectedDeadline!)
              : null,
        };

        await FirebaseFirestore.instance.collection('events').add(eventData);

        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success!'),
              content: Text('Event Added Successfully'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Event'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event title';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 14,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Event Description',
                  border:
                      OutlineInputBorder(), // Adds a border around the text field
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event description';
                  }
                  return null;
                },
                maxLines: 5,
                // Allows the TextFormField to grow to 5 lines
                keyboardType: TextInputType.multiline,
                // Enables multiline input
                textInputAction: TextInputAction
                    .newline, // Allows the user to add new lines easily
              ),
              SizedBox(
                height: 14,
              ),
              Text("Admin Email: ${_email}"),
              SizedBox(
                height: 14,
              ),
              Text("Organization Name: ${_organizationName}"),
              SizedBox(
                height: 14,
              ),
              TextFormField(
                controller: _universityShortFormController,
                decoration: InputDecoration(
                  labelText: 'University ShortForm (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(
                height: 14,
              ),
              TextFormField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  labelText: 'Registration Deadline',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                // Makes the field non-editable
                onTap: _pickDateAndTime,
                // Open the date and time picker
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the registration deadline';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 20,
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Event Category'),
                items: [
                  'Educational Events',
                  'Competitions',
                  'IT contest',
                  'Training Programs',
                  'Cultural and Arts Event',
                  'Study Abroad Events',
                  'Career and Networking Event',
                  'Sports and Recreational Event',
                  'Community and Fundraising Event',
                  'Government Drives and Events',
                  'Religious Events',
                  'Tech and Innovation Events',
                  'Tourism Events',
                ]
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCoverage,
                decoration: InputDecoration(labelText: 'Event Coverage Area'),
                items: [
                  'National',
                  'Specific Area',
                  'International',
                  'Institute Only',
                ]
                    .map((coverage) => DropdownMenuItem<String>(
                          value: coverage,
                          child: Text(coverage),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCoverage = value!;
                  });
                },
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  color: Colors.grey[300],
                  height: 150,
                  width: double.infinity,
                  child: _imageFile == null
                      ? Center(child: Text('Tap to Select Banner Image'))
                      : Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addEvent,
                child: Text('Add Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
