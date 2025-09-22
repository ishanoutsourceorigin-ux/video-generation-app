import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

import 'package:video_gen_app/Utils/app_colors.dart';

class Utils {
  static void flushBarErrorMessage(
    String message,
    BuildContext context, {
    bool success = false,
  }) {
    Flushbar(
      margin: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(50),
      reverseAnimationCurve: Curves.easeInOut,
      message: message,
      duration: const Duration(seconds: 2),
      icon: Icon(
        success ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
      backgroundColor: AppColors.appBgColor,
      flushbarPosition: FlushbarPosition.BOTTOM,
    ).show(context);
  }

  static void fieldFocusNode(
    BuildContext context,
    FocusNode currentFocus,
    FocusNode nextFocus,
  ) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }
}
