import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor_operations.dart';
import 'package:neuro_sdk_isolate_example/screens/home/widgets/tapper_registered_sensor_info.dart';
import 'package:neuro_sdk_isolate_example/screens/client_journal/client_history_screen.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/search_controller.dart';
import 'dart:async';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_battery_indicator.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_client_avatar.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_pop_menu_item_child.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_text_field.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  List<Client> allRegisteredClients = [];
  List<Client> favoriteClients = [];
  List<Client> lastAddedClients = [];
  late Future initRegisteredClients;
  late Future initFavoriteClients;
  late Future initLastAddedClients;

  @override
  void initState() {
    initRegisteredClients = _getRegisteredClientsDBAsync();
    initFavoriteClients = _getFavoriteClientsDBAsync();
    initLastAddedClients = _getLastAddedClientsDBAsync();

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
          ascending, value1.lastVisit ?? '', value2.lastVisit ?? ''));
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
                        AppPopMenuButton(
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
                            style: Get.isDarkMode
                                ? AppTheme.appDarkTheme.textTheme.caption
                                : AppTheme.appTheme.textTheme.caption),
                    ],
                  ))
                ]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        body: Row(
          children: [
            SidePanel(
              favoriteClients: favoriteClients,
              lastAddedClients: lastAddedClients,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                        left: 24, right: 24, bottom: 12, top: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline1
                                        ?.copyWith(color: Colors.white)
                                    : AppTheme.appTheme.textTheme.headline1,
                                children: <TextSpan>[
                                  const TextSpan(text: 'Your Clients '),
                                  TextSpan(
                                      text: '${allRegisteredClients.length}',
                                      style: AppTheme
                                          .appDarkTheme.textTheme.headline1
                                          ?.copyWith(
                                        shadows: [
                                          Shadow(
                                              color: Get.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              offset: Offset(0, -2))
                                        ],
                                        color: Colors.transparent,
                                        decorationThickness: 2,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xffe40031),
                                      )),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 12,
                              children: [
                                AppIconButton(
                                  onPressed: () => null,
                                  iconData: Icons.settings,
                                ),
                                AppIconButton(
                                  onPressed: () {
                                    Get.isDarkMode
                                        ? Get.changeTheme(AppTheme.appTheme)
                                        : Get.changeTheme(
                                            AppTheme.appDarkTheme);
                                  },
                                  iconData: Get.isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                ),
                                AppIconButton(
                                  onPressed: () => null,
                                  iconData: Icons.logout,
                                  iconColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // - Text Field
                        SizedBox(
                          child: Row(
                            children: [
                              Flexible(
                                flex: 1,
                                child: AppTextField(
                                  textEditingController: _textEditingController,
                                  hintText: 'Search client',
                                  onCancelButtonPressed: () {
                                    if (_textEditingController.text != '') {
                                      searchedClients.clear();
                                      _textEditingController.text = '';
                                    } else {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    }
                                    setState(() {});
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              AppIconButton(
                                iconData: Icons.person_add,
                                size: ButtonSize.big,
                                backgroundColor: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.colorScheme.primary
                                        .withAlpha(200)
                                    : AppTheme.appTheme.colorScheme.primary
                                        .withAlpha(200),
                                iconColor: Colors.white,
                                onPressed: () => null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 12, left: 12, right: 12),
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
                                          ? AppTheme
                                              .appDarkTheme.textTheme.headline5
                                          : AppTheme
                                              .appTheme.textTheme.headline5),
                                  onSort: onSort),
                              DataColumn(
                                  tooltip: "Client's age",
                                  label: Text('Age',
                                      style: Get.isDarkMode
                                          ? AppTheme
                                              .appDarkTheme.textTheme.headline5
                                          : AppTheme
                                              .appTheme.textTheme.headline5),
                                  onSort: onSort),
                              DataColumn(
                                  tooltip: 'Date when client was registered',
                                  label: Text('Last session',
                                      style: Get.isDarkMode
                                          ? AppTheme
                                              .appDarkTheme.textTheme.headline5
                                          : AppTheme
                                              .appTheme.textTheme.headline5),
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
          ],
        ),
      ),
    );
  }

  Future<void> _getRegisteredClientsDBAsync() async {
    var receivedData = await ClientOperations().getAllClients();
    allRegisteredClients = List.from(receivedData.toList());
    allRegisteredClients.sort((a, b) => a.surname.compareTo(b.surname));
    setState(() {});
  }

  Future<void> _getFavoriteClientsDBAsync() async {
    var receivedData = await ClientOperations().getAllFavoriteClients();
    favoriteClients = List.from(receivedData.toList());
    favoriteClients.sort((a, b) => a.surname.compareTo(b.surname));
    setState(() {});
  }

  Future<void> _getLastAddedClientsDBAsync() async {
    var receivedData = await ClientOperations().getLastAddedClients();
    lastAddedClients = List.from(receivedData.toList());
    setState(() {});
  }
}

class AppPopMenuButton extends StatelessWidget {
  final Function() notifyParentClientDeleted;
  final Function() notifyParentClientAddedToFavorites;
  final Client client;
  const AppPopMenuButton({
    Key? key,
    required this.client,
    required this.notifyParentClientDeleted,
    required this.notifyParentClientAddedToFavorites,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16.0),
          ),
        ),
        elevation: 0.2,
        color: Get.isDarkMode
            ? AppTheme.appDarkTheme.colorScheme.surface
            : AppTheme.appTheme.colorScheme.surface,
        position: PopupMenuPosition.under,
        offset: Offset(0, 12),
        splashRadius: 26,
        icon: Icon(
          Icons.more_vert,
          color: Get.isDarkMode ? Color(0xffdcdcdc) : Colors.black,
        ),
        itemBuilder: (context) => [
              const PopupMenuItem(
                child: AppPopMenuItemChild(
                  title: 'Edit client',
                  iconData: Icons.edit,
                ),
              ),
              PopupMenuItem(
                onTap: () async {
                  client.isFavorite == 0
                      ? client.isFavorite = 1
                      : client.isFavorite = 0;
                  await ClientOperations().updateClient(client);
                  notifyParentClientAddedToFavorites();
                },
                child: AppPopMenuItemChild(
                  title: client.isFavorite == 0
                      ? 'Add to favorites'
                      : 'Remove from favorites',
                  iconData:
                      client.isFavorite == 0 ? Icons.star_outline : Icons.star,
                ),
              ),
              const PopupMenuItem(
                child: AppPopMenuItemChild(
                  title: 'Start new session',
                  iconData: Icons.sports_gymnastics_outlined,
                ),
              ),
              PopupMenuItem(
                onTap: () async {
                  await ClientOperations().deleteClient(client);
                  notifyParentClientDeleted();
                },
                child: AppPopMenuItemChild(
                  title: 'Delete client',
                  iconData: Icons.delete_outlined,
                  iconColor: Get.isDarkMode
                      ? AppTheme.appDarkTheme.colorScheme.error
                      : AppTheme.appTheme.colorScheme.error,
                ),
              ),
            ]);
  }
}

class SidePanel extends StatefulWidget {
  final List<Client> favoriteClients;
  final List<Client> lastAddedClients;
  const SidePanel({
    Key? key,
    required this.favoriteClients,
    required this.lastAddedClients,
  }) : super(key: key);

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  final sidePanelWidth = 270.0;
  bool _isLoading = true;

  final SearchController _searchController = SearchController();
  late StreamSubscription _subscription;
  final List<SensorInfo> _foundSensorsWithCallback = [];

  RegisteredSensor? _tappedRegisteredSensorInfo;
  List<RegisteredSensor> _allRegisteredSensors = [];
  late Future<void> initRegisteredSensors;

  @override
  void initState() {
    super.initState();
    initController();
    initRegisteredSensors = _initRegisteredSensorsDBAsync();
  }

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
    return Container(
      height: MediaQuery.of(context).size.height,
      width: sidePanelWidth,
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppTheme.appDarkTheme.scaffoldBackgroundColor
            : AppTheme.appTheme.scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
              width: 1.0,
              color: Get.isDarkMode
                  ? AppTheme.appDarkTheme.dividerColor
                  : AppTheme.appTheme.dividerColor),
        ),
      ),
      child: ListView(
        children: [
          SizedBox(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      width: 1.0,
                      color: Get.isDarkMode
                          ? AppTheme.appDarkTheme.dividerColor
                          : AppTheme.appTheme.dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                        top: 20, left: 12, right: 12, bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.textTheme.headline3
                                        ?.copyWith(color: Colors.white)
                                    : AppTheme.appTheme.textTheme.headline3,
                                children: <TextSpan>[
                                  const TextSpan(text: 'Your Sensors: '),
                                  TextSpan(
                                      text: '${_allRegisteredSensors.length}',
                                      style: AppTheme
                                          .appDarkTheme.textTheme.headline3
                                          ?.copyWith(
                                        shadows: [
                                          Shadow(
                                              color: Get.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              offset: Offset(0, -2))
                                        ],
                                        color: Colors.transparent,
                                        decorationThickness: 2,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xffe40031),
                                      )),
                                ],
                              ),
                            ),
                            AppIconButton(
                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                _searchController.startScanner();
                                await Future.delayed(Duration(seconds: 2));
                                _searchController.stopScanner();
                                _searchController.startScanner();
                                await Future.delayed(Duration(seconds: 2));
                                _searchController.stopScanner();

                                _initRegisteredSensorsDBAsync();
                              },
                              iconData: Icons.refresh,
                              iconColor: Color(0xff107c10),
                            )
                          ],
                        ),
                        Container(
                            margin: const EdgeInsets.only(top: 8),
                            height: 100,
                            width: sidePanelWidth - (12 * 2),
                            decoration: BoxDecoration(
                                color: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.colorScheme.surface
                                    : AppTheme.appTheme.colorScheme.surface,
                                borderRadius:
                                    _tappedRegisteredSensorInfo == null
                                        ? const BorderRadius.all(
                                            Radius.circular(16))
                                        : const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16))),
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                child: Builder(
                                  builder: (context) {
                                    if (_isLoading == true) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        for (var registeredSensor
                                            in _allRegisteredSensors)
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(height: 2),
                                              InkWell(
                                                onTap: () => setState(() {
                                                  _tappedRegisteredSensorInfo =
                                                      (_tappedRegisteredSensorInfo ==
                                                              registeredSensor)
                                                          ? null
                                                          : registeredSensor;
                                                }),
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      _tappedRegisteredSensorInfo ==
                                                              registeredSensor
                                                          ? Colors.white
                                                          : Colors.transparent,
                                                  radius: 26,
                                                  child: CircleAvatar(
                                                    backgroundColor: Get
                                                            .isDarkMode
                                                        ? Colors.white
                                                            .withOpacity(0.05)
                                                        : Colors.black
                                                            .withOpacity(0.05),
                                                    radius: 24,
                                                    child: SvgPicture.asset(
                                                        'assets/icons/callibri_device-${registeredSensor.color}.svg',
                                                        width: 16,
                                                        semanticsLabel:
                                                            'Callibri icon'),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
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
                                    );
                                  },
                                ))),
                        if (_tappedRegisteredSensorInfo != null)
                          TapperRegisteredSensorInfo(
                              tappedRegisteredSensorInfo:
                                  _tappedRegisteredSensorInfo!),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
              top: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text('Favorites',
                      style: Get.isDarkMode
                          ? AppTheme.appDarkTheme.textTheme.headline4
                          : AppTheme.appTheme.textTheme.headline4),
                ),
                ScrollViewContacts(clients: widget.favoriteClients),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text('Last added',
                      style: Get.isDarkMode
                          ? AppTheme.appDarkTheme.textTheme.headline4
                          : AppTheme.appTheme.textTheme.headline4),
                ),
                ScrollViewContacts(clients: widget.lastAddedClients),
              ],
            ),
          ),
        ],
      ),
    );
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
