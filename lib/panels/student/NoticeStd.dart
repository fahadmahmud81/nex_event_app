import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marquee/marquee.dart';

class NoticePage extends StatelessWidget {
  final String contactEmail = "inspiretech.bdu@gmail.com";

  @override
  Widget build(BuildContext context) {
    void _launchURL() async {
      final Uri url = Uri.parse('https://club-master-cc804.web.app/');
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    }
    void _launchEmail() async {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'inspiretech.bdu@gmail.com', // Replace with the recipient's email
        query: 'subject=NexEvent&body=Describe Your Queries Here.', // Replace with your email content
      );

      if (!await launchUrl(emailUri)) {
        throw 'Could not launch $emailUri';
      }
    }

    return Scaffold(
      body: Column(
        children: [
          // Marquee at the top
          TextButton(
           onPressed: (){
             _launchEmail();
           },
            child: Container(
              width: double.infinity,
              color: Colors.blueAccent,
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Contact: $contactEmail",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('notice').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                // Separate notices based on priority
                final notices = snapshot.data!.docs;
                final superAdminNotices = notices
                    .where((doc) => doc['NoticeType'] == 'SuperAdmin')
                    .toList();
                final regularNotices = notices
                    .where((doc) => doc['NoticeType'] != 'SuperAdmin')
                    .toList();

                return ListView(
                  children: <Widget>[
                    // Priority Notices
                    if (superAdminNotices.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8,horizontal: 16),
                        child: Text(
                          "Priority Notices",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...superAdminNotices.map((doc) {
                        return _buildNoticeCard(context, doc, isPriority: true);
                      }).toList(),
                    ],
                    // Regular Notices
                    if (regularNotices.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8,horizontal: 16),
                        child: Text(
                          "Regular Notices",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...regularNotices.map((doc) {
                        return _buildNoticeCard(context, doc,
                            isPriority: false);
                      }).toList(),
                    ],
                    // Ads Section
                    SizedBox(height: 16),
                    Container(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20), // Adjust the value for the desired roundness
                        child: Image.network(
                          "https://miro.medium.com/v2/resize:fit:1400/0*OckilgOyByn-x242.gif",
                          fit: BoxFit.cover, // Ensures the image covers the entire container
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Checkout Our Recent Project:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          ElevatedButton(
                              onPressed: () {
                                _launchURL();
                              },
                              child: Text(
                                "ClubSync",
                                style: TextStyle(fontSize: 16),
                              )),
                          // SizedBox(height: 30,),
                          // Text("Today's Update:"),
                          // SizedBox(
                          //   height: 30, // Height of the marquee widget
                          //   child: Marquee(
                          //     text: 'This is a scrolling marquee text. Add any long content here!',
                          //     style: const TextStyle(fontSize: 14, color: Colors.black),
                          //     scrollAxis: Axis.horizontal, // Scroll horizontally
                          //     crossAxisAlignment: CrossAxisAlignment.center,
                          //     blankSpace: 20.0, // Space between repetitions
                          //     velocity: 100.0, // Speed of the marquee
                          //     pauseAfterRound: Duration(seconds: 1), // Pause after each scroll round
                          //     startPadding: 10.0, // Padding before starting the scroll
                          //     accelerationDuration: Duration(seconds: 1), // Acceleration time
                          //     accelerationCurve: Curves.linear, // Acceleration curve
                          //     decelerationDuration: Duration(milliseconds: 500), // Deceleration time
                          //     decelerationCurve: Curves.easeOut, // Deceleration curve
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, DocumentSnapshot doc,
      {bool isPriority = false}) {
    final title = doc['Title'] ?? "No Title";
    final date = doc['Date'] ?? "No Date";
    final bgColor = isPriority ? Colors.blue[100] : Colors.white;
    final borderColor = isPriority ? Colors.blueAccent : Colors.grey;

    return GestureDetector(
      onTap: () => _showNoticeDetails(context, title, doc['Description']),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Card(
          elevation: isPriority ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor!, width: isPriority ? 2 : 1),
          ),
          color: bgColor,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Date: $date",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoticeDetails(
      BuildContext context, String title, String? description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            description ?? "No Description Available",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
