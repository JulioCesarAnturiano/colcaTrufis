import 'package:flutter/material.dart';
import 'dart:async';

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
        // ✅ Fondo que combina con pant.png (elimina bordes blancos)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0, 44, 62, 1), // parecido al fondo superior
              Color.fromRGBO(0, 44, 62, 1), 
            ],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/pant.png',
            fit: BoxFit.contain, // no recorta, solo elimina el blanco del fondo
          ),
        ),
      ),
    );
  }
}
