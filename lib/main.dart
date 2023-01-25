import 'package:flutter/material.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor__operations.dart';
import 'package:neuro_sdk_isolate_example/screens/search/get_ready_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/search/search_screen.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

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
    initRegisteredSensors = initRegisteredSensorsAsync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.appTheme,
      darkTheme: AppTheme.appDarkTheme,
      home: FutureBuilder<List<RegisteredSensor>?>(
        future: initRegisteredSensors,
        builder: (context, AsyncSnapshot<List<RegisteredSensor>?> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const SearchScreen();
            } else {
              return Container(
                color: Colors.pink,
              );
            }
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Future<List<RegisteredSensor>?> initRegisteredSensorsAsync() async {
    var registeredSensors =
        await registeredSensorOperations.getAllRegisteredSensors();
    return registeredSensors;
  }
}
