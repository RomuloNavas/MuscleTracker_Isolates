import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/database/registered_sensor__operations.dart';
import 'package:neuro_sdk_isolate_example/screens/search/controllers/search_controller.dart';
import 'dart:async';

import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/utils/global_utils.dart';
import 'package:neuro_sdk_isolate_example/utils/utils.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';

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
    log('sorted');
    if (columnIndex == 0) {
      allRegisteredClients.sort((value1, value2) =>
          compareString(ascending, value1.surname, value2.surname));
    } else if (columnIndex == 1) {
      allRegisteredClients.sort((value1, value2) =>
          compareString(ascending, value1.birthday, value2.birthday));
    } else if (columnIndex == 2) {
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
                  // Get.to(() => ClientHistoryScreen(
                  //       client: c,
                  //     ));
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
                  DataCell(Text(c.registrationDate,
                      style: Get.isDarkMode
                          ? AppTheme.appDarkTheme.textTheme.bodyText2
                          : AppTheme.appTheme.textTheme.bodyText2))
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
                                child: TextField(
                                  controller: _textEditingController,
                                  style: TextStyle(
                                      color: Get.isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                  cursorColor: Colors.grey,
                                  decoration: InputDecoration(
                                    fillColor: Get.isDarkMode
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.05),
                                    filled: true,
                                    contentPadding: const EdgeInsets.all(0),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none),
                                    hintText: 'Search client',
                                    hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow,
                                        fontSize: 18),
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(15),
                                      width: 18,
                                      child: Icon(
                                        Icons.search,
                                        size: 26,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow,
                                      ),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        if (_textEditingController.text != '') {
                                          searchedClients.clear();
                                          _textEditingController.text = '';
                                        } else {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        }
                                        setState(() {});
                                      },
                                      child: Icon(
                                        Icons.cancel,
                                        size: 26,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              AppIconButton(
                                size: ButtonSize.big,
                                iconData: Icons.person,
                                iconColor:
                                    Theme.of(context).colorScheme.primary,
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
                                  label: Text('Registered',
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
        constraints: BoxConstraints(minWidth: 220),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20.0),
          ),
        ),
        elevation: 0.2,
        color: Get.isDarkMode
            ? AppTheme.appDarkTheme.colorScheme.surface
            : AppTheme.appTheme.colorScheme.surface,
        position: PopupMenuPosition.under,
        offset: Offset(0, 12),
        // position: PopupMenuPosition.over,
        // offset: Offset(48, -10),
        splashRadius: 26,
        icon: Icon(
          Icons.more_vert,
          color: Get.isDarkMode ? Color(0xffdcdcdc) : Colors.black,
        ),
        itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Get.isDarkMode
                          ? AppTheme.appDarkTheme.colorScheme.secondary
                          : AppTheme.appTheme.colorScheme.secondary,
                    ),
                    SizedBox(width: 10),
                    Text('Edit client',
                        style: Get.isDarkMode
                            ? AppTheme.appDarkTheme.textTheme.bodyText1
                            : AppTheme.appTheme.textTheme.bodyText1),
                  ],
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
                child: Row(
                  children: [
                    Icon(Icons.star,
                        color: Get.isDarkMode
                            ? AppTheme.appDarkTheme.colorScheme.secondary
                            : AppTheme.appTheme.colorScheme.secondary),
                    SizedBox(width: 10),
                    Text(
                        client.isFavorite == 0
                            ? 'Add to favorites'
                            : 'Remove from favorites',
                        style: Get.isDarkMode
                            ? AppTheme.appDarkTheme.textTheme.bodyText1
                            : AppTheme.appTheme.textTheme.bodyText1),
                  ],
                ),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.sports_gymnastics_outlined,
                        color: Get.isDarkMode
                            ? AppTheme.appDarkTheme.colorScheme.secondary
                            : AppTheme.appTheme.colorScheme.secondary),
                    const SizedBox(width: 10),
                    Text('Start new session',
                        style: Get.isDarkMode
                            ? AppTheme.appDarkTheme.textTheme.bodyText1
                            : AppTheme.appTheme.textTheme.bodyText1),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () async {
                  await ClientOperations().deleteClient(client);
                  notifyParentClientDeleted();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outlined,
                      color: Color(0xffd85a53),
                    ),
                    SizedBox(width: 10),
                    Text("Delete client",
                        style: Get.isDarkMode
                            ? AppTheme.appDarkTheme.textTheme.bodyText1
                            : AppTheme.appTheme.textTheme.bodyText1),
                  ],
                ),
              ),
            ]);
  }
}

