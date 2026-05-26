import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final bool isBrand;

  const AppLogo({
    super.key,
    this.height = 60,
    this.isBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show 'ProDine' text instead of branded image to remove 'Prodapt' reference
    if (isBrand) {
      return Text(
        'ProDine',
        style: TextStyle(
          fontSize: height * 1.2,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFF3B30),
          letterSpacing: -0.3,
        ),
      );
    }
    return Image.asset(
      'assets/images/app_logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
