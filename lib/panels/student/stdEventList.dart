import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegisteredPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user's email
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    if (currentUserEmail == null) {
      return Center(
        child: Text(
          "Please log in to view your registered events.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Scaffold(

      body: Column(
        children: [
          SizedBox(height: 8,),
          Text("Your Registered Event", style: TextStyle(fontSize: 18,color: Colors.black,fontWeight: FontWeight.w500),),
          Divider(),

          Expanded(child:       StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('eventreg')
                .where('userEmail', isEqualTo: currentUserEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No events found.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                );
              }

              // Get the list of documents
              final registeredEvents = snapshot.data!.docs;

              return ListView.builder(
                itemCount: registeredEvents.length,
                itemBuilder: (context, index) {
                  final event = registeredEvents[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Event Title
                              Text(
                                event['eventTitle'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 5),

                              // Event Details
                              Text("Category: ${event['eventCategory']}"),
                              // const SizedBox(height: 5),
                              Text("Organization: ${event['organizationName']}"),
                              // const SizedBox(height: 5),
                              Text(
                                "Deadline: ${DateFormat('dd/MM/yyyy, h:mm a').format(event['registrationDeadline'].toDate())}",
                                style: TextStyle(fontSize: 14), // Optional: adjust the style as needed
                              ),
                              // const SizedBox(height: 5),
                              Text("University: ${event['universityShortForm']}"),

                              const SizedBox(height: 8),

                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [

                                  IconButton(
                                    onPressed: () async {
                                      // Show confirmation dialog
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Delete'),
                                            content: const Text('Are you sure you want to delete this event?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context); // Close the confirmation dialog
                                                },
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.pop(context); // Close the confirmation dialog

                                                  // Perform the deletion
                                                  await FirebaseFirestore.instance
                                                      .collection('eventreg')
                                                      .doc(event.id)
                                                      .delete();

                                                  // Show success dialog
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text('Success'),
                                                        content: const Text(
                                                          'Event record deleted successfully!',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(context).pop(); // Close the success dialog
                                                            },
                                                            child: const Text('OK'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      size: 30,
                                      color: Colors.red,
                                    ),
                                  ),

                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Show dialog with event details
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(event['eventTitle']),
                                            content: Text(
                                              "Description: ${event['eventDescription']}",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context); // Close dialog
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('Details',style: TextStyle(fontSize: 12),),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),)
        ],
      )

    );
  }
}
