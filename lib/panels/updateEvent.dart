import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class UpdateEvent extends StatefulWidget {
  final String eventID; // The event ID that we want to update

  UpdateEvent({required this.eventID});

  @override
  _UpdateEventState createState() => _UpdateEventState();
}

class _UpdateEventState extends State<UpdateEvent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _universityShortFormController = TextEditingController();
  DateTime? _selectedDeadline;
  String _selectedCategory = "Educational Events";
  String _selectedCoverage = "National";
  String _imageUrl = "";
  File? _imageFile;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();

  String? _eventTitle;
  String? _eventDescription;
  String? _eventImage;
  DateTime? _eventDeadline;

  @override
  void initState() {
    super.initState();
    _fetchEventData();
  }

  // Fetch event data from Firebase
  Future<void> _fetchEventData() async {
    try {
      final eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventID)
          .get();

      if (eventSnapshot.exists) {
        final eventData = eventSnapshot.data()!;
        _titleController.text = eventData['eventTitle'];
        _descriptionController.text = eventData['eventDescription'];
        _universityShortFormController.text = eventData['universityShortForm'] ?? '';
        _selectedCategory = eventData['eventCategory']; // Automatically set category
        _selectedCoverage = eventData['eventCoverageArea']; // Automatically set coverage area
        _eventImage = eventData['eventImage'];
        _eventDeadline = eventData['registrationDeadline']?.toDate();

        // Set date and time to the deadline controller
        if (_eventDeadline != null) {
          _deadlineController.text = '${_eventDeadline!.toLocal()}';
        }

        // Call setState to refresh the UI with the fetched data
        setState(() {});
      } else {
        // Handle if the event does not exist
        print("Event not found");
      }
    } catch (e) {
      print("Error fetching event data: $e");
    }
  }


  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      // If the image has been changed, upload it and update the image URL
      if (_imageFile != null) {
        _imageUrl = await _uploadImage(_imageFile!);
      } else {
        // Keep the existing image URL if no new image was selected
        _imageUrl = _eventImage ?? '';
      }

      try {
        // Prepare the data to update in the 'events' collection
        final eventData = {
          'eventTitle': _titleController.text,
          'eventDescription': _descriptionController.text,
          'eventCategory': _selectedCategory,
          'eventCoverageArea': _selectedCoverage,
          'eventImage': _imageUrl,
          'registrationDeadline': _selectedDeadline != null
              ? Timestamp.fromDate(_selectedDeadline!)
              : _eventDeadline != null
              ? Timestamp.fromDate(_eventDeadline!)
              : null,
          'universityShortForm': _universityShortFormController.text.isNotEmpty
              ? _universityShortFormController.text
              : null,
        };

        // Update the 'events' collection
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventID)
            .update(eventData);
        //
        // // Prepare the specific fields for the 'eventreg' collection
        // final eventRegData = {
        //   'eventTitle': _titleController.text,
        //   'eventDescription': _descriptionController.text,
        //   'eventCategory': _selectedCategory,
        //   'registrationDeadline': _selectedDeadline != null
        //       ? Timestamp.fromDate(_selectedDeadline!)
        //       : _eventDeadline != null
        //       ? Timestamp.fromDate(_eventDeadline!)
        //       : null,
        // };
        //
        // // Query and update matching documents in the 'eventreg' collection
        // final querySnapshot = await FirebaseFirestore.instance
        //     .collection('eventreg')
        //     .where('eventID', isEqualTo: widget.eventID)
        //     .get();
        //
        // for (var doc in querySnapshot.docs) {
        //   await doc.reference.update(eventRegData);
        // }

        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success!'),
              content: Text('Event Updated Successfully in both collections'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context); // Navigate back after updating
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        // Handle any errors that occur during the update
        print("Error updating event data: $e");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to update event data. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
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








  // Upload image to imgBB
  Future<String> _uploadImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload'),
    );
    request.fields['key'] = '9b0fc2dd74bc6240f21869b39ef5929c';
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final result = json.decode(responseData.body);
    return result['data']['url']; // Extract image URL from the response
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Event'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.text_fields),
                  labelText: 'Event Title',
                  border: OutlineInputBorder( borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.textsms_outlined),
                  labelText: 'Event Description',
                  border: OutlineInputBorder( borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event description';
                  }
                  return null;
                },
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _universityShortFormController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined),
                  labelText: 'University ShortForm',
                  border: OutlineInputBorder( borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_clock),
                  labelText: 'Registration Deadline',
                  border: OutlineInputBorder( borderRadius: BorderRadius.circular(10)),
                ),
                readOnly: true,
                onTap: _pickDateAndTime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the registration deadline';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
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
              SizedBox(height: 14),
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

              SizedBox(height: 20),
              // Display and update image
              GestureDetector(
                onTap: _pickImage, // Allow user to update image on click
                child: _imageFile != null
                    ? Image.file(
                  _imageFile!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : (_eventImage != null && _eventImage!.isNotEmpty)
                    ? Image.network(
                  _eventImage!,
                  height: 150,

                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  height: 150,
                  width: double.infinity,

                  child: Icon(
                    Icons.image,
                    size: 50,
                  ),
                ),
              ),


              SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  // Change this to your desired color
                  foregroundColor: Colors.white,
                  // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        20), // Optional: Rounded corners
                  ),
                ),
                onPressed: _updateEvent,
                child: Text('Update Event',style: TextStyle(fontWeight: FontWeight.bold),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

