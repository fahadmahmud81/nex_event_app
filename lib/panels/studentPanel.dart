import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nex_event_app/panels/stdprofile.dart';
import 'package:nex_event_app/panels/student/favouritePage.dart';
import 'package:nex_event_app/panels/student/homeEvent.dart';
import 'package:nex_event_app/panels/student/stdEventList.dart';
import 'package:nex_event_app/screens/loginPage.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentApp extends StatefulWidget {
  final String userName;
  final String userImageUrl;
  final String userId; // Add userId to identify the logged-in user

  const StudentApp({
    Key? key,
    required this.userName,
    required this.userImageUrl,
    required this.userId, // Pass userId to fetch user data
  }) : super(key: key);

  @override
  _StudentAppState createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  int _currentIndex = 0;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => LoginPage()); // Navigate to login and clear stack
  }

  final List<Widget> _pages = [
    HomePage(),
    FavouritesPage(),
    RegisteredPage(),
    NoticePage(),
  ];

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
        title: Text("Welcome, ${widget.userName}", style: TextStyle(fontSize: 16)),
        automaticallyImplyLeading: false,
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
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: "Profile",
                  child: Text("Profile"),
                ),
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
      body: _pages[_currentIndex], // Display selected page
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          SalomonBottomBarItem(
            icon: Icon(Icons.home_outlined, size: 30),
            title: Text("Home"),
            selectedColor: Colors.blue,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.favorite_border_rounded, size: 30),
            title: Text("Favourites"),
            selectedColor: Colors.purple,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined, size: 30),
            title: Text("Registered"),
            selectedColor: Colors.green,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.notifications_active_outlined, size: 30),
            title: Text("Notice"),
            selectedColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class NoticePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Event Notices",
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}







