import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/database/workout_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/home/home_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/search_screen.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

import 'screens/user_registration/user_registration_screen.dart';

void main() async {
  await SDKIsolate.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool shouldProceed = false;

  RegisteredSensorOperations registeredSensorOperations =
      RegisteredSensorOperations();

  bool _isLoading = true;
  User? _loggedUser;
  List<RegisteredSensor> _registeredSensors = [];

  late Future<void> initRegisteredSensors;

  @override
  void initState() {
    initRegisteredSensors = initApp();
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      // themeMode: ThemeMode.system,
      theme: AppTheme.appTheme,
      darkTheme: AppTheme.appDarkTheme,
      home: Builder(
        builder: (context) {
          if (_isLoading)
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          else {
            if (_loggedUser == null) {
              return UserRegistrationScreen();
            } else if (_registeredSensors.isEmpty) {
              return const SearchScreen();
            } else {
              return HomeScreen();
            }
          }
        },
      ),
    );
  }

  Future<void> initApp() async {
    final allUsers = await UserOperations().getAllUsers();
    if (allUsers.isNotEmpty) {
      _loggedUser = allUsers.first;
      _registeredSensors = await registeredSensorOperations
          .getRegisteredSensorsByUser(_loggedUser!);
    }

    // INIT THE TEST VALUES FOR DATABASE:
    await ClientOperations().initTestClients();
    await ExerciseOperations().initWorkouts();
    await BodyRegionOperations().initBodyRegions();
    await PlacementOperations().initPlacements();
    setState(() {
      _isLoading = false;
    });
  }
}
