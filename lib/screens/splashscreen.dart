import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nex_event_app/screens/loginPage.dart';
import 'RegistrationScreen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 70,
              ),
              Column(
                // mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SizedBox(height: 100,),
                  Text(
                    'Welcome',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        color: Colors.blueAccent),
                  ),
                  Text(
                    'Login or Signup to continue',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                height: 300,
                width: 900,
                child: Image.asset('assets/download2.png'),
              ),
              SizedBox(
                height: 30,
              ),
              Center(
                child: Container(
                    height: 60, child: Image.asset("assets/nexaevent.png")),
              ),
              Center(
                child: Text(
                  "Bangladesh's Event Gateway",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 60,
              ),
              Container(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      // Change this to your desired color
                      foregroundColor: Colors.white,
                      // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Optional: Rounded corners
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationPage()),
                      );
                    },
                    child: Text("Create Account",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18))),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      // Change this to your desired color
                      foregroundColor: Colors.white,
                      // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Optional: Rounded corners
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Text("Already Have Account",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
