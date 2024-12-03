import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart'; // Make sure to import RxDart

class AccessPage extends StatefulWidget {
  @override
  _AccessPageState createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  String _searchQuery = "";
  final List<String> _roles = ["event_admin", "student"];

  void _updateUserRole(String userId, String newRole) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'role': newRole});
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success!'),
          content: Text('Role Updated Successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(String userId, String currentRole) {
    String? selectedRole = currentRole;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Role"),
        content: DropdownButtonFormField<String>(
          value: selectedRole ?? _roles.first, // Ensure it's initialized with a valid value
          items: _roles.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedRole = value;
            });
          },
          decoration: InputDecoration(
            labelText: "Select Role",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (selectedRole != null && selectedRole != currentRole) {
                _updateUserRole(userId, selectedRole!);
                Navigator.pop(context);
              }
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              labelText: "Search User",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),

          // User List
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: Rx.combineLatest2(
                FirebaseFirestore.instance
                    .collection('users')
                    .where('category', isEqualTo: 'admin')
                    .snapshots(),
                FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'event_admin')
                    .snapshots(),
                    (QuerySnapshot q1, QuerySnapshot q2) {
                  // Combine both queries' documents
                  final allDocs = List<QueryDocumentSnapshot>.from(q1.docs);
                  allDocs.addAll(q2.docs);
                  return allDocs;
                },
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No Admin Users Found"));
                }

                final users = snapshot.data!;

                // Filter users by search query (name or email)
                final filteredUsers = users.where((user) {
                  final name = user['name']?.toString().toLowerCase() ?? '';
                  final email = user['email']?.toString().toLowerCase() ?? '';
                  final university = user['university']?.toString().toLowerCase() ?? '';  // Add this line for university
                  return name.contains(_searchQuery) || email.contains(_searchQuery) || university.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    String userRole = user['role'] ?? _roles.first;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user['email'],
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user['university'] ?? 'No University',
                                    style: TextStyle(
                                        color: Colors.blueGrey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      _showUpdateDialog(user.id, userRole),
                                  child: Text("Update"),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
