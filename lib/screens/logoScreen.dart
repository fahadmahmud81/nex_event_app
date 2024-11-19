import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:nex_event_app/screens/splashscreen.dart';

class LogoSplashScreen extends StatelessWidget {
  const LogoSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.fadeIn(
      backgroundColor: Colors.white,
      onInit: () {
        debugPrint("On Init");
      },
      onEnd: () {
        debugPrint("On End");
      },
      childWidget: SizedBox(
        height: 450,
        width: 450,
        child: Image.asset("assets/nexaevent.png"),
      ),
      onAnimationEnd: () => debugPrint("On Fade In End"),
      nextScreen: SplashScreen(),
    );
  }
}