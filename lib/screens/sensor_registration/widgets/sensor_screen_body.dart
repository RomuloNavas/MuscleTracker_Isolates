import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/sensor_conroller.dart';

class SensorScreenBody extends StatefulWidget {
  final List<SensorInfo> sensorsInfo;
  const SensorScreenBody({super.key, required this.sensorsInfo});

  @override
  State<SensorScreenBody> createState() => _SensorScreenBodyState();
}

class _SensorScreenBodyState extends State<SensorScreenBody> {
  final SensorController _controller = SensorController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initController();
  }

  void initController() async {
    await _controller.init(widget.sensorsInfo.first);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            semanticsLabel: "Инициализация сканера..."),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Text(_controller.name),
                Text(_controller.address),
                Text(_controller.serialNumber),
                Text(_controller.color.name),
                Text(
                  '${_controller.version.fwMajor}:${_controller.version.fwMinor}:${_controller.version.fwPatch}:${_controller.version.hwMajor}:${_controller.version.hwMinor}:${_controller.version.hwPatch}:${_controller.version.extMajor}',
                ),
                Text(_controller.firmwareMode.name),

                // Sensor battery value
                StreamBuilder(
                  initialData: _controller.initialBatteryValue,
                  stream: _controller.batteryStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text('${snapshot.data} %');
                    }
                    return const Text('--- %');
                  },
                ),
                // Sensor state
                StreamBuilder(
                  initialData: _controller.initialState,
                  stream: _controller.stateStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!.name);
                    }
                    return const Text("---");
                  },
                ),
              ],
            ),
          ),
          // Connect/Disconnect
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: _controller.connect,
                  child: const Text("Подключить")),
              ElevatedButton(
                  onPressed: _controller.disconnect,
                  child: const Text("Отключить")),
            ],
          ),

          // Set frequency
          if (_controller.sensor
              .isSupportedParameter(SensorParameter.samplingFrequency))
            Column(
              children: [
                const Text("Sampling frequency:"),
                ToggleButtons<SensorSamplingFrequency>(
                  firstButtonText: SensorSamplingFrequency.frequencyHz500.name,
                  secondButtonText: SensorSamplingFrequency.frequencyHz250.name,
                  firstParam: SensorSamplingFrequency.frequencyHz500,
                  secondParam: SensorSamplingFrequency.frequencyHz250,
                  onButtonPressed: setFrequency,
                  currentParam: _controller.frequency,
                ),
              ],
            ),
          // Set gain
          if (_controller.sensor.isSupportedParameter(SensorParameter.gain))
            Column(
              children: [
                const Text("Gain:"),
                ToggleButtons<SensorGain>(
                  firstButtonText: SensorGain.gain8.name,
                  secondButtonText: SensorGain.gain12.name,
                  firstParam: SensorGain.gain8,
                  secondParam: SensorGain.gain12,
                  onButtonPressed: setGain,
                  currentParam: _controller.gain,
                ),
              ],
            ),
          // Set offset
          if (_controller.sensor.isSupportedParameter(SensorParameter.offset))
            Column(
              children: [
                const Text("Data offset:"),
                ToggleButtons<SensorDataOffset>(
                  firstButtonText: SensorDataOffset.dataOffset4.name,
                  secondButtonText: SensorDataOffset.dataOffset5.name,
                  firstParam: SensorDataOffset.dataOffset4,
                  secondParam: SensorDataOffset.dataOffset5,
                  onButtonPressed: setOffset,
                  currentParam: _controller.offset,
                ),
              ],
            ),
          // Set ADCInput
          if (_controller.sensor
              .isSupportedParameter(SensorParameter.adcInputState))
            Column(
              children: [
                const Text("ADC input:"),
                ToggleButtons<SensorADCInput>(
                  firstButtonText: SensorADCInput.electrodes.name,
                  secondButtonText: SensorADCInput.resistance.name,
                  firstParam: SensorADCInput.electrodes,
                  secondParam: SensorADCInput.resistance,
                  onButtonPressed: setADCInput,
                  currentParam: _controller.adcInput,
                ),
              ],
            ),
          // Set ExternalSwitchInput
          if (_controller.sensor
              .isSupportedParameter(SensorParameter.externalSwitchState))
            Column(
              children: [
                const Text("External switch input:"),
                ToggleButtons<SensorExternalSwitchInput>(
                  firstButtonText: SensorExternalSwitchInput.mioElectrodes.name,
                  secondButtonText:
                      SensorExternalSwitchInput.mioElectrodesRespUSB.name,
                  firstParam: SensorExternalSwitchInput.mioElectrodes,
                  secondParam: SensorExternalSwitchInput.mioElectrodesRespUSB,
                  onButtonPressed: setExternalSwitchInput,
                  currentParam: _controller.switchInput,
                ),
              ],
            ),

          // Set firmwareMode
          if (_controller.sensor
              .isSupportedParameter(SensorParameter.firmwareMode))
            Column(
              children: [
                const Text("Sampling frequency:"),
                ToggleButtons<SensorFirmwareMode>(
                  firstButtonText: SensorFirmwareMode.modeBootloader.name,
                  secondButtonText: SensorFirmwareMode.modeApplication.name,
                  firstParam: SensorFirmwareMode.modeBootloader,
                  secondParam: SensorFirmwareMode.modeApplication,
                  onButtonPressed: setFirmwareMode,
                  currentParam: _controller.firmwareMode,
                ),
              ],
            ),
          // Signal example
          if (_controller.sensor.isSupportedFeature(SensorFeature.signal))
            Column(
              children: [
                const Text("Сигнал:"),
                Center(
                  child: StreamBuilder(
                    stream: _controller.signalStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text('${snapshot.data!.last.samples.last}');
                      }
                      return const Text('...');
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: _controller.startSignal,
                        child: const Text("Старт")),
                    ElevatedButton(
                        onPressed: _controller.stopSignal,
                        child: const Text("Стоп")),
                  ],
                ),
              ],
            ),
          // Envelope example
          if (_controller.sensor.isSupportedFeature(SensorFeature.envelope))
            Column(
              children: [
                const Text("Огибающая:"),
                Center(
                  child: StreamBuilder(
                    stream: _controller.envelopeStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text('${snapshot.data!.last.sample}');
                      }
                      return const Text('...');
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: _controller.startEnvelope,
                        child: const Text("Старт")),
                    ElevatedButton(
                        onPressed: _controller.stopEnvelope,
                        child: const Text("Стоп")),
                  ],
                ),
              ],
            ),
          if (_controller.sensor
              .isSupportedParameter(SensorParameter.hardwareFilterState))
            Column(
              children: [
                const Text("Установить фильтры"),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: addFilters,
                        child: const Text("Добавить фильтры")),
                    ElevatedButton(
                        onPressed: removeLastFilter,
                        child: const Text("Удалить фильтр")),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  void setFirmwareMode(SensorFirmwareMode mode) {
    asyncSensorCallback(() => _controller.setFirmwareMode(mode));
  }

  void setGain(SensorGain gain) {
    asyncSensorCallback(() => _controller.setGain(gain));
  }

  void setOffset(SensorDataOffset offset) {
    asyncSensorCallback(() => _controller.setOffset(offset));
  }

  void setADCInput(SensorADCInput input) {
    asyncSensorCallback(() => _controller.setADCInput(input));
  }

  void setExternalSwitchInput(SensorExternalSwitchInput input) {
    asyncSensorCallback(() => _controller.setExternalSwitchInput(input));
  }

  void setFrequency(SensorSamplingFrequency frequency) {
    asyncSensorCallback(() => _controller.setFrequency(frequency));
  }

  void addFilters() {
    asyncSensorCallback(() => _controller.addFilters());
  }

  void removeLastFilter() {
    asyncSensorCallback(() => _controller.removeFilter());
  }

  Future<void> asyncSensorCallback(Future<void> Function() callback) async {
    try {
      await callback();
    } on SDKException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.cause)));
      return;
    }

    setState(() {});
  }
}

class ToggleButtons<T> extends StatelessWidget {
  final String firstButtonText;
  final T firstParam;

  final String secondButtonText;
  final T secondParam;

  final void Function(T) onButtonPressed;

  final T? currentParam;

  const ToggleButtons(
      {super.key,
      required this.firstButtonText,
      required this.firstParam,
      required this.secondButtonText,
      required this.secondParam,
      required this.onButtonPressed,
      required this.currentParam});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: currentParam != firstParam
                  ? () => onButtonPressed(firstParam)
                  : null,
              child: Text(firstButtonText),
            ),
            ElevatedButton(
              onPressed: currentParam != secondParam
                  ? () => onButtonPressed(secondParam)
                  : null,
              child: Text(secondButtonText),
            ),
          ],
        ),
      ],
    );
  }
}
