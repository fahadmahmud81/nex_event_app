import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0,),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Search Sponsors by Name or Interest',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 15,),
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
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Sponsor Image in a Circle Avatar
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(sponsor['imageUrl'] ?? ''),
                                  child: sponsor['imageUrl'] == null
                                      ? Icon(Icons.business, color: Colors.white)
                                      : null,
                                ),
                                SizedBox(height: 10),
                                // Sponsor Name
                                Text(
                                  sponsor['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                // Sponsor Phone
                                Text(
                                  sponsor['phone'] ?? '',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                // Sponsor Interest
                                Text(
                                  sponsor['interest'] ?? '',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                // Sponsor Email
                                Text(
                                  sponsor['email'] ?? '',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
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
