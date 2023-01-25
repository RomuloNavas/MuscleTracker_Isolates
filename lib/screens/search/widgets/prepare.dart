import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/screens/search/search_screen.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header_info.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_screen_bottom.dart';

class GetReadyScreen extends StatelessWidget {
  final Function() notifyParentStartDiscovery;
  final GetxControllerServices servicesManager;

  const GetReadyScreen({
    Key? key,
    required this.servicesManager,
    required this.notifyParentStartDiscovery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppHeaderInfo(
              title: "Let's connect to your Callibri sensors",
              label: 'Make sure that they are near, turned on and charged',
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                width: 360,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/devices_turned_on.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            AppScreenBottom(
              onPressed: () {
                FlutterBluetoothSerial.instance.isEnabled.then((value) {
                  if (value == true) {
                    notifyParentStartDiscovery();
                  } else {
                    servicesManager.requestBluetoothAndGPS();
                  }
                });
              },
              mainText: 'Start scanning',
            )
          ],
        ),
      ),
    );
  }
}
