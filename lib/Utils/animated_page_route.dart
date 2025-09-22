import 'package:flutter/material.dart';

class AnimatedPageRoute extends PageRouteBuilder {
  final Widget page;
  AnimatedPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Yahan tum apni desired animation rakh sakte ho
            const begin = Offset(1.0, 0.0); // slide from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

/// Reusable function
void navigateWithAnimation(BuildContext context, Widget page) {
  Navigator.push(
    context,
    AnimatedPageRoute(page: page),
  );
}
