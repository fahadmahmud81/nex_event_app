import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nex_event_app/panels/stdprofile.dart';
import 'package:nex_event_app/screens/loginPage.dart';

import 'adminInfo.dart';

class AdminApp extends StatefulWidget {
  final String userName;
  final String userImageUrl;
  final String userId;

  const AdminApp({
    Key? key,
    required this.userName,
    required this.userImageUrl,
    required this.userId,
  }) : super(key: key);

  @override
  _AdminAppState createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  int _currentIndex = 0;

  final List<String> _pages = ["Dashboard", "Events", "Notifications", "Settings"];

  // Method to handle logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => LoginPage());
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
        title: Text("Welcome Admin, ${widget.userName.split(' ').first}", style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){}, icon: Icon(Icons.notifications_active_outlined),
          ),
          SizedBox(width: 10,)

        ],

      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: widget.userImageUrl.isNotEmpty
                        ? NetworkImage(widget.userImageUrl)
                        : AssetImage('assets/default_image.png') as ImageProvider,
                    radius: 30,
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.userName,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    "Admin",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text("Dashboard"),
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.event),
              title: Text("Events"),
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text("Notifications"),
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Update Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminProfileUpdate(userId: widget.userId, ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          "Current Page: ${_pages[_currentIndex]}",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
