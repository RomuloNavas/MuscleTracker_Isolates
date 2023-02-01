import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/database/body_region_operations.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
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

  late Future<List<RegisteredSensor>?> initRegisteredSensors;

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
        themeMode: ThemeMode.system,
        theme: AppTheme.appTheme,
        darkTheme: AppTheme.appDarkTheme,
        home: UserRegistrationScreen()
        // home: FutureBuilder<List<RegisteredSensor>?>(
        //   future: initRegisteredSensors,
        //   builder: (context, AsyncSnapshot<List<RegisteredSensor>?> snapshot) {
        //     if (snapshot.connectionState == ConnectionState.done &&
        //         snapshot.hasData) {
        //       if (snapshot.data!.isEmpty) {
        //         return const SearchScreen();
        //       } else {
        //         return HomeScreen();
        //       }
        //     } else {
        //       return Scaffold(
        //         body: Center(child: CircularProgressIndicator()),
        //       );
        //     }
        //   },
        // ),
        );
  }

  Future<List<RegisteredSensor>?> initApp() async {
    var registeredSensors =
        await registeredSensorOperations.getAllRegisteredSensors();
    // INIT THE TEST VALUES FOR DATABASE:
    await ClientOperations().initTestClients();
    await ExerciseOperations().initWorkouts();
    await BodyRegionOperations().initBodyRegions();
    await PlacementOperations().initPlacements();

    return registeredSensors;
  }
}
