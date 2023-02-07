import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/search_controller.dart';
import 'package:neuro_sdk_isolate_example/screens/user_registration/user_registration_screen.dart';
import 'dart:async';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_bottom.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  late TextEditingController _textEditingControllerName;
  late TextEditingController _textEditingControllerSurname;
  late TextEditingController _textEditingControllerPatronymic;
  late TextEditingController _textEditingControllerBornDate;
  late TextEditingController _textEditingControllerPhone;
  late TextEditingController _textEditingControllerEmail;

  // Async load data on init:
  final clientOperations = ClientOperations();
  final userOperations = UserOperations();
  late User _loggedInUser;
  late Future initUserAccount;

  PhoneNumber number = PhoneNumber(isoCode: 'RU');
  @override
  void initState() {
    super.initState();

    initUserAccount = _getLoggedInUserDBAsync();

    _textEditingControllerName = TextEditingController();
    _textEditingControllerSurname = TextEditingController();
    _textEditingControllerPatronymic = TextEditingController();
    _textEditingControllerBornDate = TextEditingController();
    _textEditingControllerEmail = TextEditingController();

    _textEditingControllerPhone = TextEditingController();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  bool _isLoading = true;

  @override
  void dispose() {
    super.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading == true) {
      return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: MediaQuery.of(context).size.height < 500 ? 50 : 80,
            titleTextStyle: Get.isDarkMode
                ? AppTheme.appDarkTheme.textTheme.headline3
                : AppTheme.appTheme.textTheme.headline3,
            title: const Text('New client'),
            titleSpacing: 32.0,
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: SizedBox(
              width: Get.size.width > 800 ? 720 : Get.size.width - 32,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        const AppHeaderInfo(
                          title: "Add a new client",
                          labelPrimary:
                              "Fill up the required fields about client",
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Get.isDarkMode
                                ? AppTheme
                                    .appDarkTheme.colorScheme.surfaceVariant
                                : AppTheme.appTheme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    child: SvgPicture.asset(
                                        'assets/icons/ui/user.svg',
                                        width: 24,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow),
                                  ),
                                  Column(
                                    children: [
                                      // - icon at left (40px) and horizontal padding (12px*2)
                                      SizedBox(
                                        width: Get.size.width > 800
                                            ? 720 - 64
                                            : Get.size.width - 32 - 64,
                                        child: TextField(
                                          autocorrect: false,
                                          controller:
                                              _textEditingControllerSurname,
                                          style: TextStyle(
                                              color: Get.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Colors.grey,
                                          decoration: InputDecoration(
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Get.isDarkMode
                                                    ? lighterColorFrom(
                                                        color: AppTheme
                                                            .appDarkTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.1)
                                                    : darkerColorFrom(
                                                        color: AppTheme
                                                            .appTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.1),
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Get.isDarkMode
                                                    ? lighterColorFrom(
                                                        color: AppTheme
                                                            .appDarkTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.3)
                                                    : darkerColorFrom(
                                                        color: AppTheme
                                                            .appTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.3),
                                              ),
                                            ),
                                            hintText: 'Surname',
                                            hintStyle: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .shadow,
                                                fontSize: 18),
                                            suffixIcon: SizedBox(
                                              width: 24,
                                              child: Center(
                                                child: ScaleTap(
                                                  onPressed: () {
                                                    Fluttertoast.showToast(
                                                      msg: "Required field",
                                                      toastLength:
                                                          Toast.LENGTH_LONG,
                                                      gravity:
                                                          ToastGravity.BOTTOM,
                                                      timeInSecForIosWeb: 3,
                                                      textColor: Colors.white,
                                                      backgroundColor:
                                                          Get.isDarkMode
                                                              ? AppTheme
                                                                  .appDarkTheme
                                                                  .colorScheme
                                                                  .error
                                                              : AppTheme
                                                                  .appTheme
                                                                  .colorScheme
                                                                  .error,
                                                      fontSize: 16.0,
                                                    );
                                                  },
                                                  scaleMinValue: 0.9,
                                                  opacityMinValue: 0.4,
                                                  scaleCurve: Curves.decelerate,
                                                  opacityCurve:
                                                      Curves.fastOutSlowIn,
                                                  child: SvgPicture.asset(
                                                    'assets/icons/ui/alert-circle.svg',
                                                    width: 20,
                                                    color: Get.isDarkMode
                                                        ? AppTheme.appDarkTheme
                                                            .colorScheme.error
                                                        : AppTheme.appTheme
                                                            .colorScheme.error,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                  ),
                                  Column(
                                    children: [
                                      // - icon at left
                                      Container(
                                        width: Get.size.width > 800
                                            ? 720 - 64
                                            : Get.size.width - 32 - 64,
                                        child: TextField(
                                          autocorrect: false,
                                          controller:
                                              _textEditingControllerName,
                                          style: TextStyle(
                                              color: Get.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Colors.grey,
                                          decoration: InputDecoration(
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Get.isDarkMode
                                                    ? lighterColorFrom(
                                                        color: AppTheme
                                                            .appDarkTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.1)
                                                    : darkerColorFrom(
                                                        color: AppTheme
                                                            .appTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.1),
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Get.isDarkMode
                                                    ? lighterColorFrom(
                                                        color: AppTheme
                                                            .appDarkTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.3)
                                                    : darkerColorFrom(
                                                        color: AppTheme
                                                            .appTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.3),
                                              ),
                                            ),
                                            hintText: 'Name',
                                            hintStyle: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .shadow,
                                                fontSize: 18),
                                            suffixIcon: SizedBox(
                                              width: 24,
                                              child: Center(
                                                child: ScaleTap(
                                                  onPressed: () {
                                                    Fluttertoast.showToast(
                                                      msg: "Required field",
                                                      toastLength:
                                                          Toast.LENGTH_LONG,
                                                      gravity:
                                                          ToastGravity.BOTTOM,
                                                      timeInSecForIosWeb: 3,
                                                      textColor: Colors.white,
                                                      backgroundColor:
                                                          Get.isDarkMode
                                                              ? AppTheme
                                                                  .appDarkTheme
                                                                  .colorScheme
                                                                  .error
                                                              : AppTheme
                                                                  .appTheme
                                                                  .colorScheme
                                                                  .error,
                                                      fontSize: 16.0,
                                                    );
                                                  },
                                                  scaleMinValue: 0.9,
                                                  opacityMinValue: 0.4,
                                                  scaleCurve: Curves.decelerate,
                                                  opacityCurve:
                                                      Curves.fastOutSlowIn,
                                                  child: SvgPicture.asset(
                                                    'assets/icons/ui/alert-circle.svg',
                                                    width: 20,
                                                    color: Get.isDarkMode
                                                        ? AppTheme.appDarkTheme
                                                            .colorScheme.error
                                                        : AppTheme.appTheme
                                                            .colorScheme.error,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                  ),
                                  Column(
                                    children: [
                                      // - icon at left
                                      Container(
                                        width: Get.size.width > 800
                                            ? 720 - 64
                                            : Get.size.width - 32 - 64,
                                        child: TextField(
                                          autocorrect: false,
                                          controller:
                                              _textEditingControllerPatronymic,
                                          style: TextStyle(
                                              color: Get.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Colors.grey,
                                          decoration: InputDecoration(
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Get.isDarkMode
                                                    ? lighterColorFrom(
                                                        color: AppTheme
                                                            .appDarkTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.1)
                                                    : darkerColorFrom(
                                                        color: AppTheme
                                                            .appTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.1),
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Get.isDarkMode
                                                    ? lighterColorFrom(
                                                        color: AppTheme
                                                            .appDarkTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.3)
                                                    : darkerColorFrom(
                                                        color: AppTheme
                                                            .appTheme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                        amount: 0.3),
                                              ),
                                            ),
                                            hintText: 'Patronymic',
                                            hintStyle: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .shadow,
                                                fontSize: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Get.isDarkMode
                                ? AppTheme
                                    .appDarkTheme.colorScheme.surfaceVariant
                                : AppTheme.appTheme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                child: SvgPicture.asset(
                                    'assets/icons/ui/phone.svg',
                                    width: 24,
                                    color:
                                        Theme.of(context).colorScheme.shadow),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 12),
                                width: Get.size.width > 800
                                    ? 720 - 64 - 12
                                    : Get.size.width - 32 - 64 - 12,
                                child: InternationalPhoneNumberInput(
                                  textFieldController:
                                      _textEditingControllerPhone,
                                  spaceBetweenSelectorAndTextField: 0,
                                  onInputChanged: (PhoneNumber number) {
                                    print(number.phoneNumber);
                                  },
                                  onInputValidated: (bool value) {
                                    print(value);
                                  },
                                  searchBoxDecoration: InputDecoration(
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant,
                                    filled: true,
                                    contentPadding: const EdgeInsets.all(0),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none),
                                    hintText:
                                        'Search by country name or dial code',
                                    hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow,
                                        fontSize: 18),
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(15),
                                      width: 18,
                                      child: Icon(
                                        Icons.search,
                                        size: 26,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow,
                                      ),
                                    ),
                                  ),
                                  selectorConfig: SelectorConfig(
                                    setSelectorButtonAsPrefixIcon: true,
                                    selectorType:
                                        PhoneInputSelectorType.BOTTOM_SHEET,
                                  ),
                                  ignoreBlank: false,
                                  autoValidateMode: AutovalidateMode.disabled,
                                  selectorTextStyle: Get.isDarkMode
                                      ? AppTheme.appDarkTheme.textTheme.button
                                      : AppTheme.appTheme.textTheme.button
                                          ?.copyWith(color: Colors.black),
                                  initialValue: number,
                                  inputBorder: UnderlineInputBorder(),
                                  textStyle: Get.isDarkMode
                                      ? AppTheme
                                          .appDarkTheme.textTheme.bodyText1
                                      : AppTheme.appTheme.textTheme.bodyText1,
                                  cursorColor: Color(0xff9c9fa3),
                                  inputDecoration: InputDecoration(
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Get.isDarkMode
                                            ? lighterColorFrom(
                                                color: AppTheme.appDarkTheme
                                                    .colorScheme.surfaceVariant,
                                                amount: 0.1)
                                            : darkerColorFrom(
                                                color: AppTheme.appTheme
                                                    .colorScheme.surfaceVariant,
                                                amount: 0.1),
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Get.isDarkMode
                                            ? lighterColorFrom(
                                                color: AppTheme.appDarkTheme
                                                    .colorScheme.surfaceVariant,
                                                amount: 0.3)
                                            : darkerColorFrom(
                                                color: AppTheme.appTheme
                                                    .colorScheme.surfaceVariant,
                                                amount: 0.3),
                                      ),
                                    ),
                                    hintText: 'Phone number',
                                    hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow,
                                        fontSize: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        AppTextField(
                          textEditingController: _textEditingControllerBornDate,
                          hint: 'Birthday',
                          svgIconPath: 'calendar-dates',
                          isRequired: true,
                        ),
                        SizedBox(height: 16),
                        AppTextField(
                          textEditingController: _textEditingControllerBornDate,
                          hint: 'Mobile',
                          svgIconPath: 'phone',
                        ),
                        SizedBox(height: 16),
                        AppTextField(
                            textEditingController:
                                _textEditingControllerBornDate,
                            hint: 'E-mail',
                            svgIconPath: 'email'),
                        SizedBox(height: 16),
                        AppTextField(
                            textEditingController:
                                _textEditingControllerBornDate,
                            hint: 'Weight',
                            svgIconPath: 'weighter'),
                        SizedBox(height: 48),
                        AppBottom(
                          onPressed: () => null,
                          mainText: 'Done',
                          secondaryText: 'Cancel',
                          onSecondaryButtonPressed: () => null,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ));
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                  child: ListView(
                scrollDirection: Axis.vertical,
                children: [],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getLoggedInUserDBAsync() async {
    var user = await userOperations.getLoggedInUser();
    if (user != null) {
      _loggedInUser = user;
    } else {
      Get.off(() => UserRegistrationScreen());
    }
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final String hint;
  final String svgIconPath;
  bool? isRequired;
  AppTextField({
    Key? key,
    required this.textEditingController,
    required this.hint,
    required this.svgIconPath,
    this.isRequired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppTheme.appDarkTheme.colorScheme.surfaceVariant
            : AppTheme.appTheme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            child: SvgPicture.asset('assets/icons/ui/$svgIconPath.svg',
                width: 24, color: Theme.of(context).colorScheme.shadow),
          ),
          Column(
            children: [
              // - icon at left (40px) and horizontal padding (12px*2)
              SizedBox(
                width:
                    Get.size.width > 800 ? 720 - 64 : Get.size.width - 32 - 64,
                child: TextField(
                  autocorrect: false,
                  controller: textEditingController,
                  style: TextStyle(
                      color: Get.isDarkMode ? Colors.white : Colors.black),
                  cursorColor: Colors.grey,
                  decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Get.isDarkMode
                              ? lighterColorFrom(
                                  color: AppTheme
                                      .appDarkTheme.colorScheme.surfaceVariant,
                                  amount: 0.1)
                              : darkerColorFrom(
                                  color: AppTheme
                                      .appTheme.colorScheme.surfaceVariant,
                                  amount: 0.1),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Get.isDarkMode
                              ? lighterColorFrom(
                                  color: AppTheme
                                      .appDarkTheme.colorScheme.surfaceVariant,
                                  amount: 0.3)
                              : darkerColorFrom(
                                  color: AppTheme
                                      .appTheme.colorScheme.surfaceVariant,
                                  amount: 0.3),
                        ),
                      ),
                      hintText: hint,
                      hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.shadow,
                          fontSize: 18),
                      suffixIcon: isRequired == true
                          ? SizedBox(
                              width: 24,
                              child: Center(
                                child: ScaleTap(
                                  onPressed: () {
                                    Fluttertoast.showToast(
                                      msg: "Required field",
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 3,
                                      textColor: Colors.white,
                                      backgroundColor: Get.isDarkMode
                                          ? AppTheme
                                              .appDarkTheme.colorScheme.error
                                          : AppTheme.appTheme.colorScheme.error,
                                      fontSize: 16.0,
                                    );
                                  },
                                  scaleMinValue: 0.9,
                                  opacityMinValue: 0.4,
                                  scaleCurve: Curves.decelerate,
                                  opacityCurve: Curves.fastOutSlowIn,
                                  child: SvgPicture.asset(
                                    'assets/icons/ui/alert-circle.svg',
                                    width: 20,
                                    color: Get.isDarkMode
                                        ? AppTheme
                                            .appDarkTheme.colorScheme.error
                                        : AppTheme.appTheme.colorScheme.error,
                                  ),
                                ),
                              ),
                            )
                          : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
