import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nex_event_app/panels/student/homeEvent.dart';

class UserSpecificEventsPage extends StatefulWidget {
  @override
  _UserSpecificEventsPageState createState() => _UserSpecificEventsPageState();
}

class _UserSpecificEventsPageState extends State<UserSpecificEventsPage> {
  late Stream<QuerySnapshot> eventStream;
  String? userUniversity;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserUniversity();
  }

  Future<void> fetchCurrentUserUniversity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final email = user.email;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (userDoc.docs.isNotEmpty) {
          setState(() {
            userUniversity = userDoc.docs.first['university'];
            eventStream = FirebaseFirestore.instance
                .collection('events')
                .where('universityShortForm', isEqualTo: userUniversity)
                .snapshots();
          });
        }
      }
    } catch (e) {
      print('Error fetching user university: $e');
    }
  }

  Future<bool> _loadImage(String imageUrl) async {
    try {
      await NetworkImage(imageUrl).resolve(ImageConfiguration());
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userUniversity == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: eventStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          var events = snapshot.data!.docs;

          return ListView.builder(
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
                          EventDetailsPage(event: event), // Update this to your event details page
                    ),
                  );
                },
                child: Container(
                  child: Card(
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
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (snapshot.hasData &&
                                            snapshot.data == true) {
                                          return Image.network(
                                            event['eventImage'],
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          return Image.asset(
                                            'assets/defaultEvent.png',
                                            fit: BoxFit.cover,
                                          );
                                        }
                                      } else {
                                        return Container(
                                          width: 20,
                                          height: 100,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text('Deadline: $deadlineDate'),
                                    Text('Org: ${event['organizationName']}'),
                                    Text('Area: ${event['eventCoverageArea']}'),
                                    Text(
                                        'University: ${event['universityShortForm']}'),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
