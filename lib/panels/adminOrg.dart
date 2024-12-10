import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationsPage extends StatefulWidget {
  @override
  _OrganizationsPageState createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Listen for changes in the search box
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  // Show dialog with additional information
  void _showOrganizationDetails(Map<String, dynamic> org) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(org['name'] ?? 'Organization',style: TextStyle(fontSize: 18),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Facebook: ${org['facebookLink'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Organization Type: ${org['organizationType'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Name: ${org['name'] ?? 'N/A'}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search Organizations',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Organization List with Cards
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('organization').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return Center(child: Text('No organizations available.'));
                }

                var orgDocs = snapshot.data!.docs;

                // Filter organizations based on the search query
                var filteredOrgs = orgDocs.where((orgDoc) {
                  var org = orgDoc.data() as Map<String, dynamic>;
                  String name = org['name'] ?? '';
                  return name.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filteredOrgs.length,
                  itemBuilder: (context, index) {
                    var org = filteredOrgs[index].data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () => _showOrganizationDetails(org), // Show details when tapped
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Organization Logo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  org['logo'] ?? '',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 16),
                              // Organization Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      org['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Email: ${org['email'] ?? ''}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Contact: ${org['contact'] ?? ''}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
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
    );
  }
}
