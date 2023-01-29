// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
// import 'package:neuro_sdk_isolate_example/screens/sensor/sensor_screen.dart';
// import '../controllers/search_controller.dart';

// class SearchScreenBody extends StatefulWidget {
//   const SearchScreenBody({super.key});

//   @override
//   State<SearchScreenBody> createState() => _SearchScreenBodyState();
// }

// class _SearchScreenBodyState extends State<SearchScreenBody> {
//   final SearchController _searchController = SearchController();
//   late StreamSubscription _subscription;

//   final List<SensorInfo> _foundSensorsWithCallback = [];
//   final List<SensorInfo> _foundSensorsWithGet = [];

//   bool _isWaitingGet = false;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     initController();
//   }

//   void initController() async {
//     await _searchController.init();
//     _subscription = _searchController.foundSensorsStream.listen((sensors) {
//       setState(() {
//         _foundSensorsWithCallback.clear();
//         _foundSensorsWithCallback.addAll(sensors);
//       });
//     });

//     setState(() {
//       _isLoading = false;
//     });
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _subscription.cancel();
//     _searchController.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(semanticsLabel: "Инициализация сканера..."),
//       );
//     }

//     if (!_searchController.isAllPermissionGranted) {
//       return const Center(
//         child: Text("Необходимо предоставить разрешения!"),
//       );
//     }

//     return Column(
//       children: [
//         ElevatedButton(onPressed: _searchController.dispose, child: const Text("Dispose")),
//         const Center(
//           child: Text("Поиск через callback и stream"),
//         ),
//         ElevatedButton(
//           onPressed: _onStreamSearchButtonPressed,
//           child: _searchController.isScanning ? const Text('Остановить поиск') : const Text("Начать поиск"),
//         ),
//         _buildSensorsList(_foundSensorsWithCallback),
//         const Center(
//           child: Text("Поиск через sensorsScanner"),
//         ),
//         ElevatedButton(
//           onPressed: _onGetButtonPressed,
//           child: _isWaitingGet ? const CircularProgressIndicator() : const Text("Найти"),
//         ),
//         _buildSensorsList(_foundSensorsWithGet)
//       ],
//     );
//   }

//   Widget _buildSensorsList(List<SensorInfo> list) {
//     return ListView.separated(
//       shrinkWrap: true,
//       scrollDirection: Axis.vertical,
//       itemBuilder: (context, index) {
//         final sensor = list[index];
//         return ListTile(
//           title: Text('${sensor.name} (${sensor.address})'),
//           onTap: () => _openSensorScreen(sensor),
//         );
//       },
//       separatorBuilder: (context, index) => const Divider(),
//       itemCount: list.length,
//     );
//   }

//   void _onStreamSearchButtonPressed() {
//     _searchController.toggleSearch();
//     setState(() {});
//   }

//   void _onGetButtonPressed() async {
//     setState(() {
//       _isWaitingGet = true;
//       _foundSensorsWithGet.clear();
//     });

//     final list = await _searchController.getSensors();

//     setState(() {
//       _isWaitingGet = false;
//       _foundSensorsWithGet.addAll(list);
//     });
//   }

//   void _openSensorScreen(SensorInfo info) {
//     _searchController.stopScanner();

//     Navigator.of(context).push(MaterialPageRoute(
//       builder: (context) => SensorScreen(sensorInfo: info),
//     ));

//     _foundSensorsWithCallback.clear();
//     _foundSensorsWithGet.clear();

//     setState(() {});
//   }
// }
