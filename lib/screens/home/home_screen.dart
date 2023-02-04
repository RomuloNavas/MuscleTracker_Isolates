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
import 'package:neuro_sdk_isolate_example/screens/home/widgets/apppopupmenubutton.dart';
import 'package:neuro_sdk_isolate_example/screens/home/widgets/popupmenubutton_clients.dart';
import 'package:neuro_sdk_isolate_example/screens/home/widgets/tapper_registered_sensor_info.dart';
import 'package:neuro_sdk_isolate_example/screens/client_journal/client_history_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/search_controller.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/search_screen.dart';
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
  late User _loggedInUser;
  List<Client> allRegisteredClients = [];
  List<Client> favoriteClients = [];
  List<Client> lastAddedClients = [];
  late Future initRegisteredClients;
  late Future initFavoriteClients;
  late Future initLastAddedClients;
  late Future initUserAccount;

  @override
  void initState() {
    initUserAccount = _getLoggedInUserDBAsync();
    initRegisteredClients = _getRegisteredClientsDBAsync();
    initFavoriteClients = _getFavoriteClientsDBAsync();
    initLastAddedClients = _getLastAddedClientsDBAsync();

    initController();
    initRegisteredSensors = _initRegisteredSensorsDBAsync();

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
      clients.addAll(allRegisteredClients.toList());
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
      allRegisteredClients.sort((value1, value2) =>
          compareString(ascending, value1.surname, value2.surname));
    } else if (columnIndex == 1) {
      allRegisteredClients.sort((value1, value2) =>
          compareString(ascending, value1.birthday, value2.birthday));
    } else if (columnIndex == 2) {
      allRegisteredClients.sort((value1, value2) => compareString(
          ascending, '${value1.isFavorite}', '${value2.isFavorite}'));
    } else if (columnIndex == 3) {
      allRegisteredClients.sort((value1, value2) => compareString(
          ascending, value1.lastVisit ?? '', value2.lastVisit ?? ''));
    } else if (columnIndex == 4) {
      allRegisteredClients.sort((value1, value2) => compareString(
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
                        PopMenuButtonClients(
                          client: c,
                          // Get again the clients from DB to update the rendered information:
                          notifyParentClientDeleted: () async {
                            await _getRegisteredClientsDBAsync();
                            await _getFavoriteClientsDBAsync();
                            await _getLastAddedClientsDBAsync();
                          },
                          notifyParentClientAddedToFavorites: () async {
                            await _getFavoriteClientsDBAsync();
                          },
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
                      child: SvgPicture.asset('assets/icons/ui/star.svg',
                          color: c.isFavorite == 1
                              ? Color(0xffffc933)
                              : Color(0xffffc933).withOpacity(0.2),
                          semanticsLabel: 'Client marked as favorite'),
                    ),
                  ),
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.lastVisit ?? (""),
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.bodyText2
                              : AppTheme.appTheme.textTheme.bodyText2),
                      if (c.lastVisit != null)
                        Text(timeago.format(DateTime.parse(c.lastVisit!)),
                            style: AppTheme.appDarkTheme.textTheme.caption),
                    ],
                  )),
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.registrationDate,
                          style: Get.isDarkMode
                              ? AppTheme.appDarkTheme.textTheme.bodyText2
                              : AppTheme.appTheme.textTheme.bodyText2),
                      Text(timeago.format(DateTime.parse(c.registrationDate)),
                          style: AppTheme.appDarkTheme.textTheme.caption),
                    ],
                  ))
                ]))
        .toList();
  }

  bool _isLoading = true;

  final SearchController _searchController = SearchController();
  late StreamSubscription _subscription;
  final List<SensorInfo> _foundSensorsWithCallback = [];

  RegisteredSensor? _tappedRegisteredSensorInfo;
  List<RegisteredSensor> _allRegisteredSensors = [];
  late Future<void> initRegisteredSensors;

  void initController() async {
    await _searchController.init();
    _subscription = _searchController.foundSensorsStream.listen((sensors) {
      setState(() {
        _foundSensorsWithCallback.clear();
        _foundSensorsWithCallback.addAll(sensors);
      });
    });

    setState(() {
      _isLoading = false;
    });
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(right: 20, bottom: 12),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: [
                  0.1,
                  0.6,
                ],
                colors: [
                  Color(0xff1b1b1b),
                  Get.isDarkMode
                      ? AppTheme.appDarkTheme.scaffoldBackgroundColor
                      : AppTheme.appTheme.scaffoldBackgroundColor,
                ],
              )),
              child: Row(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          width: 240,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(16)),
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                stops: [
                                  0.1,
                                  0.6,
                                ],
                                colors: [
                                  Get.isDarkMode
                                      ? AppTheme
                                          .appDarkTheme.colorScheme.surface
                                      : AppTheme.appTheme.colorScheme.surface,
                                  Get.isDarkMode
                                      ? AppTheme.appDarkTheme.colorScheme
                                          .surfaceVariant
                                      : AppTheme
                                          .appTheme.colorScheme.surfaceVariant,
                                ],
                              )),
                          child: Column(
                            children: [
                              // if (_allRegisteredSensors.isEmpty)

                              if (_allRegisteredSensors.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    if (_isLoading == true) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    return ZoomTapAnimation(
                                      onTap: () async {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        _searchController.startScanner();
                                        await Future.delayed(
                                            Duration(seconds: 2));
                                        _searchController.stopScanner();
                                        _searchController.startScanner();
                                        await Future.delayed(
                                            Duration(seconds: 2));
                                        _searchController.stopScanner();

                                        _initRegisteredSensorsDBAsync();
                                      },
                                      child: Row(
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
                                                  backgroundColor:
                                                      Get.isDarkMode
                                                          ? AppTheme
                                                              .appDarkTheme
                                                              .colorScheme
                                                              .surface
                                                          : AppTheme
                                                              .appTheme
                                                              .colorScheme
                                                              .surface,
                                                  child: SvgPicture.asset(
                                                      'assets/icons/callibri_device-${registeredSensor.color}.svg',
                                                      width: 16,
                                                      semanticsLabel:
                                                          'Callibri icon'),
                                                ),
                                                const SizedBox(height: 6),
                                                if (registeredSensor.battery !=
                                                    null)
                                                  AppBatteryIndicator(
                                                      appBatteryIndicatorLabelPosition:
                                                          AppBatteryIndicatorLabelPosition
                                                              .inside,
                                                      batteryLevel:
                                                          registeredSensor
                                                              .battery!)
                                              ],
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
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
                          'Search from ${allRegisteredClients.length} clients...',
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
                    onPressed: showAccountSettings,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: SizedBox(
                    child: ListView(
                  scrollDirection: Axis.vertical,
                  children: [
                    DataTable(
                      showCheckboxColumn: false,
                      horizontalMargin: 4,
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
                          : getRowsAllClients(allRegisteredClients),
                    ),
                  ],
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  showAccountSettings() {
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
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 1,
                                  color: Color(0xff292929),
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 12),
                                Container(
                                  width: 48,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: Color(0xff727272),
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "Settings",
                                  style: AppTheme.appTheme.textTheme.headline5
                                      ?.copyWith(
                                    color: Colors.white,
                                  ),
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
                                        Get.changeTheme(AppTheme.appDarkTheme);
                                        await Future.delayed(
                                            Duration(milliseconds: 700));
                                        setState(() {});
                                      },
                                      child: Text(
                                        "Dark",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    ZoomTapAnimation(
                                      onTap: () async {
                                        Get.changeTheme(AppTheme.appTheme);
                                        await Future.delayed(
                                            Duration(milliseconds: 700));
                                        setState(() {});
                                      },
                                      child: const Text(
                                        "Light",
                                        style: TextStyle(color: Colors.white),
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
                          ListTile(
                            title: Text(
                              "Edit account",
                              style: TextStyle(color: Colors.white),
                            ),
                            leading: SvgPicture.asset(
                              'assets/icons/ui/edit.svg',
                              width: 24,
                              color: Colors.white,
                            ),
                            onTap: () {},
                          ),
                          ZoomTapAnimation(
                            end: 0.98,
                            onTap: () async {
                              _loggedInUser.isLoggedIn = 0;
                              await userOperations.updateUser(_loggedInUser);
                              Get.off(() => UserRegistrationScreen());
                            },
                            child: ListTile(
                              title: Text(
                                "Log out",
                                style: TextStyle(color: Colors.white),
                              ),
                              leading: SvgPicture.asset(
                                'assets/icons/ui/log-out.svg',
                                width: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  )),
            ],
          );
        });
  }

  Future<void> _getLoggedInUserDBAsync() async {
    var user = await userOperations.getLoggedInUser();
    if (user != null) {
      _loggedInUser = user;
    } else {
      Get.off(() => UserRegistrationScreen());
    }
  }

  Future<void> _getRegisteredClientsDBAsync() async {
    var receivedData = await clientOperations.getAllClients();
    allRegisteredClients = List.from(receivedData.toList());
    allRegisteredClients.sort((a, b) => a.surname.compareTo(b.surname));
    setState(() {});
  }

  Future<void> _getFavoriteClientsDBAsync() async {
    var receivedData = await clientOperations.getAllFavoriteClients();
    favoriteClients = List.from(receivedData.toList());
    favoriteClients.sort((a, b) => a.surname.compareTo(b.surname));
    setState(() {});
  }

  Future<void> _getLastAddedClientsDBAsync() async {
    var receivedData = await clientOperations.getLastAddedClients();
    lastAddedClients = List.from(receivedData.toList());
    setState(() {});
  }

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
    var registeredSensors =
        await RegisteredSensorOperations().getAllRegisteredSensors();
    _allRegisteredSensors = registeredSensors;

    _isLoading = false;
    setState(() {});
  }
}
