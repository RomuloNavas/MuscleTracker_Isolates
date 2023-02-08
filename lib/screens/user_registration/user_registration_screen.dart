import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/home/home_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/search_screen.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_text_field.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen>
    with TickerProviderStateMixin {
  final Set<List<String>> _carouselSliderImages = {
    [
      'assets/images/login/login_1.png',
      'We have created a wireless system to minimize signal interference and ensure the most accurate results so you can analyze your workout process in finest details.'
    ],
    [
      'assets/images/login/login_2.png',
      'Myographic system enables you to assess and compare how different muscles get engaged in the moving pattern.'
    ],
    [
      'assets/images/login/login_3.png',
      'A Bluetooth powered system that connects the sensor to your tablet or mobile'
    ],
    [
      'assets/images/login/login_4.png',
      'Registering muscles myoelectrical activity while exercising'
    ],
  };

  final userOperations = UserOperations();
  User? _registeredUser;
  bool _isPasswordVisible = false;
  bool _isCreatingAnAccount = false;

  late TextEditingController _textEditingControllerName;
  late TextEditingController _textEditingControllerEmail;
  late TextEditingController _textEditingControllerPassword;

  // Animations
  late AnimationController _animationControllerLogin;
  late Animation<double> _animationLogin;
  late AnimationController _animationControllerSignup;
  late Animation<double> _animationSignup;

  @override
  void initState() {
    super.initState();
    _textEditingControllerName = TextEditingController();
    _textEditingControllerEmail = TextEditingController();
    _textEditingControllerPassword = TextEditingController();

    // Animations
    _animationControllerLogin = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animationLogin = CurvedAnimation(
      parent: _animationControllerLogin,
      curve: Curves.fastLinearToSlowEaseIn,
    );

    _animationControllerSignup = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animationSignup = CurvedAnimation(
      parent: _animationControllerSignup,
      curve: Curves.fastLinearToSlowEaseIn,
    );
    _toggleContainerLogin();
  }

  _toggleContainerLogin() async {
    _animationControllerSignup.animateBack(0,
        duration: const Duration(milliseconds: 300));
    await Future.delayed(const Duration(milliseconds: 600));
    _animationControllerLogin.forward();
  }

  _toggleContainerSignup() async {
    _animationControllerLogin.animateBack(0);
    await Future.delayed(const Duration(milliseconds: 600));
    _animationControllerSignup.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Get.isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isCreatingAnAccount == false)
                        Container(
                          padding: const EdgeInsets.only(
                              left: 32, right: 32, bottom: 20, top: 24),
                          decoration: BoxDecoration(
                            border: Border.all(
                                width: 1.0,
                                color: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.colorScheme.outline
                                    : AppTheme.appTheme.colorScheme.outline),
                            color: Get.isDarkMode
                                ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                                : AppTheme.appTheme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          width: 350,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runSpacing: 12,
                            children: [
                              Text('Log into an existing account',
                                  style: Get.isDarkMode
                                      ? AppTheme
                                          .appDarkTheme.textTheme.headline5
                                      : AppTheme.appTheme.textTheme.headline5),
                              SizeTransition(
                                sizeFactor: _animationLogin,
                                axis: Axis.vertical,
                                child: Column(
                                  children: [
                                    SizedBox(height: 20),
                                    AppTextFieldSmall(
                                      textEditingController:
                                          _textEditingControllerEmail,
                                      hint: 'Email',
                                      hintIcon: Icons.email,
                                    ),
                                    SizedBox(height: 16),
                                    AppTextFieldSmall(
                                      textEditingController:
                                          _textEditingControllerPassword,
                                      hint: 'Password',
                                      hintIcon: Icons.password,
                                      obscureText: _isPasswordVisible,
                                      suffixIcon: _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      onSuffixIconPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    SizedBox(height: 8)
                                  ],
                                ),
                              ),
                              Container(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  width: double.infinity,
                                  child: AppFilledButton(
                                    backgroundColor: Color(0xff5181b8),
                                    text: 'Log in',
                                    onPressed: login,
                                  )),
                              Text('Forgot Password?',
                                  style: Get.isDarkMode
                                      ? AppTheme.appDarkTheme.textTheme.caption
                                          ?.copyWith(
                                              color: Color(0xffaeb7c4),
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline)
                                      : AppTheme.appTheme.textTheme.caption
                                          ?.copyWith(
                                              color: Color(0xffaeb7c4),
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline)),
                            ],
                          ),
                        ),
                      if (_isCreatingAnAccount == false)
                        Container(
                          width: 350,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                    height: 1,
                                    color: Get.isDarkMode
                                        ? darkerColorFrom(
                                            color: Color(0xffaeb7c4),
                                            amount: 0.2)
                                        : darkerColorFrom(
                                            color: Color(0xffe7e8ec),
                                            amount: 0.1)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or',
                                    style: Get.isDarkMode
                                        ? AppTheme
                                            .appDarkTheme.textTheme.caption
                                            ?.copyWith(
                                            color: darkerColorFrom(
                                                color: Color(0xffaeb7c4),
                                                amount: 0.2),
                                            fontWeight: FontWeight.w600,
                                          )
                                        : AppTheme.appTheme.textTheme.caption
                                            ?.copyWith(
                                            color: darkerColorFrom(
                                                color: Color(0xffe7e8ec),
                                                amount: 0.2),
                                            fontWeight: FontWeight.w600,
                                          )),
                              ),
                              Expanded(
                                child: Container(
                                    height: 1,
                                    color: Get.isDarkMode
                                        ? darkerColorFrom(
                                            color: Color(0xffaeb7c4),
                                            amount: 0.2)
                                        : darkerColorFrom(
                                            color: Color(0xffe7e8ec),
                                            amount: 0.1)),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: 32, right: 32, bottom: 20, top: 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 1.0,
                              color: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.dividerColor
                                  : Color(0xffe7e8ec)),
                          color: Get.isDarkMode
                              ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                              : AppTheme.appTheme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        width: 350,
                        child: Wrap(
                          runSpacing: 12,
                          children: [
                            if (_isCreatingAnAccount == true)
                              Text('Create and Log in to a new account',
                                  style: Get.isDarkMode
                                      ? AppTheme
                                          .appDarkTheme.textTheme.headline5
                                      : AppTheme.appTheme.textTheme.headline5),
                            if (_isCreatingAnAccount == true)
                              SizeTransition(
                                sizeFactor: _animationSignup,
                                axis: Axis.vertical,
                                child: Column(
                                  children: [
                                    SizedBox(height: 20),
                                    AppTextFieldSmall(
                                      textEditingController:
                                          _textEditingControllerName,
                                      hint: 'Name',
                                      hintIcon: Icons.person,
                                    ),
                                    SizedBox(height: 16),
                                    AppTextFieldSmall(
                                      textEditingController:
                                          _textEditingControllerEmail,
                                      hint: 'Email',
                                      hintIcon: Icons.email,
                                    ),
                                    SizedBox(height: 16),
                                    AppTextFieldSmall(
                                      textEditingController:
                                          _textEditingControllerPassword,
                                      hint: 'Password',
                                      hintIcon: Icons.password,
                                      obscureText: _isPasswordVisible,
                                      suffixIcon: _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      onSuffixIconPressed:
                                          togglePasswordVisibility,
                                    ),
                                    SizedBox(height: 8)
                                  ],
                                ),
                              ),
                            Container(
                                padding: const EdgeInsets.only(bottom: 16),
                                width: double.infinity,
                                child: AppFilledButton(
                                  backgroundColor: Color(0xff148dc6),
                                  text: 'Create new account',
                                  onPressed: createNewAccount,
                                )),
                            Text(
                                'After signing up, you’ll get access to all of NeuroMD & Callibri features',
                                textAlign: TextAlign.center,
                                style: AppTheme.appDarkTheme.textTheme.caption
                                    ?.copyWith(
                                  color: const Color(0xffaeb7c4),
                                )),
                            Center(
                              child: Text('Learn more',
                                  style: AppTheme.appTheme.textTheme.caption
                                      ?.copyWith(
                                          color: const Color(0xff626d7a),
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.underline)),
                            ),
                            if (_isCreatingAnAccount == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Row(
                                  children: [
                                    Text('Already have an account? ',
                                        style: AppTheme
                                            .appTheme.textTheme.caption
                                            ?.copyWith(
                                          color: const Color(0xffaeb7c4),
                                        )),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isCreatingAnAccount = false;
                                          _toggleContainerLogin();
                                        });
                                      },
                                      child: Text('Log in',
                                          style: AppTheme
                                              .appTheme.textTheme.caption
                                              ?.copyWith(
                                                  color: Color(0xff5181b8),
                                                  fontWeight: FontWeight.w600,
                                                  decoration: TextDecoration
                                                      .underline)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    // (- logIn card width, - left margin - (left and right margin of 48 each one))
                    width: Get.size.width - 350 - 24 - 96,
                    margin: const EdgeInsets.only(left: 24),
                    height: Get.size.height - 48,
                    child: CarouselSlider.builder(
                        options: CarouselOptions(
                          autoPlayInterval: const Duration(seconds: 6),
                          viewportFraction: 1,
                          autoPlay: true,
                        ),
                        itemCount: _carouselSliderImages.length,
                        itemBuilder: (context, index, realIndex) {
                          final sliderImage =
                              _carouselSliderImages.toList()[index];
                          return buildImage(sliderImage, index);
                        }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> createNewAccount() async {
    if (_isCreatingAnAccount == true) {
      if (_textEditingControllerName.text.isEmpty ||
          _textEditingControllerEmail.text.isEmpty ||
          _textEditingControllerPassword.text.isEmpty) {
        Fluttertoast.showToast(
          msg: "Please fill out the empty fields.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          textColor: Colors.white,
          backgroundColor: Get.isDarkMode
              ? AppTheme.appDarkTheme.colorScheme.error
              : AppTheme.appTheme.colorScheme.error,
          fontSize: 16.0,
        );
      } else {
        final user = User(
          name: _textEditingControllerName.text,
          email: _textEditingControllerEmail.text,
          password: _textEditingControllerPassword.text,
          isLoggedIn: 0,
        );
        int? idOfInsertedUser = await userOperations.createUser(user);
        if (idOfInsertedUser != null) {
          user.id = idOfInsertedUser;
          user.isLoggedIn = 1;
          await userOperations.updateUser(user);
          Get.off(() => SearchScreen());
        }
      }
    } else {
      setState(() {
        _isCreatingAnAccount = true;
        _toggleContainerSignup();
      });
    }
  }

  Future<void> login() async {
    if (_textEditingControllerEmail.text.isEmpty ||
        _textEditingControllerPassword.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill out the empty fields.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        backgroundColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.colorScheme.error
            : AppTheme.appTheme.colorScheme.error,
        fontSize: 16.0,
      );
    } else {
      var logInUser = await userOperations.getUser(
        email: _textEditingControllerEmail.text,
        password: _textEditingControllerPassword.text,
      );

      if (logInUser != null) {
        // If the account exists, then log in and set loggedIn to true, in order to remember the account and step this screen the next time
        logInUser.isLoggedIn = 1;
        await userOperations.updateUser(logInUser);

        Get.off(() => HomeScreen());
      }
    }
  }

  Widget buildImage(List<String> urlImage, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage(
              urlImage.first,
            )),
      ),
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: FractionalOffset.bottomCenter,
                end: FractionalOffset.topCenter,
                colors: Get.isDarkMode
                    ? [
                        Colors.black.withOpacity(.8),
                        Colors.black.withOpacity(.3)
                      ]
                    : [
                        Colors.black.withOpacity(.7),
                        Colors.black.withOpacity(.0)
                      ])),
        child: Stack(
          children: [
            Positioned(
              right: 12,
              top: 12,
              child: SvgPicture.asset(
                'assets/icons/callibri_logo.svg',
                height: 32,
                semanticsLabel: 'Callibri Logo',
                color: Colors.white,
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                  height: 8,
                  width: (Get.size.width -
                      350 -
                      24 -
                      96), //carousel width - margins
                  color: Get.isDarkMode
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.5)),
            ),
            Positioned(
              bottom: 16,
              child: Row(
                children: [
                  Container(
                      height: 64,
                      width: 8,
                      color: Get.isDarkMode
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white.withOpacity(0.7)),
                  Container(
                      margin: const EdgeInsets.only(left: 12, right: 12),
                      width: (Get.size.width - 350 - 24 - 96) -
                          24 -
                          24, //carousel width - margins
                      child: Text(
                        urlImage.last,
                        style: AppTheme.appTheme.textTheme.bodyText1?.copyWith(
                            color: const Color(0xffeeeeee), height: 1.4),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppTextFieldSmall extends StatelessWidget {
  AppTextFieldSmall({
    Key? key,
    required this.hint,
    required this.hintIcon,
    required this.textEditingController,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixIconPressed,
  }) : super(key: key);

  final TextEditingController textEditingController;
  final String hint;
  final IconData hintIcon;
  final IconData? suffixIcon;
  final Function()? onSuffixIconPressed;
  bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      controller: textEditingController,
      style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
      cursorColor: Colors.grey,
      decoration: InputDecoration(
        counterStyle: TextStyle(color: Colors.transparent),
        fillColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.colorScheme.surfaceVariant
            : AppTheme.appTheme.colorScheme.surfaceVariant,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Get.isDarkMode
                ? lighterColorFrom(
                    color: AppTheme.appDarkTheme.colorScheme.surfaceVariant,
                    amount: 0.3)
                : Color(0xffd3d5d7),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 66, 125, 145)),
        ),
        hintText: hint,
        contentPadding: const EdgeInsets.all(12),
        hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.shadow, fontSize: 18),
        prefixIcon: Container(
          padding: const EdgeInsets.all(15),
          width: 18,
          child: Icon(
            hintIcon,
            size: 26,
            color: Theme.of(context).colorScheme.shadow,
          ),
        ),
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixIconPressed,
                child: Icon(
                  suffixIcon,
                  size: 26,
                  color: Theme.of(context).colorScheme.shadow,
                ))
            : null,
      ),
    );
  }
}
