import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Screens/Auth/forgot_pass_screen.dart';
import 'package:video_gen_app/Screens/Auth/signup_screen.dart';
import 'package:video_gen_app/Services/auth_services.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _loading = false;
  bool _googleSigninLoading = false;
  // bool _facebookSigninLoading = false;

  FocusNode emailFocusNode = FocusNode();
  FocusNode passFocusNode = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // login with email
  void _handleEmailLogin() {
    if (_formKey.currentState!.validate()) {
      final authService = AuthService();
      authService.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        context: context,
        onStart: () => setState(() => _loading = true),
        onComplete: () async {
          setState(() => _loading = false);
          // final hasLocation = await isLocationSaved();

          // if (!mounted) return;

          // if (hasLocation) {
          // Navigator.pushReplacementNamed(context, RouteNames.DashboardScreen);
          // } else {
          //   Navigator.pushReplacementNamed(
          //     context,
          //     RouteNames.askLocationScreen,
          //   );
          // }
        },
      );
    }
  }

  // void _signInWithFacebook() {
  //   final authService = AuthService();

  //   authService.signInWithFacebook(
  //     context: context,
  //     onStart: () => setState(() => _facebookSigninLoading = true),
  //     onComplete: () {
  //       if (mounted) setState(() => _facebookSigninLoading = false);
  //     },
  //   );
  // }

  void _signInWithGoogle() {
    final authService = AuthService();

    authService.signInWithGoogle(
      context: context,
      onStart: () => setState(() => _googleSigninLoading = true),
      onComplete: () {
        if (mounted) setState(() => _googleSigninLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.appBgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? screenWidth * 0.2 : 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    Padding(
                      padding: EdgeInsets.only(
                        top: isLandscape ? 20 : 60,
                        bottom: isLandscape ? 10 : 20,
                      ),
                      child: SizedBox(
                        height: isTablet
                            ? screenHeight * 0.15
                            : isLandscape
                            ? screenHeight * 0.2
                            : screenHeight * 0.18,
                        child: Image.asset(
                          "images/logo.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Welcome Text
                    Padding(
                      padding: EdgeInsets.only(bottom: isLandscape ? 10 : 20),
                      child: Text(
                        textAlign: TextAlign.center,
                        'Welcome to CloneX',
                        style: TextStyle(
                          fontSize: isTablet ? 32 : 27,
                          color: AppColors.whiteColor,
                          fontFamily: "Eurostile",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Text(
                      textAlign: TextAlign.center,
                      'Sign in to Continue',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 20,
                        color: AppColors.whiteColor.withOpacity(0.8),
                        fontFamily: "Eurostile",
                      ),
                    ),

                    SizedBox(height: isLandscape ? 20 : 40),

                    // Form Section
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 400 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                RoundTextField(
                                  label: 'Email',
                                  bgColor: AppColors.appBgColor,
                                  hint: 'johndoe@gmail.com',
                                  inputType: TextInputType.emailAddress,
                                  textEditingController: emailController,
                                  validatorValue: 'Please Enter Email',
                                  focusNode: emailFocusNode,
                                  onFieldSubmitted: (value) {
                                    Utils.fieldFocusNode(
                                      context,
                                      emailFocusNode,
                                      passFocusNode,
                                    );
                                  },
                                ),
                                SizedBox(height: 16),
                                RoundTextField(
                                  label: 'Password',
                                  hint: 'Password',
                                  inputType: TextInputType.name,
                                  bgColor: AppColors.appBgColor,
                                  textEditingController: passwordController,
                                  isPasswordField: true,
                                  validatorValue: 'Please Enter Password',
                                  focusNode: passFocusNode,
                                  onFieldSubmitted: (value) {
                                    _handleEmailLogin();
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Forgot Password
                          TextButton(
                            style: TextButton.styleFrom(
                              splashFactory: NoSplash.splashFactory,
                              overlayColor: Colors.transparent,
                            ),
                            onPressed: () {
                              navigateWithAnimation(
                                context,
                                const ForgetPassScreen(),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontFamily: "Eurostile",
                                color: AppColors.greyColor,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ),

                          // Buttons Section
                          Padding(
                            padding: EdgeInsets.only(
                              top: isLandscape ? 20 : 30,
                              bottom: 20,
                            ),
                            child: Column(
                              children: [
                                // Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: isTablet ? 60 : 56,
                                  child: RoundButton(
                                    loading: _loading,
                                    borderRadius: 30,
                                    title: 'Sign in',
                                    fontSize: isTablet ? 20 : 18,
                                    onPress: () {
                                      if (_formKey.currentState!.validate()) {
                                        _handleEmailLogin();
                                      }
                                    },
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Google Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: isTablet ? 60 : 56,
                                  child: RoundButton(
                                    titleColor: AppColors.purpleColor,
                                    bgColor: AppColors.whiteColor,
                                    leadingIcon: FontAwesomeIcons.google,
                                    loading: _googleSigninLoading,
                                    borderRadius: 30,
                                    title: 'Sign in with Google',
                                    fontSize: isTablet ? 20 : 18,
                                    onPress: _signInWithGoogle,
                                  ),
                                ),

                                SizedBox(height: 24),

                                // Sign Up Section
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: AppColors.greyColor,
                                        fontSize: isTablet ? 18 : 16,
                                      ),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        splashFactory: NoSplash.splashFactory,
                                        overlayColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        navigateWithAnimation(
                                          context,
                                          const SignupScreen(),
                                        );
                                      },
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: const Color(0xFF6366F1),
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
