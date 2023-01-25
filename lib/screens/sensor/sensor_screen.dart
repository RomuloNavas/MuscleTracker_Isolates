import 'package:flutter/material.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor/widgets/sensor_screen_body.dart';

class SensorScreen extends StatelessWidget {
  final List<SensorInfo> sensorsInfo;
  const SensorScreen({super.key, required this.sensorsInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SensorScreenBody(sensorsInfo: sensorsInfo),
    );
  }
}
