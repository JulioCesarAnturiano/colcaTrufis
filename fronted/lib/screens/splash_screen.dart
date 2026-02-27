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
              Color.fromARGB(255, 28, 76, 82), // parecido al fondo superior
              Color.fromARGB(255, 81, 188, 193), // parecido al fondo inferior
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