class ImportContactsCard extends StatelessWidget {
  const ImportContactsCard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          height: 70,
          width: MediaQuery.of(context).size.width - 372,
          color: Get.isDarkMode
              ? AppTheme.appDarkTheme.cardColor
              : AppTheme.appTheme.cardColor,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xff26c6f4),
                        Color(0xff6f78fa),
                        Color(0xffa73de4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4)),
                child: const Icon(
                  Icons.contacts,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Import people from your phone's contacts",
                    style: Get.isDarkMode
                        ? AppTheme.appDarkTheme.textTheme.bodyText2
                        : AppTheme.appTheme.textTheme.bodyText2,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: null,
                    child: Text(
                      'Import contacts',
                      style: Get.isDarkMode
                          ? AppTheme.appDarkTheme.textTheme.bodyText2?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.appDarkTheme.colorScheme.primary)
                          : AppTheme.appTheme.textTheme.bodyText2?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.appTheme.colorScheme.primary),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
          child: GestureDetector(
            onTap: null,
            child: const Icon(Icons.close),
          ),
        )
      ],
    );
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

  List<RegisteredSensor> allRegisteredSensors = [];
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
        log(_foundSensorsWithCallback.length.toString());
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

  RegisteredSensor? _lastTappedSensor;

  Widget buildSensorInfoCard({required RegisteredSensor tappedSensor}) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12),
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppTheme.appDarkTheme.colorScheme.surface
            : AppTheme.appTheme.colorScheme.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Get.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            radius: 22,
            child: SvgPicture.asset(
                'assets/icons/callibri_device-${tappedSensor.color.split('.').last}.svg',
                width: 16,
                semanticsLabel: 'Battery'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: sidePanelWidth - (32 * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InformationTile(
                    title: 'Serial Number',
                    description: tappedSensor.serialNumber.toUpperCase()),
                InformationTile(
                    title: 'Address',
                    description: tappedSensor.address.toUpperCase()),
                InformationTile(
                    title: 'Color',
                    description:
                        tappedSensor.color.split('.').last.toCapitalized()),
                InformationTile(
                    title: 'Gain',
                    description:
                        tappedSensor.gain.split('.').last.toCapitalized()),
                InformationTile(
                    title: 'Data offset',
                    description: tappedSensor.dataOffset
                        .split('.')
                        .last
                        .toCapitalized()),
                InformationTile(
                    title: 'ADC Input',
                    description:
                        tappedSensor.adcInput.split('.').last.toCapitalized()),
                InformationTile(
                    title: 'Hardware filters',
                    description: tappedSensor.hardwareFilters),
                InformationTile(
                    title: 'Sampling frequency',
                    description: tappedSensor.samplingFrequency
                        .split('frequency')
                        .last
                        .toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
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
                                      text: '3',
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
                              onPressed: () {
                                log(_foundSensorsWithCallback.length
                                    .toString());
                                setState(() {
                                  _isLoading = true;
                                  _searchController.stopScanner();
                                  _searchController.startScanner();
                                });
                                // _initRegisteredSensorsDBAsync();
                              },
                              iconData: Icons.battery_5_bar_rounded,
                              iconColor: Color(0xff107c10),
                            )
                          ],
                        ),
                        Container(
                            margin: const EdgeInsets.only(top: 8),
                            height: 80,
                            width: sidePanelWidth - (12 * 2),
                            decoration: BoxDecoration(
                                color: Get.isDarkMode
                                    ? AppTheme.appDarkTheme.colorScheme.surface
                                    : AppTheme.appTheme.colorScheme.surface,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(16))),
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                child: Builder(
                                  builder: (context) {
                                    if (_isLoading == true) {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        for (var registeredSensor
                                            in allRegisteredSensors)
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(height: 2),
                                              InkWell(
                                                // onTap: () {
                                                //   RegisteredSensor
                                                //       currentTappedSensor =
                                                //       homeStatusManager
                                                //               .currentSavedDevices[
                                                //           index];
                                                //   if (_lastTappedSensor?.id ==
                                                //       currentTappedSensor.id) {
                                                //     _lastTappedSensor = null;
                                                //   } else {
                                                //     _lastTappedSensor =
                                                //         currentTappedSensor;
                                                //   }
                                                //   setState(() {});
                                                // },
                                                child: CircleAvatar(
                                                  backgroundColor: Get
                                                          .isDarkMode
                                                      ? Colors.white
                                                          .withOpacity(0.05)
                                                      : const Color(0xffdddddd),
                                                  radius: 24,
                                                  child: SvgPicture.asset(
                                                      'assets/icons/callibri_device-${registeredSensor.color}.svg',
                                                      width: 16,
                                                      semanticsLabel:
                                                          'Callibri icon'),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              // if (isCurrentSensorAvailable)
                                              //   Text(
                                              //     '${connectedSensorsInfo.first.batteryLevel}%',
                                              //     style: GoogleFonts.roboto(
                                              //       fontSize: 12,
                                              //       fontWeight: FontWeight.w400,
                                              //     ),
                                              //   )
                                            ],
                                          ),
                                      ],
                                    );
                                  },
                                ))),
                        if (_lastTappedSensor != null)
                          buildSensorInfoCard(tappedSensor: _lastTappedSensor!),
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
    var registeredSensors =
        await RegisteredSensorOperations().getAllRegisteredSensors();
    allRegisteredSensors = registeredSensors;
    _isLoading = false;
    setState(() {});
  }
}

