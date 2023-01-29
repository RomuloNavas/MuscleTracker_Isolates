import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate/neuro_sdk_isolate.dart';
import 'package:neuro_sdk_isolate_example/controllers/services_manager.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/controllers/search_controller.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/widgets/prepare.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/widgets/search_body.dart';
import 'package:neuro_sdk_isolate_example/screens/sensor_registration/sensor_screen.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_header.dart';

class SearchingSensorsScreen extends StatefulWidget {
  final Function() notifyParentStopScanner;
  final Function() notifyParentStartScanner;
  const SearchingSensorsScreen({
    Key? key,
    required this.notifyParentStopScanner,
    required this.notifyParentStartScanner,
  }) : super(key: key);

  @override
  State<SearchingSensorsScreen> createState() => _SearchingSensorsScreenState();
}

AnimationController? _animationController;

int countDown = 10;
Timer? timer;

class _SearchingSensorsScreenState extends State<SearchingSensorsScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    _animationController = AnimationController(
      vsync: this,
    );

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        countDown--;
      });
      if (countDown == 2 || countDown == 4 || countDown == 6 ) {
        // There is a bug in library that doesn't find any device, it gets to work after calling several times startScanner()
        widget.notifyParentStartScanner();
      }
      if (countDown <= 0) {
        widget.notifyParentStopScanner();
        t.cancel();
        countDown = 10;
      }
    });
    _startAnimation();

    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    setState(() {
      if (_animationController != null) {
        _animationController!
          ..stop()
          ..reset()
          ..repeat(period: const Duration(seconds: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 12,
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            child: _animationController != null
                ? CustomPaint(painter: SpritePainter(_animationController!))
                : const SizedBox(
                    width: 8,
                  ),
          ),
        ),
        const Positioned(
          top: 0,
          child: AppHeaderInfo(
            title: "Searching for Callibri devices",
            labelPrimary: 'It is going to take just a few seconds',
          ),
        ),
        Positioned(
          top: 80,
          child: Text('$countDown',
              style: Get.isDarkMode
                  ? AppTheme.appDarkTheme.textTheme.headline1
                  : AppTheme.appTheme.textTheme.headline1),
        ),
      ],
    );
  }
}

class SpritePainter extends CustomPainter {
  final Animation<double> _animation;

  SpritePainter(this._animation) : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 4.0)).clamp(0.0, 1.0);

    Color color = Get.isDarkMode
        ? Color.fromRGBO(33, 33, 33, opacity)
        : Color.fromRGBO(232, 233, 234, opacity);

    double size = rect.width;
    double area = size * size * 4;
    double radius = math.sqrt(area * value / 6);

    final Paint paint = Paint()
      // ..style = PaintingStyle.stroke
      // ..strokeWidth = 5
      ..color = color;

    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    for (int wave = 8; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(SpritePainter oldDelegate) {
    return true;
  }
}
