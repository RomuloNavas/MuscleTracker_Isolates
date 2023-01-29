// import 'dart:async';
// import 'dart:developer';
// import 'package:get/get.dart';
// import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
// import 'package:neuro_sdk_isolate_example/database/placement_operations.dart';
// import 'package:neuro_sdk_isolate_example/screens/client_journal/session/session_monitor_screen.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class SensorUsedInSession {
//   SensorUsedInSession({
//     required this.sensor,
//     this.placement,
//     this.isSelectedToAssignPlacement = false,
//     this.chartSeriesController,
//     this.columnChartSeriesController,
//     this.isConnected = true,
//     this.countLastElectrodeState = 0,
//     this.electrodeState = CallibriElectrodeState.elStNormal,
//     this.signalForCheckingSensorState = 0,
//     this.xValueCounter = 0,
//     required this.listEnvSamplesValuesForGraphic,
//     required this.envelopeValuesForAnalytics,
//     required this.chartData,
//     required this.columnChartData,
//   });

//   final Sensor sensor;
//   Placement? placement;
//   bool isSelectedToAssignPlacement = false;
//   bool isConnected;
//   int countLastElectrodeState;
//   CallibriElectrodeState electrodeState;
//   int xValueCounter;
//   ChartSeriesController? chartSeriesController;
//   ChartSeriesController? columnChartSeriesController;
//   List<double> listEnvSamplesValuesForGraphic;
//   int signalForCheckingSensorState;
//   List<ChartSampleData> chartData;
//   List<ChartSampleData> columnChartData;
//   EnvelopeValuesForAnalytics envelopeValuesForAnalytics;
// }

// class EnvelopeValuesForAnalytics {
//   EnvelopeValuesForAnalytics({
//     required this.address,
//     required this.listEnvSamplesValuesForStatistics,
//     this.countSamplesFromSensor = 0,
//     this.countCerosAdded = 0,
//     this.countRemovedValues = 0,
//     this.isConnected = true,
//   });
//   final String address;
//   List<double> listEnvSamplesValuesForStatistics;
//   int countSamplesFromSensor;
//   int countRemovedValues;
//   int countCerosAdded;
//   bool isConnected;
// }

// // This class if for discovered devices that haven't been connected yet.
// class SensorForSessionSetup {
//   SensorForSessionSetup({
//     required this.sensorInfo,
//     this.placement,
//     this.isSelectedToAssignPlacement = false,
//   });
//   SensorInfo sensorInfo;
//   Placement? placement;
//   bool isSelectedToAssignPlacement = false;
// }

// class MANAGERWorkoutSetup extends GetxController {
//   @override
//   void onInit() {
//     // startScanning();
//     super.onInit();
//   }

//   //This screen will search for devices till it finds them. In dispose() and onClose() the timer is closed
//   // so it will not work anymore when you change from screen.
//   @override
//   void dispose() {
//     timer!.cancel();
//     super.dispose();
//   }

//   @override
//   void onClose() {
//     timer?.cancel();
//     super.onClose();
//   }

//   /// Variables required for the UI in the app

//   double sidebarWidth = 300;
//   double muscleCardSize = 180;
//   late Client client;

//   /// Connection variables

//   final Scanner _scanner = Scanner(filters: [SensorFamily.leCallibri]);

//   RxList<SensorForSessionSetup> registeredAndDiscoveredSensorsToConnect =
//       <SensorForSessionSetup>[].obs;

//   RxList<SensorUsedInSession> connectedSensorsUsedInSession =
//       <SensorUsedInSession>[].obs;
//   SensorUsedInSession? selectedSensor = null;

//   //Phone restarts scanning each 2 seconds, otherwise, user should press button
//   //constantly because mobile doesn't always show devices at first.
//   Timer? timer;

//   void startScanning() async {
//     log('Starting scanner...', name: 'Start Scanning (MANAGERWorkoutSetup)');
//     registeredAndDiscoveredSensorsToConnect.clear();
//     for (var connectedSensor in connectedSensorsUsedInSession) {
//       connectedSensor.sensor.disconnectSensor();
//     }

//     connectedSensorsUsedInSession.clear();

//     List<RegisteredSensor>? savedDevice =
//         await RegisteredSensorOperations().getAllRegisteredSensors();

//     final List<String?> savedDevicesAddresses =
//         savedDevice!.map((e) => e.address).toList();

//     _scanner.scannerCallback = (List<SensorInfo> discoveredSensors) {
//       log('Discovered Callibri: ${discoveredSensors.length}');
//       List<SensorForSessionSetup> listRegisteredAndDiscovered = [];
//       for (var sensorInfo in discoveredSensors) {
//         // Add only the sensor if it was registered
//         if (savedDevicesAddresses.contains(sensorInfo.address)) {
//           SensorForSessionSetup sensorForSessionSetup =
//               SensorForSessionSetup(sensorInfo: sensorInfo);
//           listRegisteredAndDiscovered.add(sensorForSessionSetup);
//         }
//       }
//       registeredAndDiscoveredSensorsToConnect.value =
//           listRegisteredAndDiscovered;
//       registeredAndDiscoveredSensorsToConnect.refresh();
//     };

//     timer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
//       if (registeredAndDiscoveredSensorsToConnect.isEmpty) {
//         {
//           log('Scanner started', name: 'Start Scanning (MANAGERWorkoutSetup)');
//           _scanner.stopScanner();
//           _scanner.startScanner();
//         }
//       } else {
//         t.cancel();
//         timer?.cancel();
//         Future.delayed(const Duration(seconds: 5), () async {
//           _scanner.stopScanner();
//           List<SensorUsedInSession> sensorsForMonitoring = [];
//           for (SensorForSessionSetup sensorForSessionSetup
//               in registeredAndDiscoveredSensorsToConnect) {
//             log('Connecting to ${sensorForSessionSetup.sensorInfo.name}...');

//             Sensor sensor = Sensor(_scanner, sensorForSessionSetup.sensorInfo);
//             sensor.connectSensor();

//             final sensorForMonitoring = SensorUsedInSession(
//               sensor: sensor,
//               listEnvSamplesValuesForGraphic: [0.0],
//               chartData: [ChartSampleData(x: 0, y: 0)],
//               columnChartData: [ChartSampleData(x: 0, y: 0)],
//               envelopeValuesForAnalytics: EnvelopeValuesForAnalytics(
//                 address: sensor.address,
//                 listEnvSamplesValuesForStatistics: [],
//               ),
//             );
//             sensorsForMonitoring.add(sensorForMonitoring);
//           }
//           connectedSensorsUsedInSession.value = sensorsForMonitoring;
//         });
//       }
//     });

//     update();
//   }

//   void stopScanning() {
//     _scanner.stopScanner();
//     timer?.cancel();
//     log('Scanner Stopped');
//     update();
//   }
// }
