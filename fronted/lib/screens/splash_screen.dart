import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore_for_file: library_private_types_in_public_api

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;

  // Fade in
  late Animation<double> _fade;

  // Scale: starts slightly far (small) → comes in → settles
  // Simulates a "zoom in from distance" — professional, no bounce
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Fade: 0 → 1 over first 60%
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
      ),
    );

    // Scale: 0.82 → 1.04 → 1.0
    // Comes from "far away" (small) and settles — no elastic, no bounce
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 75,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_ctrl);

    _ctrl.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 1.20,
            colors: [
              Color(0xFF0B4F62),
              Color(0xFF042E3D),
              Color(0xFF021A22),
            ],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
        child: Stack(
          children: [

            // Subtle dot grid
            CustomPaint(size: size, painter: _GridPainter()),

            // Soft ambient glow behind logo
            Center(
              child: Container(
                width:  size.width * 0.65,
                height: size.width * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF19B7B0).withOpacity(0.13),
                      blurRadius: 110,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),

            // Logo
            Center(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => FadeTransition(
                  opacity: _fade,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Image.asset(
                      'assets/images/logo_appp.png',
                      width:  size.width * 0.62,
                      height: size.width * 0.62,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // Version — minimal, bottom centre
            Positioned(
              bottom: 42,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 1,
                      color: const Color(0xFF19B7B0).withOpacity(0.30),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'v 1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.18),
                        fontSize: 10,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─── Subtle background pattern ────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = const Color(0xFF19B7B0).withOpacity(0.045);
    const step = 40.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.9, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}