import 'package:flutter/material.dart';

Color darkerColorFrom({required Color color, double amount = .1}) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighterColorFrom({required Color color, double amount = .1}) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}

calculateAgeFromDateTime(DateTime birthDate) {
  DateTime currentDate = DateTime.now();
  int age = currentDate.year - birthDate.year;
  int month1 = currentDate.month;
  int month2 = birthDate.month;
  if (month2 > month1) {
    age--;
  } else if (month1 == month2) {
    int day1 = currentDate.day;
    int day2 = birthDate.day;
    if (day2 > day1) {
      age--;
    }
  }
  return age;
}

String restrictFractionalSeconds(String dateTime) =>
    dateTime.replaceFirstMapped(RegExp(r"(\.\d{6})\d+"), (m) => m[1]!);

String getMinutesAndSecondsFromDuration({required Duration duration}) {
  var _duration = Duration(milliseconds: duration.inMilliseconds.round());
  return [_duration.inMinutes, _duration.inSeconds]
      .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
      .join(':');
}

String getMinutesAndSecondsFromDurationWithSign({required Duration duration}) {
  var _duration = Duration(milliseconds: duration.inMilliseconds.round());
  return [_duration.inMinutes, _duration.inSeconds]
          .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
          .join('m ') +
      's';
}

String buildTextFromAmplitude({required double amplitude}) {
  String amplitudeText = '$amplitude';
  if (amplitude <= 0.1 && amplitude > 0.0009) {
    amplitudeText = '${(amplitude * 1000).toStringAsFixed(1)} mV';
  } else if (amplitude <= 0.0009 && amplitude >= 0) {
    amplitudeText = '${(amplitude * 1000000).toStringAsFixed(1)} μV';
  }
  return amplitudeText;
}

double getAverage(List<double> values) {
  final average =
      values.reduce((value, element) => value + element) / values.length;
  return average;
}

String iso8601StringToDate(String iso8601String) {
  var date = iso8601String.split('T').first;
  return date;
}

String iso8601StringToHour(String iso8601String) {
  var time = iso8601String.split('T').last;
  if (time.length >= 5) {
    time = time.substring(0, 5);
  }

  return time;
}
