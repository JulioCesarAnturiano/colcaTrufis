import 'package:flutter/material.dart';
import 'dart:async';

const Color kPrimary = Color(0xFF09596E);
const Color kPrimaryDark = Color(0xFF064656);
const Color kAqua = Color(0xFF19B7B0);

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryDark,
              kPrimary,
              kAqua.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/logo_appp.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
