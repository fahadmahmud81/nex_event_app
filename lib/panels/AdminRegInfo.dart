import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationInfoPage extends StatefulWidget {
  @override
  _RegistrationInfoPageState createState() => _RegistrationInfoPageState();
}

class _RegistrationInfoPageState extends State<RegistrationInfoPage> {
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await _getAdminEvents();
      final uniqueData = _getUniqueEvents(data);
      setState(() {
        events = uniqueData;
      });
    } catch (e) {
      print("Error loading events: $e");
    }
  }

  void _removeEventFromPage(int index) {
    setState(() {
      events.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Event Management"),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: events.isEmpty
          ? Center(child: Text("No events found."))
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final deadline =
                    (event['registrationDeadline'] as Timestamp).toDate();
                final hasDeadlinePassed = DateTime.now().isAfter(deadline);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserListPage(event: event),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.all(10),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['eventTitle'] ?? "Untitled Event",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                              "Category: ${event['eventCategory'] ?? 'Unknown'}"),
                          Text("Deadline: ${deadline.toLocal()}"),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (hasDeadlinePassed)
                                ElevatedButton(
                                  onPressed: () => _removeEventFromPage(index),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: Text("Delete Event",style: TextStyle(color: Colors.white),),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Fetches events created by the current admin from Firestore.
  Future<List<Map<String, dynamic>>> _getAdminEvents() async {
    try {
      // Get the current user's email
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user is signed in.");
      }
      final email = user.email;

      // Query Firestore for events created by the admin
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventreg')
          .where('adminEmail', isEqualTo: email)
          .get();

      // Extract event details
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Store the document ID for potential future use
        return data;
      }).toList();
    } catch (e) {
      throw Exception("Failed to load events: $e");
    }
  }

  /// Removes duplicate events based on the event title.
  List<Map<String, dynamic>> _getUniqueEvents(
      List<Map<String, dynamic>> events) {
    final seenTitles = Set<String>();
    return events.where((event) {
      final eventTitle = event['eventTitle'] ?? '';
      if (seenTitles.contains(eventTitle)) {
        return false; // Skip duplicate events
      } else {
        seenTitles.add(eventTitle);
        return true; // Keep unique event
      }
    }).toList();
  }
}

class UserListPage extends StatelessWidget {
  final Map<String, dynamic> event;

  UserListPage({required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event['eventTitle'] ?? "Event Details",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getEventUsers(event['eventID'] ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No users registered for this event."));
          } else {
            final userData = snapshot.data!;
            return ListView.builder(
              itemCount: userData.length,
              itemBuilder: (context, index) {
                final user = userData[index];
                return ListTile(
                  leading: CircleAvatar(child: Text((index + 1).toString())),
                  title: Text(user['name'] ?? 'Unknown Name'),
                  subtitle: Text(
                    "${user['university'] ?? 'Unknown University'}\n${user['email'] ?? 'Unknown Email'}",
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  /// Fetches all users' details for the given event ID.
  Future<List<Map<String, dynamic>>> _getEventUsers(String eventID) async {
    try {
      // Fetch all emails registered for the event
      final eventQuerySnapshot = await FirebaseFirestore.instance
          .collection('eventreg')
          .where('eventID', isEqualTo: eventID)
          .get();

      final userEmails = eventQuerySnapshot.docs
          .map((doc) => doc['userEmail'] as String)
          .toList();

      // Fetch user details from the 'users' collection
      List<Map<String, dynamic>> userDetails = [];
      for (final email in userEmails) {
        final userQuerySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (userQuerySnapshot.docs.isNotEmpty) {
          userDetails.add(userQuerySnapshot.docs.first.data());
        } else {
          userDetails.add(
              {'email': email, 'name': 'Unknown', 'university': 'Unknown'});
        }
      }

      return userDetails;
    } catch (e) {
      throw Exception("Failed to load user details: $e");
    }
  }
}
