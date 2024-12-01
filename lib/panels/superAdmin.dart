import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nex_event_app/panels/stdprofile.dart';
import 'package:nex_event_app/screens/loginPage.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuperApp extends StatefulWidget {

  final String userName;
  final String userImageUrl;
  final String userId; // Add userId to identify the logged-in user

  const SuperApp({
    Key? key,
    required this.userName,
    required this.userImageUrl,
    required this.userId,
  }) : super(key: key);

  @override
  _SuperAppState createState() => _SuperAppState();
}

class _SuperAppState extends State<SuperApp> {
  int _currentIndex = 0;

  // Method to handle logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => LoginPage()); // Navigate to login and clear stack
  }

  // Show confirmation dialog before logging out
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _logout(); // Perform logout
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Super Admin Panel", style: TextStyle(fontSize: 16)),
        automaticallyImplyLeading: false, // Disable default back button
        titleSpacing: 20,

        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundImage: NetworkImage(widget.userImageUrl),
            ),
            onSelected: (String value) {
              if (value == "Profile") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: widget.userId),
                  ),
                );
              } else if (value == "Logout") {
                _showLogoutDialog(); // Show logout confirmation dialog
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                // PopupMenuItem(
                //   value: "Profile",
                //   child: Text("Profile"),
                // ),
                PopupMenuItem(
                  value: "Logout",
                  child: Text("Logout"),
                ),
              ];
            },
          ),
          SizedBox(width: 15),
        ],
      ),
      body: Center(
        child: Text(
          "Page ${_currentIndex + 1}",
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          SalomonBottomBarItem(
            icon: Icon(Icons.verified_user_outlined,size: 30,),
            title: Text("Access"),
            selectedColor: Colors.blue,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.school_outlined,size: 30,),
            title: Text("Organization"),
            selectedColor: Colors.orange,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.monetization_on_outlined,size: 30,),
            title: Text("Sponsor"),
            selectedColor: Colors.purple,
          ),


          SalomonBottomBarItem(
            icon: Icon(Icons.tips_and_updates_outlined,size: 30,),
            title: Text("Notice"),
            selectedColor: Colors.green,
          ),

        ],
      ),
    );
  }
}
