import 'dart:developer';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/home/home_screen.dart';
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
  late TextEditingController _textEditingControllerBirthday;
  late TextEditingController _textEditingControllerWeight;
  late TextEditingController _textEditingControllerMobile;
  late TextEditingController _textEditingControllerEmail;

  // - keys
  final _formKeySurname = GlobalKey<FormState>();
  final _formKeyName = GlobalKey<FormState>();
  final _formKeyBirthday = GlobalKey<FormState>();
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyWeight = GlobalKey<FormState>();
  final _formKeyMobile = GlobalKey<FormState>();

  // Async load data on init:
  final clientOperations = ClientOperations();
  final userOperations = UserOperations();
  late User _loggedInUser;
  late Future initUserAccount;
  late List<TextInputFormatter> _textInputFormatterFullName;

  PhoneNumber number = PhoneNumber(isoCode: 'RU');
  @override
  void initState() {
    super.initState();

    initUserAccount = _getLoggedInUserDBAsync();

    _textInputFormatterFullName = [
      FilteringTextInputFormatter.allow(RegExp("[a-zA-ZЁёА-яء-ي]")),
      LengthLimitingTextInputFormatter(50),
    ];
    _textEditingControllerName = TextEditingController();
    _textEditingControllerSurname = TextEditingController();
    _textEditingControllerPatronymic = TextEditingController();
    _textEditingControllerBirthday = TextEditingController();
    _textEditingControllerEmail = TextEditingController();
    _textEditingControllerWeight = TextEditingController();

    _textEditingControllerMobile = TextEditingController();

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
          titleSpacing: 8.0,
          automaticallyImplyLeading: false,
          leading: ScaleTap(
            onPressed: () => Get.back(),
            scaleMinValue: 0.9,
            opacityMinValue: 0.4,
            scaleCurve: Curves.decelerate,
            opacityCurve: Curves.fastOutSlowIn,
            child: Container(
              width: 48,
              height: 48,
              color: Colors.transparent,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/ui/arrow-left.svg',
                  width: 32,
                  color: Get.isDarkMode
                      ? AppTheme.appDarkTheme.colorScheme.tertiary
                      : AppTheme.appTheme.colorScheme.tertiary,
                ),
              ),
            ),
          ),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Get.isDarkMode
                              ? AppTheme.appDarkTheme.colorScheme.surfaceVariant
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
                                      color:
                                          Theme.of(context).colorScheme.shadow),
                                ),
                                Column(
                                  children: [
                                    // - icon at left (40px) and horizontal padding (12px*2)
                                    SizedBox(
                                      width: Get.size.width > 800
                                          ? 720 - 64
                                          : Get.size.width - 32 - 64,
                                      child: Form(
                                        key: _formKeySurname,
                                        child: TextFormField(
                                          autocorrect: false,
                                          controller:
                                              _textEditingControllerSurname,
                                          autovalidateMode:
                                              AutovalidateMode.always,
                                          validator: (value) {
                                            if (value != null) {
                                              if (value == '') {
                                                return "Surname is required";
                                              } else {
                                                return null;
                                              }
                                            } else {
                                              return "Surname is required";
                                            }
                                          },
                                          style: TextStyle(
                                              color: Get.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Colors.grey,
                                          inputFormatters:
                                              _textInputFormatterFullName,
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
                                      child: Form(
                                        key: _formKeyName,
                                        child: TextFormField(
                                          autocorrect: false,
                                          controller:
                                              _textEditingControllerName,
                                          inputFormatters:
                                              _textInputFormatterFullName,
                                          autovalidateMode:
                                              AutovalidateMode.always,
                                          validator: (value) {
                                            if (value != null) {
                                              if (value == '') {
                                                return "Name is required";
                                              } else {
                                                return null;
                                              }
                                            } else {
                                              return "Name is required";
                                            }
                                          },
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
                                      child: TextFormField(
                                        autocorrect: false,
                                        controller:
                                            _textEditingControllerPatronymic,
                                        inputFormatters:
                                            _textInputFormatterFullName,
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
                      const SizedBox(height: 16),
                      AppTextField(
                        textEditingController: _textEditingControllerBirthday,
                        autovalidateMode: AutovalidateMode.always,
                        hint: 'Birthday: DD/MM/YYYY',
                        svgIconPath: 'calendar-dates',
                        keyboardType: TextInputType.datetime,
                        globalKey: _formKeyBirthday,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp("[0-9/]")),
                          LengthLimitingTextInputFormatter(10),
                          _DateFormatter(),
                        ],
                        validator: (value) {
                          if (value != null) {
                            int numberOfSlashes = 0;
                            List<String> letters = value.split('');
                            for (var letter in letters) {
                              if (letter == '/') {
                                numberOfSlashes++;
                              }
                            }
                            if (value.isEmpty) {
                              return 'Birthday date is required';
                            } else if (numberOfSlashes > 2) {
                              return 'Write only digits';
                            } else {
                              return null;
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                              child: SvgPicture.asset(
                                  'assets/icons/ui/phone.svg',
                                  width: 24,
                                  color: Theme.of(context).colorScheme.shadow),
                            ),
                            Container(
                              width: Get.size.width > 800
                                  ? 720 - 64
                                  : Get.size.width - 32 - 64,
                              child: Form(
                                key: _formKeyMobile,
                                child: InternationalPhoneNumberInput(
                                  textFieldController:
                                      _textEditingControllerMobile,
                                  ignoreBlank: true,
                                  spaceBetweenSelectorAndTextField: 12,
                                  selectorButtonOnErrorPadding:
                                      23, //Padding at bottom of selector on error message.
                                  cursorColor: Color(0xff9c9fa3),
                                  onInputChanged: (PhoneNumber number) {
                                    print(number.phoneNumber);
                                  },
                                  onInputValidated: (bool value) {
                                    print(value);
                                  },

                                  initialValue: number,
                                  selectorConfig: SelectorConfig(
                                    leadingPadding: 12, // Padding at left
                                    trailingSpace: false,

                                    setSelectorButtonAsPrefixIcon: false,
                                    selectorType:
                                        PhoneInputSelectorType.BOTTOM_SHEET,
                                  ),
                                  selectorTextStyle: Get.isDarkMode
                                      ? AppTheme.appDarkTheme.textTheme.button
                                      : AppTheme.appTheme.textTheme.button
                                          ?.copyWith(color: Colors.black),

                                  autoValidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  inputBorder: UnderlineInputBorder(),
                                  textStyle: Get.isDarkMode
                                      ? AppTheme
                                          .appDarkTheme.textTheme.bodyText1
                                      : AppTheme.appTheme.textTheme.bodyText1,
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
                                  // - UI of search text field
                                  searchBoxDecoration: InputDecoration(
                                    fillColor: AppTheme.appDarkTheme.colorScheme
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
                                      width: 40,
                                      child: Center(
                                        child: SvgPicture.asset(
                                            'assets/icons/ui/search.svg',
                                            width: 24,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .shadow),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                          textEditingController: _textEditingControllerEmail,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          globalKey: _formKeyEmail,
                          hint: 'E-mail',
                          svgIconPath: 'email',
                          validator: (email) {
                            if (email != null) {
                              var isValid = EmailValidator.validate(email);
                              if (email.isEmpty) {
                                return null;
                              }
                              if (isValid == false) {
                                return 'Enter a valid e-mail';
                              } else {
                                return null;
                              }
                            } else {
                              return null;
                            }
                          }),
                      const SizedBox(height: 16),
                      AppTextField(
                          textEditingController: _textEditingControllerWeight,
                          keyboardType: TextInputType.phone,
                          globalKey: _formKeyWeight,
                          hint: 'Weight in Kilograms',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp("[0-9.]")),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          validator: (value) {
                            if (value != null) {
                              int numberOfSlashes = 0;
                              List<String> letters = value.split('');
                              for (var letter in letters) {
                                if (letter == '.') {
                                  numberOfSlashes++;
                                }
                              }
                              if (numberOfSlashes > 1) {
                                return "Only one dot allowed";
                              } else {
                                return null;
                              }
                            }
                          },
                          svgIconPath: 'weighter'),
                      const SizedBox(height: 48),
                      AppBottom(
                        onPressed: () {
                          final isValidBirthday =
                              _formKeyBirthday.currentState != null
                                  ? _formKeyBirthday.currentState!.validate()
                                  : false;
                          final isValidName = _formKeyName.currentState != null
                              ? _formKeyName.currentState!.validate()
                              : false;
                          final isValidSurname =
                              _formKeySurname.currentState != null
                                  ? _formKeySurname.currentState!.validate()
                                  : false;
                          final isValidEmail =
                              _formKeyEmail.currentState != null
                                  ? _formKeyEmail.currentState!.validate()
                                  : true;
                          final isValidMobile =
                              _formKeyMobile.currentState != null
                                  ? _formKeyMobile.currentState!.validate()
                                  : true;
                          final isValidWeight =
                              _formKeyWeight.currentState != null
                                  ? _formKeyWeight.currentState!.validate()
                                  : true;

                          if (isValidBirthday &&
                              isValidSurname &&
                              isValidName &&
                              isValidEmail &&
                              isValidMobile &&
                              isValidWeight) {
                            int userId = _loggedInUser.id!;
                            var inputFormat = DateFormat('dd/MM/yyyy');
                            var dateDMY = inputFormat
                                .parse(_textEditingControllerBirthday.text);
                            var outputFormat = DateFormat('yyyy-MM-dd');
                            var dateYMD = outputFormat.format(dateDMY);

                            var client = Client(
                              userId: userId,
                              name: _textEditingControllerName.text,
                              surname: _textEditingControllerSurname.text,
                              patronymic: _textEditingControllerPatronymic.text,
                              birthday: dateYMD,
                              registrationDate:
                                  DateTime.now().toIso8601String(),
                              weight:
                                  _textEditingControllerWeight.text.isNotEmpty
                                      ? double.tryParse(
                                          _textEditingControllerWeight.text)
                                      : null,
                              email: _textEditingControllerEmail.text.isNotEmpty
                                  ? _textEditingControllerEmail.text
                                  : null,
                              mobile:
                                  _textEditingControllerMobile.text.isNotEmpty
                                      ? _textEditingControllerMobile.text
                                      : null,
                            );

                            ClientOperations().createClient(client);
                          } else {
                            Fluttertoast.showToast(
                              msg: "Please, correct the fields.",
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 3,
                              textColor: Colors.white,
                              backgroundColor: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.colorScheme.error
                                  : AppTheme.appTheme.colorScheme.error,
                              fontSize: 16.0,
                            );
                          }
                        },
                        mainText: 'Done',
                        secondaryText: 'Cancel',
                        onSecondaryButtonPressed: () => Get.back(),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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

class AppSuffixIconRequiredField extends StatelessWidget {
  const AppSuffixIconRequiredField({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                  ? AppTheme.appDarkTheme.colorScheme.error
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
                ? AppTheme.appDarkTheme.colorScheme.error
                : AppTheme.appTheme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final String hint;
  final List<TextInputFormatter>? inputFormatters;
  final String svgIconPath;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final AutovalidateMode? autovalidateMode;
  final GlobalKey<FormState>? globalKey;

  bool? isValid;
  AppTextField({
    Key? key,
    required this.textEditingController,
    required this.hint,
    required this.svgIconPath,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.autovalidateMode,
    this.isValid,
    this.globalKey,
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
                child: Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  key: globalKey,
                  child: TextFormField(
                    autocorrect: false,
                    controller: textEditingController,
                    inputFormatters: inputFormatters,
                    keyboardType: keyboardType,
                    autovalidateMode: autovalidateMode,
                    validator: validator,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue prevText, TextEditingValue currText) {
    int selectionIndex;

    // Get the previous and current input strings
    String pText = prevText.text;
    String cText = currText.text;
    // Abbreviate lengths
    int cLen = cText.length;
    int pLen = pText.length;

    if (cText.length > 0) {
      String? lastLetter = cText[cText.length - 1];
      if (lastLetter == '/') {
        selectionIndex = cText.length;
        return TextEditingValue(
          text: cText,
          selection: TextSelection.collapsed(offset: selectionIndex),
        );
      }
    }

    if (cLen == 1) {
      // Can only be 0, 1, 2 or 3
      if (int.parse(cText) > 3) {
        // Remove char
        cText = '';
      }
    } else if (cLen == 2 && pLen == 1) {
      // Days cannot be greater than 31
      int dd = int.parse(cText.substring(0, 2));
      if (dd == 0 || dd > 31) {
        // Remove char
        cText = cText.substring(0, 1);
      } else {
        // Add a / char
        cText += '/';
      }
    } else if (cLen == 4) {
      // Can only be 0 or 1
      if (int.parse(cText.substring(3, 4)) > 1) {
        // Remove char
        cText = cText.substring(0, 3);
      }
    } else if (cLen == 5 && pLen == 4) {
      // Month cannot be greater than 12
      int mm = int.parse(cText.substring(3, 5));
      if (mm == 0 || mm > 12) {
        // Remove char
        cText = cText.substring(0, 4);
      } else {
        // Add a / char
        cText += '/';
      }
    } else if ((cLen == 3 && pLen == 4) || (cLen == 6 && pLen == 7)) {
      // Remove / char
      cText = cText.substring(0, cText.length - 1);
    } else if (cLen == 3 && pLen == 2) {
      if (int.parse(cText.substring(2, 3)) > 1) {
        // Replace char
        cText = cText.substring(0, 2) + '/';
      } else {
        // Insert / char
        cText =
            cText.substring(0, pLen) + '/' + cText.substring(pLen, pLen + 1);
      }
    } else if (cLen == 6 && pLen == 5) {
      // Can only be 1 or 2 - if so insert a / char
      int y1 = int.parse(cText.substring(5, 6));
      if (y1 < 1 || y1 > 2) {
        // Replace char
        cText = cText.substring(0, 5) + '/';
      } else {
        // Insert / char
        cText = cText.substring(0, 5) + '/' + cText.substring(5, 6);
      }
    } else if (cLen == 7) {
      // Can only be 1 or 2
      int y1 = int.parse(cText.substring(6, 7));
      if (y1 < 1 || y1 > 2) {
        // Remove char
        cText = cText.substring(0, 6);
      }
    } else if (cLen == 8) {
      // Can only be 19 or 20
      int y2 = int.parse(cText.substring(6, 8));
      if (y2 < 19 || y2 > 20) {
        // Remove char
        cText = cText.substring(0, 7);
      }
    }

    selectionIndex = cText.length;
    return TextEditingValue(
      text: cText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
