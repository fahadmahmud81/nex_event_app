
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SponsorsPage extends StatefulWidget {
  @override
  _SponsorsPageState createState() => _SponsorsPageState();
}

class _SponsorsPageState extends State<SponsorsPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Listen for changes in the search box
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  // Function to launch email
  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email, // Replace with the recipient's email
      query: 'subject=Your Topic&body=Describe Your Queries Here.', // Replace with your email content
    );

    if (!await launchUrl(emailUri)) {
      throw 'Could not launch $emailUri';
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Search Sponsors by Name or Interest',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            // Sponsor List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('sponsor').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No sponsors available.'));
                  }

                  var sponsorDocs = snapshot.data!.docs;

                  // Filter sponsors based on the search query
                  var filteredSponsors = sponsorDocs.where((sponsorDoc) {
                    var sponsor = sponsorDoc.data() as Map<String, dynamic>;
                    String name = sponsor['name'] ?? '';
                    String interest = sponsor['interest'] ?? '';
                    return name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        interest.toLowerCase().contains(searchQuery.toLowerCase());
                  }).toList();

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredSponsors.length,
                    itemBuilder: (context, index) {
                      var sponsor = filteredSponsors[index].data() as Map<String, dynamic>;

                      return Container(
                        height: 300, // Set your desired height here
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Get the width of the current card for responsive adjustments
                              double cardWidth = constraints.maxWidth;

                              return Padding(
                                padding: EdgeInsets.all(cardWidth * 0.04), // Scaled padding
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Sponsor Image in a Circle Avatar
                                    CircleAvatar(
                                      radius: cardWidth * 0.2, // Scaled radius
                                      backgroundImage: NetworkImage(sponsor['imageUrl'] ?? ''),
                                      child: sponsor['imageUrl'] == null
                                          ? Icon(Icons.business, color: Colors.white, size: cardWidth * 0.1)
                                          : null,
                                    ),
                                    SizedBox(height: cardWidth * 0.05), // Scaled spacing
                                    // Sponsor Name
                                    Text(
                                      sponsor['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: cardWidth * 0.06, // Scaled font size
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: cardWidth * 0.02),
                                    // Sponsor Phone
                                    GestureDetector(
                                      onTap: () => _launchPhone(sponsor['phone'] ?? ''),
                                      child: Text(
                                        sponsor['phone'] ?? '',
                                        style: TextStyle(fontSize: cardWidth * 0.06),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: cardWidth * 0.02),
                                    // Sponsor Interest
                                    Text(
                                      sponsor['interest'] ?? '',
                                      style: TextStyle(
                                        fontSize: cardWidth * 0.05,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: cardWidth * 0.02),
                                    // Sponsor Email with clickable functionality
                                    InkWell(
                                      onTap: () {
                                        if (sponsor['email'] != null &&
                                            sponsor['email']!.isNotEmpty) {
                                          _launchEmail(sponsor['email']!);
                                        }
                                      },
                                      child: Text(
                                        sponsor['email'] ?? '',
                                        style: TextStyle(
                                          fontSize: cardWidth * 0.06,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
