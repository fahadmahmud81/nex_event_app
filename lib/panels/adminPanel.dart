import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nex_event_app/panels/AdminRegInfo.dart';
import 'package:nex_event_app/panels/adminOrg.dart';
import 'package:nex_event_app/panels/adminSponsor.dart';
import 'package:nex_event_app/screens/loginPage.dart';

import 'adminEvent.dart';
import 'adminInfo.dart';

class AdminApp extends StatefulWidget {
  final String userName;
  final String userImageUrl;
  final String userId;
  final String userEmail;

  const AdminApp({
    Key? key,
    required this.userName,
    required this.userImageUrl,
    required this.userId,
    required this.userEmail,
  }) : super(key: key);

  @override
  _AdminAppState createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  int _currentIndex = 0;

  final List<Widget> _pageWidgets = [
    EventsPage(),
    SponsorsPage(),
    OrganizationsPage(),
    RegistrationInfoPage(),
  ];

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
    return WillPopScope(
      onWillPop: () async {
        // Disable the back button functionality
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, // Change the color of the 3-line menu icon
          ),
          backgroundColor: Colors.blue,
          title: Text(

            "Welcome Admin, ${widget.userName.split(' ').first}",
            style: TextStyle(fontSize: 16,color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                // Placeholder for notifications functionality
              },
              icon: Icon(
                  Icons.notifications_active_outlined,


              ),
            ),
            SizedBox(width: 10),
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
                leading: Icon(Icons.event_note_sharp),
                title: Text("Events"),
                selected: _currentIndex == 0,
                selectedTileColor: Colors.black12, // Optional: highlight color
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_money),
                title: Text("Sponsors"),
                selected: _currentIndex == 1,
                selectedTileColor: Colors.black12,  // Optional: highlight color
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.school),
                title: Text("Organizations"),
                selected: _currentIndex == 2,
                  selectedTileColor: Colors.black12,  // Optional: highlight color
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.how_to_reg_rounded),
                title: Text("Reg. Info"),
                selected: _currentIndex == 3,
                selectedTileColor: Colors.black12, // Optional: highlight color
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
                      builder: (context) => AdminProfileUpdate(userId: widget.userId, userEmail: widget.userEmail,),
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



        body: _pageWidgets[_currentIndex],
      ),
    );
  }
}

// Events Page










