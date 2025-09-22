import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/utils.dart';

class ForgetPassScreen extends StatefulWidget {
  const ForgetPassScreen({super.key});

  @override
  State<ForgetPassScreen> createState() => _ForgetPassScreenState();
}

class _ForgetPassScreenState extends State<ForgetPassScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final emailFocusNode = FocusNode();
  bool _loading = false;

  Future<void> _sendResetLink() async {
    setState(() => _loading = true);

    final email = emailController.text.trim();
    final dbRef = FirebaseDatabase.instance.ref().child("users");

    try {
      final snapshot = await dbRef.orderByChild("email").equalTo(email).get();

      if (!snapshot.exists) {
        Utils.flushBarErrorMessage('No user found with this email.', context);
        setState(() => _loading = false);
        return;
      } else {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        Utils.flushBarErrorMessage(
          'Password reset link sent to your email.',
          context,
          success: true,
        );
        // ✅ Clear email field and dismiss keyboard
        emailController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint(e.toString());
      Utils.flushBarErrorMessage(
        'Something went wrong. Please try again.',
        context,
      );
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Forgot Password",
          style: TextStyle(
            fontSize: isTablet ? 22 : 18,
            color: AppColors.whiteColor,
            fontFamily: "Eurostile",
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: AppColors.whiteColor,
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.appBgColor,
        elevation: 0,
      ),
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenHeight -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? screenWidth * 0.2 : 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Section
                  Padding(
                    padding: EdgeInsets.only(
                      top: isLandscape ? 10 : 20,
                      bottom: isLandscape ? 20 : 30,
                    ),
                    child: SizedBox(
                      height: isTablet
                          ? screenHeight * 0.12
                          : isLandscape
                          ? screenHeight * 0.15
                          : screenHeight * 0.16,
                      child: Image.asset(
                        "images/logo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Title Text
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: isLandscape ? 25 : 35,
                      left: 10,
                      right: 10,
                    ),
                    child: Text(
                      textAlign: TextAlign.center,
                      "Enter your email and we'll send you instructions on how to reset it",
                      style: TextStyle(
                        fontSize: isTablet
                            ? 20
                            : isLandscape
                            ? 16
                            : 18,
                        color: AppColors.whiteColor,
                        fontFamily: "Eurostile",
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Form Section
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 400 : double.infinity,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Email Field
                          RoundTextField(
                            bgColor: AppColors.appBgColor,
                            label: "Email Address",
                            hint: "Enter your email address",
                            inputType: TextInputType.emailAddress,
                            textEditingController: emailController,
                            validatorValue: "Please enter a valid email",
                            focusNode: emailFocusNode,
                            onFieldSubmitted: (_) {
                              if (_formKey.currentState!.validate()) {
                                _sendResetLink();
                              }
                            },
                          ),

                          SizedBox(height: isLandscape ? 20 : 30),

                          // Send Button
                          SizedBox(
                            width: double.infinity,
                            height: isTablet ? 60 : 56,
                            child: RoundButton(
                              title: "Send Reset Link",
                              loading: _loading,
                              onPress: () {
                                if (_formKey.currentState!.validate()) {
                                  _sendResetLink();
                                }
                              },
                              borderRadius: 30,
                              fontSize: isTablet ? 20 : 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Additional spacing for better centering
                  SizedBox(height: isLandscape ? 20 : 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