class InformationTile extends StatelessWidget {
  const InformationTile({
    Key? key,
    required String title,
    required String description,
  })  : _title = title,
        _description = description,
        super(key: key);

  final String _title;
  final String _description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: RichText(
        text: TextSpan(
          style: Get.isDarkMode
              ? AppTheme.appDarkTheme.textTheme.overline
                  ?.copyWith(color: Color(0xffbababa))
              : AppTheme.appTheme.textTheme.overline,
          children: <TextSpan>[
            TextSpan(text: '$_title: '),
            TextSpan(
                text: _description,
                style: Get.isDarkMode
                    ? AppTheme.appDarkTheme.textTheme.overline?.copyWith(
                        color: const Color(0xffeaeaea),
                      )
                    : AppTheme.appTheme.textTheme.overline?.copyWith(
                        color: Colors.black,
                      )),
          ],
        ),
      ),
    );
  }
}

class ScrollViewContacts extends StatelessWidget {
  final List<Client> clients;
  const ScrollViewContacts({
    Key? key,
    required this.clients,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      //This widget allow to scroll its child.
      //To horizontally scroll its child, make sure that the parent has shrinkWrap:false
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: null,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 8),
              child: Row(
                children: [
                  for (Client client in clients)
                    InkWell(
                      child: ContactAvatar(
                        client: client,
                      ),
                      // onTap: () => Get.to(() => ClientHistoryScreen(
                      //       client: client,
                      //     )),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContactAvatar extends StatelessWidget {
  final Client client;
  const ContactAvatar({Key? key, required this.client}) : super(key: key);

  final double widgetWidth = 80;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ignore: prefer_const_constructors
          ContactCircleAvatar(
            radius: 27,
            padding: const EdgeInsets.only(left: 6, right: 6),
            isFavorite: client.isFavorite != 1 ? false : true,
          ),
          const SizedBox(height: 2),
          Container(
            width: widgetWidth,
            child: Text(
              client.surname,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.caption
                  : AppTheme.appTheme.textTheme.caption,
            ),
          ),
          Container(
            width: widgetWidth,
            child: Text(
              client.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.caption
                      ?.copyWith(color: Color(0xff878787))
                  : AppTheme.appTheme.textTheme.caption,
            ),
          )
        ],
      ),
    );
  }
}

class ContactCircleAvatar extends StatelessWidget {
  final double? _radius;
  final EdgeInsets? _padding;
  final EdgeInsets? _margin;
  final bool? _isFavorite;

  const ContactCircleAvatar({
    double? radius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    bool? isFavorite,
    Key? key,
  })  : _radius = radius,
        _padding = padding,
        _margin = margin,
        _isFavorite = isFavorite,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_isFavorite != true) {
      return Container(
        padding: _padding,
        margin: _margin,
        child: CircleAvatar(
          radius: _radius, //big 27, small 25
          backgroundColor: Get.isDarkMode
              ? Color.fromARGB(((10 + math.Random().nextInt(100 - 10))).toInt(),
                  150, 150, 150)
              : Color.fromARGB(
                  115,
                  80,
                  120,
                  180 + (math.Random().nextDouble() * 1.2).toInt(),
                ),
          child: Icon(Icons.person,
              color: Get.isDarkMode ? const Color(0xff878787) : Colors.black),
        ),
      );
    } else {
      return Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          Container(
            padding: _padding,
            margin: _margin,
            child: CircleAvatar(
              radius: _radius, //big 27, small 25
              backgroundColor: Get.isDarkMode
                  ? Color.fromARGB(
                      ((10 + math.Random().nextInt(100 - 10))).toInt(),
                      150,
                      150,
                      150)
                  : Color.fromARGB(
                      115,
                      80,
                      120,
                      180 + (math.Random().nextDouble() * 1.2).toInt(),
                    ),
              child: Icon(Icons.person,
                  color:
                      Get.isDarkMode ? const Color(0xff878787) : Colors.black),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? Color.fromARGB(155, 255, 234, 171)
                  : Color.fromARGB(255, 255, 234, 171),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: SvgPicture.asset('assets/icons/ui/star.svg',
                  width: 14, semanticsLabel: 'Star'),
            ),
          ),
        ],
      );
    }
  }
}
