import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'RegistrationScreen.dart';



class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/splashimage.png", // Replace with your background image path
              fit: BoxFit.cover,
            ),
          ),


          // "Get Started" button positioned at the bottom
          Positioned(
            bottom: 50, // Position the button above the bottom edge
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                Get.to(() => RegistrationPage());
              },
              child: Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.black, // Text color
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}