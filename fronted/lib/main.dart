import 'package:flutter/material.dart';
import 'package:colcatrufis/screens/splash_screen.dart';  // Asegúrate de importar la pantalla de inicio
import 'package:colcatrufis/screens/home_screen.dart';    // Asegúrate de importar la pantalla principal

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colca Trufis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: SplashScreen(), // No necesitas const aquí
      routes: {
        '/home': (context) => HomeScreen(), // Aquí tampoco es necesario const
      },
    );
  }
}
