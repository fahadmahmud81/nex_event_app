import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nex_event_app/panels/adminPanel.dart';
import 'package:nex_event_app/panels/adminPanel.dart';
import 'package:nex_event_app/panels/studentPanel.dart';

import 'package:nex_event_app/screens/loginPage.dart';
import 'package:nex_event_app/screens/logoScreen.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';


//Your Gateway to Event Opportunities in Bangladesh

//Connect. Engage. Elevate.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NexEvent',
      debugShowCheckedModeBanner: false,
      // home: LogoSplashScreen(),
      home: LoginPage(),
    );
  }
}



