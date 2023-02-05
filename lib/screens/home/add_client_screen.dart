import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/search_controller.dart';
import 'package:neuro_sdk_isolate_example/screens/user_registration/user_registration_screen.dart';
import 'dart:async';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  late TextEditingController _textEditingController;

  // Async load data on init:
  final clientOperations = ClientOperations();
  final userOperations = UserOperations();
  late User _loggedInUser;
  late Future initRegisteredClients;
  late Future initUserAccount;

  @override
  void initState() {
    super.initState();

    initUserAccount = _getLoggedInUserDBAsync();
    initController();

    _textEditingController = TextEditingController();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  bool _isLoading = true;

  void initController() async {}

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
          backgroundColor: Color(0xfff2f3f5),
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
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const AppHeaderInfo(
                      title: "Let's create a new client",
                      labelPrimary:
                          "Fill up the required files with client's information",
                    ),
                    AppTextFieldSmall(
                        hint: 'Name',
                        hintIcon: Icons.near_me,
                        textEditingController: TextEditingController())
                  ],
                ),
              ),
            ],
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
