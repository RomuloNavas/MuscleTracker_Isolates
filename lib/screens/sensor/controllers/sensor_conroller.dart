import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';

class SensorController {
  late final Sensor sensor;

  Stream<int> get batteryStream => sensor.batteryStream.stream;
  Stream<SensorState> get stateStream => sensor.stateStream.stream;
  Stream<List<CallibriSignalData>> get signalStream => sensor.signalStream.stream;
  Stream<List<CallibriEnvelopeData>> get envelopeStream => sensor.envelopeStream.stream;

  late final String name;
  late final String address;
  late final String serialNumber;
  late final SensorVersion version;
  late final CallibriColorType color;

  late SensorFirmwareMode firmwareMode;

  late final int initialBatteryValue;
  late final SensorState initialState;

  SensorExternalSwitchInput? switchInput;
  SensorSamplingFrequency? frequency;
  SensorDataOffset? offset;
  SensorADCInput? adcInput;
  SensorGain? gain;

  final List<SensorFilter> filters = [];

  Future<void> init(SensorInfo info) async {
    sensor = await Sensor.create(info);

    sensor.stateStream.init();
    sensor.signalStream.init();
    sensor.batteryStream.init();
    sensor.envelopeStream.init();

    name = await sensor.name.value;
    color = await sensor.color.value;
    address = await sensor.address.value;
    version = await sensor.version.value;
    serialNumber = await sensor.serialNumber.value;

    firmwareMode = await sensor.firmwareMode.value;

    initialState = await sensor.state.value;
    initialBatteryValue = await sensor.battery.value;
  }

  void startSignal() {
    sensor.executeCommand(SensorCommand.startSignal);
  }

  void stopSignal() {
    sensor.executeCommand(SensorCommand.stopSignal);
  }

  void startEnvelope() {
    sensor.executeCommand(SensorCommand.startEnvelope);
  }

  void stopEnvelope() {
    sensor.executeCommand(SensorCommand.stopEnvelope);
  }

  Future<void> setFirmwareMode(SensorFirmwareMode mode) async {
    firmwareMode = await sensor.firmwareMode.set(mode);
  }

  Future<void> setFrequency(SensorSamplingFrequency freq) async {
    frequency = await sensor.samplingFrequency.set(freq);
  }

  Future<void> setGain(SensorGain gain) async {
    this.gain = await sensor.gain.set(gain);
  }

  Future<void> setOffset(SensorDataOffset offset) async {
    this.offset = await sensor.dataOffset.set(offset);
  }

  Future<void> setADCInput(SensorADCInput adc) async {
    adcInput = await sensor.adcInput.set(adc);
  }

  Future<void> setExternalSwitchInput(SensorExternalSwitchInput input) async {
    switchInput = await sensor.externalSwitchInput.set(input);
  }

  Future<void> getFilters() async {
    filters.clear();
    filters.addAll(await sensor.hardwareFilters.value);
  }

  Future<void> addFilters() async {
    filters.addAll([SensorFilter.BSFBwhLvl2CutoffFreq45_55Hz, SensorFilter.BSFBwhLvl2CutoffFreq55_65Hz]);
    var newfilters = await sensor.hardwareFilters.set(filters);

    filters.clear();
    filters.addAll(newfilters);

    print(filters);
  }

  Future<void> removeFilter() async {
    if (filters.isEmpty) return;

    filters.removeLast();
    final newList = await sensor.hardwareFilters.set(filters);
    filters.clear();
    filters.addAll(newList);

    print(filters);
  }

  void connect() {
    sensor.connect();
  }

  void disconnect() {
    sensor.disconnect();
  }

  void dispose() {
    sensor.dispose();
  }
}
