import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/database/users_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/client_journal/client_history_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/home/add_client_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/search_controller.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/search_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/widgets/modal_bottom_sheet.dart';
import 'package:neuro_sdk_isolate_example/screens/session/session_setup_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/user_registration/user_registration_screen.dart';
import 'dart:async';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_battery_indicator.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_client_avatar.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_pop_menu_item_child.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_text_field.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GetxControllerServices servicesManager =
      Get.put(GetxControllerServices());

  int sortColumnIndex = 0;
  bool isAscending = true;

  late TextEditingController _textEditingController;
  List<Client> searchedClients = [];

  // Async load data on init:
  final clientOperations = ClientOperations();
  final userOperations = UserOperations();

  late Future initUserAccount;
  late Future initRegisteredClients;
  late Future<void> initRegisteredSensors;

  late User _loggedInUser;
  List<Client> _allRegisteredClients = [];
  List<RegisteredSensor> _allRegisteredSensors = [];

  bool _isLoading = true;
  bool _isLoadingSensors = true;

  final SearchController _searchController = SearchController();
  late StreamSubscription _subscription;
  final List<SensorInfo> _foundSensorsWithCallback = [];

  @override
  void initState() {
    initRegisteredClients = _getRegisteredClientsDBAsync();
    initRegisteredSensors = _initRegisteredSensorsDBAsync();
    initController();

    _textEditingController = TextEditingController();
    _textEditingController.addListener(() {
      filterContacts();
    });
    servicesManager.requestBluetoothAndGPS();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
  }

  filterContacts() {
    List<Client>? clients = [];
    if (_textEditingController.text.isNotEmpty) {
      clients.addAll(_allRegisteredClients.toList());
      clients.retainWhere((Client c) {
        String searchTerm = _textEditingController.text.toLowerCase();

        String fullName = c.surname.toLowerCase() +
            c.name.toLowerCase() +
            c.patronymic.toLowerCase();

        return fullName.contains(searchTerm);
      });
      searchedClients.clear();
      searchedClients.addAll(clients);

      setState(() {});
    }
  }

  void onSort(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      _allRegisteredClients.sort((value1, value2) =>
          compareString(ascending, value1.surname, value2.surname));
    } else if (columnIndex == 1) {
      _allRegisteredClients.sort((value1, value2) =>
          compareString(ascending, value1.birthday, value2.birthday));
    } else if (columnIndex == 2) {
      _allRegisteredClients.sort((value1, value2) => compareString(
          ascending, '${value1.isFavorite}', '${value2.isFavorite}'));
    } else if (columnIndex == 3) {
      _allRegisteredClients.sort((value1, value2) => compareString(
          ascending, value1.lastSession ?? '', value2.lastSession ?? ''));
    } else if (columnIndex == 4) {
      _allRegisteredClients.sort((value1, value2) => compareString(
          ascending, value1.registrationDate, value2.registrationDate));
    }
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  int compareString(bool ascending, String value1, String value2) {
    return ascending ? value1.compareTo(value2) : value2.compareTo(value1);
  }

  List<DataRow> getRowsAllClients(List<Client> clients) {
    return clients
        .map((Client c) => DataRow(
                onSelectChanged: (value) {
                  Get.to(
                    () => ClientHistoryScreen(
                      client: c,
                    ),
                  );
                },
                cells: [
                  DataCell(
                    Row(
                      children: [
                        ScaleTap(
                          onPressed: () => showClientSettings(client: c),
                          scaleMinValue: 0.9,
                          opacityMinValue: 0.4,
                          scaleCurve: Curves.decelerate,
                          opacityCurve: Curves.fastOutSlowIn,
                          child: Container(
                            height: 48,
                            width: 48,
                            color: Colors.transparent,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/ui/more-vert.svg',
                                width: 24,
                                color: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.colorScheme.tertiary
                                    : AppTheme.appTheme.colorScheme.tertiary,
                              ),
                            ),
                          ),
                        ),
                        ContactCircleAvatar(
                          radius: 25,
                          padding: const EdgeInsets.all(8),
                          isFavorite: c.isFavorite != 1 ? false : true,
                        ),
                        Flexible(
                          flex: 1,
                          child: RichText(
                            text: TextSpan(
                              style: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.textTheme.bodyText2
                                  : AppTheme.appTheme.textTheme.bodyText2,
                              children: <TextSpan>[
                                TextSpan(
                                    text: c.surname,
                                    style: Get.isDarkMode
                                        ? AppTheme
                                            .appDarkTheme.textTheme.bodyText1
                                        : AppTheme
                                            .appTheme.textTheme.bodyText1),
                                TextSpan(
                                  text: ' ${c.name} ${c.patronymic}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                        calculateAgeFromDateTime(DateTime.parse(c.birthday))
                            .toString(),
                        style: Get.isDarkMode
                            ? AppTheme.appDarkTheme.textTheme.bodyText2
                            : AppTheme.appTheme.textTheme.bodyText2),
                  ),
                  DataCell(
                    ZoomTapAnimation(
                      onTap: () async {
                        c.isFavorite == 0 ? c.isFavorite = 1 : c.isFavorite = 0;
                        await clientOperations.updateClient(c);
                        setState(() {});
                      },
                      end: 0.9,
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.transparent,
                        child: Center(
                          child: SvgPicture.asset('assets/icons/ui/star.svg',
                              color: c.isFavorite == 1
                                  ? Color(0xffffc933)
                                  : Color(0xffffc933).withOpacity(0.2),
                              semanticsLabel: 'Client marked as favorite'),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(iso8601StringToDate(c.registrationDate),
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.bodyText2
                              : AppTheme.appTheme.textTheme.bodyText2),
                      Text(timeago.format(DateTime.parse(c.registrationDate)),
                          style: AppTheme.appDarkTheme.textTheme.caption),
                    ],
                  )),
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          c.lastSession != null
                              ? iso8601StringToDate(c.lastSession!)
                              : "No sessions",
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.bodyText2
                              : AppTheme.appTheme.textTheme.bodyText2),
                      if (c.lastSession != null)
                        Text(timeago.format(DateTime.parse(c.lastSession!)),
                            style: AppTheme.appDarkTheme.textTheme.caption),
                    ],
                  )),
                ]))
        .toList();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
    _searchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading == true) {
      return Scaffold(
          body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Center(
              child: AppHeaderInfo(
            title: 'Welcome back!',
            labelPrimary: 'Loading ...',
          )),
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
            Container(
              padding: EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      width: 1,
                      color: Get.isDarkMode
                          ? AppTheme.appDarkTheme.colorScheme.outline
                          : AppTheme.appTheme.colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          width: 250,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Get.isDarkMode
                                ? AppTheme.appDarkTheme.colorScheme.surface
                                : AppTheme.appTheme.colorScheme.surface,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_allRegisteredSensors.isEmpty)
                                AppIconButton(
                                  onPressed: () => Get.to(() => SearchScreen()),
                                  text: 'Add Sensors',
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  svgIconPath: 'sensor',
                                ),
                              if (_allRegisteredSensors.isNotEmpty &&
                                  _isLoadingSensors == true)
                                CircularProgressIndicator(),
                              if (_allRegisteredSensors.isNotEmpty &&
                                  _isLoadingSensors == false)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    for (var registeredSensor
                                        in _allRegisteredSensors)
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Get.isDarkMode
                                                ? lighterColorFrom(
                                                    color: AppTheme.appDarkTheme
                                                        .colorScheme.surface,
                                                    amount: 0.05)
                                                : lighterColorFrom(
                                                    color: AppTheme.appTheme
                                                        .colorScheme.surface,
                                                    amount: 0.05),
                                            child: SvgPicture.asset(
                                                'assets/icons/callibri_device-${registeredSensor.color}.svg',
                                                width: 16,
                                                semanticsLabel:
                                                    'Callibri icon'),
                                          ),
                                          const SizedBox(height: 6),
                                          if (registeredSensor.battery != null)
                                            AppBatteryIndicator(
                                                appBatteryIndicatorLabelPosition:
                                                    AppBatteryIndicatorLabelPosition
                                                        .inside,
                                                batteryLevel:
                                                    registeredSensor.battery!)
                                        ],
                                      ),
                                  ],
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  ScaleTap(
                    onPressed: showAccountSettings,
                    scaleMinValue: 0.9,
                    opacityMinValue: 0.4,
                    scaleCurve: Curves.decelerate,
                    opacityCurve: Curves.fastOutSlowIn,
                    child: SvgPicture.asset('assets/icons/ui/settings.svg',
                        color: Get.isDarkMode
                            ? AppTheme.appDarkTheme.colorScheme.tertiary
                            : Colors.black,
                        width: 32),
                  ),
                  SizedBox(width: 64),
                  Flexible(
                    flex: 1,
                    child: AppTextFieldSearch(
                      textEditingController: _textEditingController,
                      hintText:
                          'Search from ${_allRegisteredClients.length} clients...',
                      onCancelButtonPressed: () {
                        if (_textEditingController.text != '') {
                          searchedClients.clear();
                          _textEditingController.text = '';
                        } else {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  ScaleTap(
                    onPressed: () => Get.to(() => AddClientScreen()),
                    scaleMinValue: 0.9,
                    opacityMinValue: 0.4,
                    scaleCurve: Curves.decelerate,
                    opacityCurve: Curves.fastOutSlowIn,
                    child: SvgPicture.asset(
                      'assets/icons/ui/user-plus.svg',
                      width: 32,
                      color: Get.isDarkMode
                          ? AppTheme.appDarkTheme.colorScheme.tertiary
                          : AppTheme.appTheme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (_allRegisteredClients.isEmpty)
              Expanded(
                  child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppHeaderInfo(
                      title: 'No clients',
                      labelPrimary: "You haven't registered any client yet",
                    ),
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: SvgPicture.asset(
                        'assets/illustrations/empty.svg',
                        height: 220,
                      ),
                    ),
                    SizedBox(height: 24),
                    AppIconButton(
                      onPressed: () => Get.to(() => AddClientScreen()),
                      svgIconPath: 'user-plus',
                      text: 'Add client',
                    ),
                  ],
                ),
              )),
            if (_allRegisteredClients.isNotEmpty)
              Expanded(
                child: SizedBox(
                    child: ListView(
                  scrollDirection: Axis.vertical,
                  children: [
                    DataTable(
                      showCheckboxColumn: false,
                      dataRowHeight: 72,
                      sortColumnIndex: sortColumnIndex,
                      sortAscending: isAscending,
                      columns: [
                        DataColumn(
                            tooltip: "Client's full name",
                            label: Text('         Full name',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                    : AppTheme.appTheme.textTheme.headline5),
                            onSort: onSort),
                        DataColumn(
                            tooltip: "Client's age",
                            label: Text('Age',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                    : AppTheme.appTheme.textTheme.headline5),
                            onSort: onSort),
                        DataColumn(
                            tooltip: "Favorite clients",
                            label: SvgPicture.asset(
                              'assets/icons/ui/star.svg',
                              semanticsLabel: 'Favorite Client',
                              color: Get.isDarkMode
                                  ? AppTheme.appDarkTheme.colorScheme.tertiary
                                  : Colors.black,
                            ),
                            onSort: onSort),
                        DataColumn(
                            tooltip: "Registered date",
                            label: Text('Registered',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                    : AppTheme.appTheme.textTheme.headline5),
                            onSort: onSort),
                        DataColumn(
                            tooltip: "Client's last session",
                            label: Text('Last session',
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline5
                                    : AppTheme.appTheme.textTheme.headline5),
                            onSort: onSort),
                      ],
                      rows: _textEditingController.text.isNotEmpty
                          ? getRowsAllClients(searchedClients)
                          : getRowsAllClients(_allRegisteredClients),
                    ),
                  ],
                )),
              ),
          ],
        ),
      ),
    );
  }

  void initController() async {
    await _searchController.init();
    _subscription = _searchController.foundSensorsStream.listen((sensors) {
      setState(() {
        _foundSensorsWithCallback.clear();
        _foundSensorsWithCallback.addAll(sensors);
      });
    });
  }

  Future<void> _getRegisteredClientsDBAsync() async {
    var user = await userOperations.getLoggedInUser();
    int? userId;
    if (user != null) {
      _loggedInUser = user;
      userId = user.id;
      var receivedData = await clientOperations.getAllClientsByUserId(userId);
      _allRegisteredClients = List.from(receivedData.toList());
      _allRegisteredClients.sort((a, b) => a.surname.compareTo(b.surname));
      setState(() {
        _isLoading = false;
      });
    } else {
      Get.off(() => UserRegistrationScreen());
    }
  }

  // Future<List<RegisteredSensor?>> getRegisteredSensors() async {
  //   var user = await userOperations.getLoggedInUser();
  //   int? userId;
  //   List<RegisteredSensor> registeredSensor = [];
  //   if (user != null) {
  //     registeredSensor =
  //         await RegisteredSensorOperations().getRegisteredSensorsByUser(user);
  //   }
  //   _allRegisteredSensors = registeredSensor;
  //   _isLoadingSensors = false;
  //   return registeredSensor;
  // }

  Future<void> _initRegisteredSensorsDBAsync() async {
    if (_foundSensorsWithCallback.isNotEmpty) {
      List<SensorInfo> allRegisteredAndDiscoveredSensors = [];

      // Prepare a list of the registered and discovered sensors, to connect to them later.
      for (var registeredSensor in _allRegisteredSensors) {
        SensorInfo? registeredAndDiscoveredSensor =
            _foundSensorsWithCallback.firstWhereOrNull(
                (element) => element.address == registeredSensor.address);
        if (registeredAndDiscoveredSensor != null) {
          allRegisteredAndDiscoveredSensors.add(registeredAndDiscoveredSensor);
        }
      }

      /// Connect to the registered and discovered sensors just to get the battery level of the sensors.
      List<Sensor> allConnectedSensors = [];
      for (var info in allRegisteredAndDiscoveredSensors) {
        log('CONNECTING...');
        var connectedSensor = await Sensor.create(info);
        var connectedSensorBattery = await connectedSensor.battery.value;
        String connectedSensorAddress = await connectedSensor.address.value;

        var currentRegisteredSensor = _allRegisteredSensors.firstWhereOrNull(
            (registeredSensor) =>
                registeredSensor.address == connectedSensorAddress);
        currentRegisteredSensor?.battery ??= (connectedSensorBattery);

        if (currentRegisteredSensor != null) {
          RegisteredSensorOperations().updateRegisteredSensorBatteryByAddress(
              currentRegisteredSensor.address, currentRegisteredSensor);
        }

        allConnectedSensors.add(connectedSensor);
      }

      /// Disconnect from all `allConnectedSensors`
      for (var connectedSensor in allConnectedSensors) {
        log('DISCONNECTING...');
        connectedSensor.disconnect();
        // connectedSensor.dispose();
      }
      _foundSensorsWithCallback.clear();
    }
    var user = await userOperations.getLoggedInUser();
    int? userId;
    List<RegisteredSensor> registeredSensor = [];
    if (user != null) {
      registeredSensor =
          await RegisteredSensorOperations().getRegisteredSensorsByUser(user);
    }
    _allRegisteredSensors = registeredSensor;
    _isLoadingSensors = false;
    setState(() {});
  }

  showAccountSettings() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                    color: Color(0xff242424),
                    child: Column(
                      children: <Widget>[
                        ListView(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: <Widget>[
                            AppBottomSheetHeader(
                              text: 'Settings',
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    Get.isDarkMode
                                        ? 'assets/icons/ui/moon.svg'
                                        : 'assets/icons/ui/sun.svg',
                                    width: 24,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 32,
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      "App Theme:",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 32,
                                    children: [
                                      ZoomTapAnimation(
                                        onTap: () async {
                                          Get.changeTheme(
                                              AppTheme.appDarkTheme);
                                          await Future.delayed(
                                              Duration(milliseconds: 700));
                                          setState(() {});
                                        },
                                        child: Text(
                                          "Dark",
                                          style: TextStyle(
                                            color: Colors.white,
                                            decorationThickness: 2,
                                            decoration: Get.isDarkMode
                                                ? TextDecoration.underline
                                                : null,
                                            decorationColor: Color(0xffe40031),
                                          ),
                                        ),
                                      ),
                                      ZoomTapAnimation(
                                        onTap: () async {
                                          Get.changeTheme(AppTheme.appTheme);
                                          await Future.delayed(
                                              Duration(milliseconds: 700));
                                          setState(() {});
                                        },
                                        child: Text(
                                          "Light",
                                          style: TextStyle(
                                            color: Colors.white,
                                            decorationThickness: 2,
                                            decoration: Get.isDarkMode == false
                                                ? TextDecoration.underline
                                                : null,
                                            decorationColor: Color(0xffe40031),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ui/planet.svg',
                                    width: 24,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 32,
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      "App Language:",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 32,
                                    children: [
                                      Text(
                                        "Russian",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        "English",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        "French",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ui/globe.svg',
                                    width: 24,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 32,
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      "Muscles Language:",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 32,
                                    children: [
                                      Text(
                                        "Russian",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        "Latin",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            AppBottomSheetButton(
                              text: "Edit account",
                              svgFileName: 'edit',
                              onPressed: () => null,
                            ),
                            if (_allRegisteredSensors.isEmpty)
                              AppBottomSheetButton(
                                text:
                                    'Register your Sensors (${_allRegisteredSensors.length} of 4 sensors added)',
                                svgFileName: 'sensor',
                                onPressed: () => Get.to(() => SearchScreen()),
                              ),
                            if (_allRegisteredSensors.isNotEmpty)
                              AppBottomSheetButton(
                                text:
                                    'Repeat Registration of Sensors (${_allRegisteredSensors.length} of 4 sensors added)',
                                svgFileName: 'sensor',
                                onPressed: () => Get.to(() => SearchScreen()),
                              ),
                            if (_allRegisteredSensors.isNotEmpty)
                              AppBottomSheetButton(
                                text:
                                    'Check sensors battery (First you need to turn on your sensors!)',
                                svgFileName: 'battery-2',
                                onPressed: () async {
                                  setState(() {
                                    _isLoadingSensors = true;
                                  });

                                  _searchController.startScanner();
                                  await Future.delayed(
                                      const Duration(seconds: 4));
                                  _searchController.stopScanner();

                                  _initRegisteredSensorsDBAsync();
                                },
                              ),
                            AppBottomSheetButton(
                              text: 'Log out',
                              svgFileName: 'log-out',
                              onPressed: () async {
                                _loggedInUser.isLoggedIn = 0;
                                await userOperations.updateUser(_loggedInUser);
                                Get.offAll(() => UserRegistrationScreen());
                              },
                            ),
                          ],
                        )
                      ],
                    )),
              ],
            ),
          );
        });
  }

  showClientSettings({required Client client}) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                  color: Color(0xff242424),
                  child: Column(
                    children: <Widget>[
                      ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          AppBottomSheetHeader(
                              text:
                                  'Client: ${client.surname} ${client.name} ${client.patronymic} '),
                          AppBottomSheetButton(
                              text: 'Open journal',
                              svgFileName: 'notebook',
                              onPressed: () => Get.to(
                                  () => ClientHistoryScreen(client: client))),
                          AppBottomSheetButton(
                              text: 'Start new session',
                              svgFileName: 'activity',
                              onPressed: () => Get.to(
                                  () => SessionSetupScreen(client: client))),
                          AppBottomSheetButton(
                            text: 'Edit client',
                            svgFileName: 'edit',
                            onPressed: () {},
                          ),
                          StatefulBuilder(
                              builder: (BuildContext context, setStateBuilder) {
                            bool isFavorite = client.isFavorite == 1;
                            return AppBottomSheetButton(
                              text: isFavorite == true
                                  ? 'Remove from favorites'
                                  : 'Mark as favorite',
                              svgFileName: isFavorite == false
                                  ? 'star-slash'
                                  : 'star-filled',
                              onPressed: () async {
                                isFavorite = !isFavorite;
                                client.isFavorite == 0
                                    ? client.isFavorite = 1
                                    : client.isFavorite = 0;
                                await clientOperations.updateClient(client);
                                setState(() {});
                                setStateBuilder(() {});
                              },
                            );
                          }),
                          AppBottomSheetButton(
                            text: 'Delete client',
                            svgFileName: 'user-minus',
                            onPressed: () {
                              showAlertDialog(context);
                              // await clientOperations.deleteClient(client);
                              // await _getRegisteredClientsDBAsync();
                              // setState(() {});
                              // Navigator.pop(context);
                            },
                          ),
                        ],
                      )
                    ],
                  )),
            ],
          );
        });
  }

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = AppIconButton(
      buttonType: ButtonType.outlinedButton,
      backgroundColor: Colors.transparent,
      textColor: Theme.of(context).colorScheme.secondary,
      text: 'Cancel',
      onPressed: () {},
    );
    Widget continueButton = AppIconButton(
      svgIconPath: 'trash',
      backgroundColor: Colors.red,
      text: 'Delete',
      onPressed: () {},
    );

    // set up the AlertDialog
    Dialog alert = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceVariant,
          // border: Border.all(
          //   color: Theme.of(context).colorScheme.outline,
          //   width: 1,
          // ),
        ),
        height: 220,
        width: 450,
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 24, bottom: 20, right: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CircleAvatar(
                        backgroundColor: AppTheme.appDarkTheme.colorScheme.error
                            .withOpacity(0.3),
                        radius: 22,
                        child: SvgPicture.asset('assets/icons/ui/trash.svg',
                            width: 24,
                            color: AppTheme.appDarkTheme.colorScheme.error),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete client',
                            style: Get.isDarkMode
                                ? AppTheme.appDarkTheme.textTheme.headline4
                                : AppTheme.appTheme.textTheme.headline4),
                        SizedBox(
                          width: 450 - (12 * 1) - (16 * 2) - 24 - 22,
                          child: Text(
                            "Are you sure you want to delete this client?\nAll client's data will be permanently removed. This action cannot be undone.",
                            style: Get.isDarkMode
                                ? AppTheme.appDarkTheme.textTheme.bodyText1
                                : AppTheme.appTheme.textTheme.bodyText1,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: SizedBox.expand(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      cancelButton,
                      continueButton,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // title: Text("AlertDialog"),
      // content: Text(
      //     "Would you like to continue learning how to use Flutter alerts?"),
      // actions: [
      //   cancelButton,
      //   continueButton,
      // ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
