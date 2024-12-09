import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticePage extends StatelessWidget {
  final String contactEmail = "inspiretech.bdu@gmail.com";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Marquee at the top
          GestureDetector(
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: contactEmail,
              );

              try {
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                } else {
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text("No email app found."),
                  //   ),
                  // );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error opening email app: $e"),
                  ),
                );
              }
            },
            child: Container(
              color: Colors.blueAccent,
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Contact: $contactEmail",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notice').snapshots(),
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
                  children: [
                    // Priority Notices
                    if (superAdminNotices.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Priority Notices",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...superAdminNotices.map((doc) {
                        return _buildNoticeCard(context, doc, isPriority: true);
                      }).toList(),
                    ],
                    // Regular Notices
                    if (regularNotices.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Regular Notices",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...regularNotices.map((doc) {
                        return _buildNoticeCard(context, doc, isPriority: false);
                      }).toList(),
                    ],
                    // Ads Section
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Center(
                          child: Text(
                            "Your Ad Here",
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
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

  Widget _buildNoticeCard(BuildContext context, DocumentSnapshot doc, {bool isPriority = false}) {
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

  void _showNoticeDetails(BuildContext context, String title, String? description) {
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
