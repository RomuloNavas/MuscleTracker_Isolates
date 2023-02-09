import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/home/home_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/search_screen.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_bottom.dart';

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
            FutureBuilder(
              future: UserOperations().getLoggedInUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return AppHeaderInfo(
                    title:
                        "Welcome ${snapshot.data!.name}! Let's add your Callibri sensors",
                    labelPrimary: 'Please, turn on your sensors.',
                  );
                } else {
                  return SizedBox();
                }
              },
            ),
            Expanded(
              child: SvgPicture.asset(
                'assets/illustrations/turn-on.svg',
              ),
            ),
            AppBottom(
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
              
              secondaryText: 'Add sensors later',
              secondaryTextColor: Theme.of(context).colorScheme.error,
              onSecondaryButtonPressed: () => Get.off(() => HomeScreen()),
            )
          ],
        ),
      ),
    );
  }
}
