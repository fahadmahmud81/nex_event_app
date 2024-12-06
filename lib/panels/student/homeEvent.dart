import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      event['eventImage'],
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
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
    final deadlineDateTime = DateFormat('MMMM d, yyyy, hh:mm a')
        .format(deadlineTimestamp.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text(event['eventTitle']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(event['eventImage'], fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20),
            Text('Title: ${event['eventTitle']}'),

            Text('Description:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(event['eventDescription']),
            Text('Org: ${event['organizationName']}'),
            Text('Category: ${event['eventCategory']}'),
            Text('Area: ${event['eventCoverageArea']}'),
            Text('University: ${event['universityShortForm']}'),
            SizedBox(height: 20),
            Text('Registration Deadline:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(deadlineDateTime),
            SizedBox(height: 20),
            Container(
              height: 30,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(40),backgroundColor: Colors.lightBlue),
                child: Text('Register',style: TextStyle(color: Colors.white),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
