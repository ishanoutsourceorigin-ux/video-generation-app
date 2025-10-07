import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Screens/Auth/login_screen.dart';
import 'package:video_gen_app/Services/auth_services.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  FocusNode nameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode passFocusNode = FocusNode();
  FocusNode confirmPassFocusNode = FocusNode();
  FocusNode mobileFocusNode = FocusNode();
  FocusNode buttonFocusNode = FocusNode();
  bool _googleSigninLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // void _signInWithFacebook() {
  //   final authService = AuthService();

  //   authService.signInWithFacebook(
  //     context: context,
  //     onStart: () => setState(() => _googleSigninLoading = true),
  //     onComplete: () {
  //       if (mounted) setState(() => _googleSigninLoading = false);
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

  void onSignUp() {
    if (passwordController.text != confirmPasswordController.text) {
      Utils.flushBarErrorMessage("Passwords do not match", context);
      return;
    }

    AuthService().signUp(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      phoneNumber: mobileController.text.trim(),
      context: context,
      onStart: () {
        if (mounted) setState(() => _loading = true);
      },
      onComplete: () {
        if (mounted) setState(() => _loading = false);
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
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          foregroundColor: AppColors.whiteColor,
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
                  horizontal: isTablet ? screenWidth * 0.2 : 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo Section
                    Padding(
                      padding: EdgeInsets.only(
                        top: isLandscape ? 10 : 20,
                        bottom: isLandscape ? 10 : 20,
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
                      'Create Your Account',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 20,
                        color: AppColors.whiteColor.withValues(alpha: 0.8),
                        fontFamily: "Eurostile",
                      ),
                    ),

                    SizedBox(height: isLandscape ? 20 : 40),

                    // Form Section
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 400 : double.infinity,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name Field
                            RoundTextField(
                              label: 'Name',
                              hint: 'Enter your full name',
                              inputType: TextInputType.name,
                              focusNode: nameFocusNode,
                              bgColor: AppColors.appBgColor,
                              textEditingController: nameController,
                              validatorValue: 'Please Enter Name',
                              onFieldSubmitted: (_) {
                                Utils.fieldFocusNode(
                                  context,
                                  nameFocusNode,
                                  emailFocusNode,
                                );
                              },
                            ),

                            SizedBox(height: 16),

                            // Email Field
                            RoundTextField(
                              label: 'Email',
                              hint: 'johndoe@gmail.com',
                              bgColor: AppColors.appBgColor,
                              inputType: TextInputType.emailAddress,
                              textEditingController: emailController,
                              validatorValue: 'Please Enter Email',
                              focusNode: emailFocusNode,
                              onFieldSubmitted: (_) {
                                Utils.fieldFocusNode(
                                  context,
                                  emailFocusNode,
                                  passFocusNode,
                                );
                              },
                            ),

                            SizedBox(height: 16),

                            // Password Field
                            RoundTextField(
                              label: 'Create a password',
                              hint: 'Password',
                              inputType: TextInputType.visiblePassword,
                              bgColor: AppColors.appBgColor,
                              textEditingController: passwordController,
                              isPasswordField: true,
                              validatorValue: 'Please Enter Password',
                              focusNode: passFocusNode,
                              onFieldSubmitted: (_) {
                                Utils.fieldFocusNode(
                                  context,
                                  passFocusNode,
                                  confirmPassFocusNode,
                                );
                              },
                            ),

                            SizedBox(height: 16),

                            // Confirm Password Field
                            RoundTextField(
                              bgColor: AppColors.appBgColor,
                              label: 'Confirm Password',
                              hint: 'Re-enter password',
                              inputType: TextInputType.visiblePassword,
                              textEditingController: confirmPasswordController,
                              isPasswordField: true,
                              validatorValue: 'Please Confirm Password',
                              focusNode: confirmPassFocusNode,
                              onFieldSubmitted: (_) {
                                Utils.fieldFocusNode(
                                  context,
                                  confirmPassFocusNode,
                                  mobileFocusNode,
                                );
                              },
                            ),

                            SizedBox(height: 16),

                            // Mobile Field
                            RoundTextField(
                              bgColor: AppColors.appBgColor,
                              label: 'Phone Number',
                              hint: 'Enter your phone number',
                              inputType: TextInputType.phone,
                              textEditingController: mobileController,
                              validatorValue: 'Please Enter Phone Number',
                              focusNode: mobileFocusNode,
                              onFieldSubmitted: (_) {
                                Utils.fieldFocusNode(
                                  context,
                                  mobileFocusNode,
                                  buttonFocusNode,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Buttons Section
                    Padding(
                      padding: EdgeInsets.only(
                        top: isLandscape ? 20 : 30,
                        bottom: 20,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 400 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            // Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              height: isTablet ? 60 : 56,
                              child: RoundButton(
                                focusNode: buttonFocusNode,
                                loading: _loading,
                                title: 'Sign Up',
                                borderRadius: 30,
                                fontSize: isTablet ? 20 : 18,
                                onPress: () {
                                  if (_formKey.currentState!.validate()) {
                                    onSignUp();
                                  }
                                },
                              ),
                            ),

                            SizedBox(height: 16),

                            // Google Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              height: isTablet ? 60 : 56,
                              child: RoundButton(
                                titleColor: AppColors.purpleColor,
                                bgColor: AppColors.whiteColor,
                                leadingIcon: FontAwesomeIcons.google,
                                loading: _googleSigninLoading,
                                borderRadius: 30,
                                title: 'Sign up with Google',
                                fontSize: isTablet ? 20 : 18,
                                onPress: _signInWithGoogle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Sign In Section
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
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
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              navigateWithAnimation(
                                context,
                                const LoginScreen(),
                              );
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.blueColor,
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w600,
                              ),
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
