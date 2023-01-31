import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_text_field.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  late TextEditingController _textEditingControllerTitle;
  final _carouselSliderImages = [
    'assets/images/callibri_blue.png',
    'assets/images/callibri_red.png',
    'assets/images/callibri_yellow.png',
    'assets/images/callibri_white.png',
  ];

  List<User> _allUsers = [];
  late Future<void> _initRegisteredUsers;

  @override
  void initState() {
    _textEditingControllerTitle = TextEditingController();

    _initRegisteredUsers = getRegisteredUsers();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Get.isDarkMode
            ? Colors.black.withAlpha(250)
            : Colors.white.withAlpha(250),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    alignment: WrapAlignment.center,
                    runSpacing: 16,
                    children: [
                      Text('Log into an existing account',
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.titleLarge
                              : AppTheme.appTheme.textTheme.headline5),
                      SizedBox(height: 24),
                      AppTextFieldSmall(
                          textEditingControllerTitle: _textEditingControllerTitle,
                              hint: 'email',
                              hintIcon: Icons.email,
                              ),
                      AppTextFieldSmall(
                          textEditingControllerTitle:
                              _textEditingControllerTitle,
                              hint: 'password',
                              hintIcon: Icons.password,

                              ),
                      Container(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          width: double.infinity,
                          child: AppFilledButton(
                            backgroundColor: Color(0xff5181b8),
                            text: 'Log in',
                            onPressed: () => null,
                          )),
                      Text('Forgot Password?',
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.caption
                                  ?.copyWith(
                                      color: Color(0xffaeb7c4),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline)
                              : AppTheme.appTheme.textTheme.caption?.copyWith(
                                  color: Color(0xffaeb7c4),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text('or',
                    style: Get.isDarkMode
                        ? AppTheme.appDarkTheme.textTheme.caption?.copyWith(
                            color: Color(0xff626d7a),
                            fontWeight: FontWeight.w600,
                          )
                        : AppTheme.appTheme.textTheme.caption?.copyWith(
                            color: Color(0xff626d7a),
                            fontWeight: FontWeight.w600,
                          )),
                SizedBox(height: 12),
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
                  child: Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.only(bottom: 20, top: 8),
                          width: double.infinity,
                          child: AppFilledButton(
                            backgroundColor: Color(0xff148dc6),
                            text: 'Create new account',
                            onPressed: () => null,
                          )),
                      Text(
                          'After signing up, you’ll get access to all of NeuroMD & Callibri features',
                          textAlign: TextAlign.center,
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.caption
                                  ?.copyWith(
                                  color: Color(0xffaeb7c4),
                                )
                              : AppTheme.appTheme.textTheme.caption?.copyWith(
                                  color: Color(0xffaeb7c4),
                                )),
                      SizedBox(height: 4),
                      Text('Learn more',
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.caption
                                  ?.copyWith(
                                      color: Color(0xff626d7a),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline)
                              : AppTheme.appTheme.textTheme.caption?.copyWith(
                                  color: Color(0xff626d7a),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              width: 320,
              height: 530,
              color: Colors.white,
              child: Column(
                children: [
                  // CarouselSlider.builder(itemCount: _carouselSliderImages, itemBuilder: (context, index, realIndex){
                  //   final sliderImage = 
                  // }, options: options)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getRegisteredUsers() async {
    var registeredUsers = await UserOperations().getAllUsers();
  }
}

class AppTextFieldSmall extends StatelessWidget {
  const AppTextFieldSmall({
    Key? key,
    required this.hint,
    required this.hintIcon,
    required this.textEditingControllerTitle,
  }) : super(key: key);

  final TextEditingController textEditingControllerTitle;
  final String hint;
  final IconData hintIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingControllerTitle,
      style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
      cursorColor: Colors.grey,
      decoration: InputDecoration(
        counterStyle: TextStyle(color: Colors.transparent),
        fillColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.highlightColor
            : Color(0xfff2f3f5),
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
                    color: AppTheme.appDarkTheme.highlightColor, amount: 0.3)
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
           hintIcon
            size: 26,
            color: Theme.of(context).colorScheme.shadow,
          ),
        ),
      ),
    );
  }
}
