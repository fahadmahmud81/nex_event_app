import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user's email

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = [
    'All',
    'Educational Events',
    'Tech and Innovation Events',
    'Competitions',
    'IT Contest',
    'Training Programs',
    'Cultural and Arts Event',
    'Study Abroad Events',
    'Career and Networking Event',
    'Sports and Recreational Event',
    'Community and Fundraising Event',
    'Government Drives and Events',
    'Religious Events',
    'Tourism Events',
  ];

  final List<String> bannerImages = [
    'https://i.imgur.com/1vOifiN.png',
    'https://i.imgur.com/lsx4Sjy.png',
    'https://i.imgur.com/ao4FFHe.png',
  ];

  String selectedCategory = 'All';
  late Stream<QuerySnapshot> eventStream;

  @override
  void initState() {
    super.initState();
    eventStream = FirebaseFirestore.instance.collection('events').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> _loadImage(String imageUrl) async {
      try {
        await NetworkImage(imageUrl).resolve(ImageConfiguration());
        return true;
      } catch (e) {
        return false;
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Row
            Container(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = categories[index];
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Chip(
                        label: Text(
                          categories[index],
                          style: TextStyle(
                            color: selectedCategory == categories[index]
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        backgroundColor: selectedCategory == categories[index]
                            ? Colors.blue
                            : Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 5),
            // Banner Carousel
            Container(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: bannerImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(bannerImages[index],
                          fit: BoxFit.cover, width: 300),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            // Events List
            StreamBuilder<QuerySnapshot>(
              stream: eventStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var events = snapshot.data!.docs;

                if (selectedCategory != 'All') {
                  events = events.where((event) {
                    return event['eventCategory'] == selectedCategory;
                  }).toList();
                }

                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final deadlineTimestamp = event['registrationDeadline'];
                    final deadlineDate = DateFormat('MMMM d, yyyy')
                        .format(deadlineTimestamp.toDate());

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventDetailsPage(event: event),
                          ),
                        );
                      },
                      child:
                      Card(
                        margin: EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 10),
                                  Container(
                                      height: 100,
                                      width: 100,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: FutureBuilder(
                                          future: _loadImage(event['eventImage']),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.done) {
                                              // Check if the image was loaded successfully
                                              if (snapshot.hasData && snapshot.data == true) {
                                                return Image.network(
                                                  event['eventImage'],
                                                  fit: BoxFit.cover,
                                                  // width: 100,
                                                  // height: 100,
                                                );
                                              } else {
                                                return Image.asset('assets/defaultEvent.png', fit: BoxFit.cover);
                                              }
                                            } else {
                                              // Show the loader while the image is being fetched
                                              return Container(
                                                width: 20,
                                                height: 100,
                                                child: Center(child: CircularProgressIndicator()),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),


                                  SizedBox(width: 25),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event['eventTitle'],
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text('Deadline: $deadlineDate'),
                                        Text('Org: ${event['organizationName']}'),
                                        Text('Area: ${event['eventCoverageArea']}'),
                                        Text('University: ${event['universityShortForm']}'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),

                            ],
                          ),
                        ),
                      ),



                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot event;

  EventDetailsPage({required this.event});

  @override
  Widget build(BuildContext context) {
    final deadlineTimestamp = event['registrationDeadline'];
    final deadlineDateTime =
    DateFormat('MMMM d, yyyy, hh:mm a').format(deadlineTimestamp.toDate());

    void _registerForEvent(BuildContext context) async {
      // Get current user's email
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

      if (currentUserEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please log in to register for events.")),
        );
        return;
      }

      try {
        // Check if the user is already registered for this event
        final querySnapshot = await FirebaseFirestore.instance
            .collection('eventreg')
            .where('eventID', isEqualTo: event['eventID'])
            .where('userEmail', isEqualTo: currentUserEmail)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // If a record already exists, show an alert dialog
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Already Registered"),
                content: Text(
                    "You are already registered for this event. Check your Registrations page."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Close dialog
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
          return;
        }

        // If no record exists, proceed with registration
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Register for Event"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Event Title: ${event['eventTitle']}"),
                  Text("Event ID: ${event['eventID']}"),
                  Text("University Short Form: ${event['universityShortForm']}"),
                  Text("Category: ${event['eventCategory']}"),
                  Text("Organization Name: ${event['organizationName']}"),
                  Text("Registration Deadline: $deadlineDateTime"),
                  SizedBox(height: 10),
                  Text("Your Email: $currentUserEmail"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), // Close dialog
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Save the registration details to Firestore
                    await FirebaseFirestore.instance.collection('eventreg').add({
                      'eventTitle': event['eventTitle'],
                      'eventDescription': event['eventDescription'],
                      'eventID': event['eventID'],
                      'eventCategory': event['eventCategory'],
                      'adminEmail': event['adminEmail'],
                      'registrationDeadline': event['registrationDeadline'],
                      'userEmail': currentUserEmail,
                      'universityShortForm': event['universityShortForm'],
                      'organizationName': event['organizationName'],
                      'registrationTime': Timestamp.now(),
                    });

                    Navigator.pop(context); // Close the dialog

                    // Show success message
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Success'),
                          content: Text('Event Registration Successful!'),
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
                  },
                  child: Text("Confirm Registration"),
                ),
              ],
            );
          },
        );
      } catch (e) {
        // Handle any errors during the registration process
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred. Please try again later.")),
        );
      }
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(event['eventTitle']),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                      height: 200,
                      width: 500,
                      child:
                      Image.network(event['eventImage'], fit: BoxFit.cover)),
                ),
              ),
              SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Title: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: '${event['eventTitle']}',
                      style: TextStyle(
                          fontWeight: FontWeight.w400, color: Colors.black),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5),
              Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(event['eventDescription']),
              Divider(),
              Text('Org: ${event['organizationName']}'),
              Text('Category: ${event['eventCategory']}'),
              Text('Area: ${event['eventCoverageArea']}'),
              Text('University: ${event['universityShortForm']}'),
              SizedBox(height: 20),
              Divider(),
              Text('Registration Deadline:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(deadlineDateTime),
              SizedBox(height: 30),
              Container(
                height: 35,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _registerForEvent(context),
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(40),
                      backgroundColor: Colors.lightBlue),
                  child: Text(
                    'Register',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}