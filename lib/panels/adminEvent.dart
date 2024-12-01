import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  // Sample data for events (this can be fetched from Firebase or any backend)
  List<Map<String, String>> events = [
    {
      'name': 'Tech Talk 2024',
      'date': '2024-12-10',
      'description': 'A session on the latest trends in technology.',
    },
    {
      'name': 'Flutter Workshop',
      'date': '2024-12-15',
      'description': 'A hands-on workshop on Flutter development.',
    },
    // Add more events here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              contentPadding: EdgeInsets.all(10),
              title: Text(
                events[index]['name']!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Date: ${events[index]['date']}\nDescription: ${events[index]['description']}',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                // Handle event tap (e.g., show event details or manage event)
              },
            ),
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
  final TextEditingController _universityShortFormController = TextEditingController();
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
          _deadlineController.text = '${_selectedDeadline!.toLocal()}'; // Set the deadline input field text
        });
      }
    }
  }


  // Save event data to Firebase Firestore
  // Save event data to Firebase Firestore
  Future<void> _addEvent() async {
    if (_formKey.currentState!.validate()) {
      // Check for duplicate events based on title, organization, and category
      final querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('eventTitle', isEqualTo: _titleController.text)
          .where('organizationName', isEqualTo: _organizationController.text)
          .where('eventCategory', isEqualTo: _selectedCategory)
          .where('eventDescription', isEqualTo: _descriptionController.text)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If a duplicate is found
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Duplicate Event'),
              content: Text('An event with this title, organization, and category already exists.'),
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
      } else {
        // Upload image to imgBB and get the URL
        if (_imageFile != null) {
          _imageUrl = await _uploadImage(_imageFile!);
        }

        // Generate unique eventID
        String eventID = DateTime.now().millisecondsSinceEpoch.toString();

        // Create event data
        final eventData = {
          'universityShortForm': _universityShortFormController.text.isNotEmpty
              ? _universityShortFormController.text
              : null, // Example, you can change this
          'eventCategory': _selectedCategory,
          'eventCoverageArea': _selectedCoverage,
          'adminEmail': _emailController.text,
          'eventID': eventID,
          'eventTitle': _titleController.text,
          'eventDescription': _descriptionController.text,
          'eventImage': _imageUrl,
          'organizationName': _organizationController.text,
          'registrationDeadline': _selectedDeadline != null
              ? Timestamp.fromDate(_selectedDeadline!)
              : null,
        };

        // Add event data to Firestore
        await FirebaseFirestore.instance.collection('events').add(eventData);

        // Show confirmation dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success!'),
              content: Text('Event Added Successfully'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.pop(context); // Optionally, go back after success
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
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Admin Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Check if the email is empty
                  if (value == null || value.isEmpty) {
                    return 'Please enter the admin email';
                  }

                  // Regular expression for validating an email
                  String pattern =
                      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b';
                  RegExp regExp = RegExp(pattern);

                  // Check if the email matches the regular expression
                  if (!regExp.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }

                  return null;
                },
              ),
              SizedBox(
                height: 14,
              ),
              TextFormField(
                controller: _organizationController,
                decoration: InputDecoration(
                  labelText: 'Organization Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the organization name';
                  }
                  return null;
                },
              ),
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
                decoration: InputDecoration(labelText: 'Registration Deadline',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,  // Makes the field non-editable
                onTap: _pickDateAndTime,  // Open the date and time picker
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the registration deadline';
                  }
                  return null;
                },
              ),


              SizedBox(height: 20,),
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
