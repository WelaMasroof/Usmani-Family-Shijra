import 'package:flutter/material.dart';
import 'package:usmaifamilyshijra/splash%20screen/splash_screen.dart';


void main() => runApp(const ShijraApp());

class ShijraApp extends StatelessWidget {
  const ShijraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usmani Family Shijra',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
      ),

      home: const SplashScreen(), // start with splash
      debugShowCheckedModeBanner: false,
    );
  }
}
