import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nex_event_app/panels/student/personalized.dart';
import 'package:nex_event_app/panels/student/userSpecific.dart';

class FavouritesPage extends StatefulWidget {
  @override
  _FavouritesPageState createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  String university = '';
  String userName = '';
  List<String> selectedCategories = []; // To store selected categories
  String filterOption = 'My Uni'; // Default filter option

  // Categories to choose from
  final List<String> allCategories = [
    'Educational Events',
    'Competitions',
    'IT contest',
    'Training Programs',
    'Cultural and Arts Event',
    'Study Abroad Events',
    'Career and Networking Event',
    'Sports and Recreational Event',
    'Community and Fundraising Event',
    'Government Drives and Events',
    'Religious Events',
    'Tech and Innovation Events',
    'Tourism Events',
  ];

  void hello () {
  String hello = 'Empty';
}

  // Method to fetch user information from Firestore
  Future<void> getUserInfo() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // Fetch user data from Firestore
        var userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          // Get the user data
          var userData = userSnapshot.docs.first.data();
          setState(() {
            university = userData['university'] ?? '';
            userName = userData['name'] ?? '';
            selectedCategories = List<String>.from(userData['personalized'] ?? []);
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  // Method to save the selected categories to Firestore
  Future<void> saveSelectedCategories(List<String> categories) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // Update user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .get()
            .then((snapshot) {
          snapshot.docs.first.reference.update({
            'personalized': categories, // Save the selected categories
          });
        });
      } catch (e) {
        print("Error saving categories: $e");
      }
    }
  }

  // Open dialog to select categories
  void _openCategoryDialog() async {
    List<String> tempSelectedCategories = List.from(selectedCategories); // Create a copy of selected categories

    // Show dialog with category selection
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text("Select up to 3 Categories",style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: allCategories.map((category) {
                    return CheckboxListTile(
                      title: Text(category),
                      value: tempSelectedCategories.contains(category),
                      onChanged: (bool? selected) {
                        setState(() {
                          // If selected is true and there are less than 3 categories, add the category
                          if (selected == true && tempSelectedCategories.length < 3) {
                            tempSelectedCategories.add(category);
                          } else if (selected == false) {
                            // If selected is false, remove the category
                            tempSelectedCategories.remove(category);
                          } else if (tempSelectedCategories.length >= 3) {
                            // If 3 categories are already selected, show a SnackBar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("You can select only 3 categories."),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Save the selected categories and reload the user info
                    await saveSelectedCategories(tempSelectedCategories); // Save to Firestore
                    setState(() {
                      selectedCategories = tempSelectedCategories; // Update selected categories
                    });

                    // Fetch the updated user info (reload page)
                    await getUserInfo(); // This will update the UI with the latest categories
                    Navigator.pop(context); // Close the dialog

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Success'),
                          content: Text('Category Saved'),
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

                  },
                  child: Text('Save'),
                ),
                TextButton(
                  onPressed: () async {
                    // Clear selections locally and in Firestore
                    setState(() {
                      selectedCategories.clear(); // Clear all selections
                      tempSelectedCategories.clear(); // Clear temporary list as well
                    });

                    // Save the empty selection to Firestore
                    await saveSelectedCategories([]); // Clear categories in Firestore

                    // Fetch the updated user info (reload page)
                    await getUserInfo(); // This will update the UI with the empty categories
                    Navigator.pop(context); // Close the dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Caution!'),
                          content: Text('Category Cleared'),
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
                  },
                  child: Text('Clear Selections'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  // Refresh function to reload user info
  Future<void> _onRefresh() async {
    await getUserInfo(); // Reload user info from Firestore
  }

  @override
  void initState() {
    super.initState();
    getUserInfo(); // Fetch user information when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh, // Refresh data when pulled down
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10,),
              // Row with "Edit Your Choice" button and Filter PopupMenu on the right
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Button to open category selection dialog
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        // Change this to your desired color
                        foregroundColor: Colors.white,
                        // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Optional: Rounded corners
                        ),
                      ),
                      onPressed: _openCategoryDialog,
                      child: Text("Edit Your Choice",style: TextStyle(fontWeight: FontWeight.bold),),
                    ),
                    // PopupMenuButton for Filter options on the right
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        setState(() {
                          filterOption = value;
                          selectedCategories;
                        });
                        print("Selected Filter: $filterOption");
                      },
                      itemBuilder: (BuildContext context) {
                        return ['My Uni', 'Personalized']
                            .map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          );
                        }).toList();
                      },
                      child: Row(
                        children: [
                          Text(
                            'Filter',
                            style: TextStyle(fontSize: 16, color: Colors.blue,fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            Icons.filter_list,
                            size: 20,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5), // Space after row

              // Display selected categories
              Center(
                child: Text(
                  "Selected Categories: ${selectedCategories.join(', ')},",
                  style: TextStyle(fontSize: 7), // Increased font size for visibility
                ),
              ),
            // Space after categories

              // Filtered content based on the selected option (for now, a placeholder)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: filterOption == 'My Uni'
                      ? Container(


                     child:  UserSpecificEventsPage(),

                  )
                      : filterOption == 'Personalized'
                      ? Container(


                    child:  PersonalizedEvent(),

                  )

                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Displaying all events",
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
