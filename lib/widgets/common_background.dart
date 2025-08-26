import 'package:flutter/material.dart';

class CommonBackground extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const CommonBackground({
    super.key,
    required this.child,
    this.imagePath = 'lib/assets/images/background.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: child,
    );
  }
}
