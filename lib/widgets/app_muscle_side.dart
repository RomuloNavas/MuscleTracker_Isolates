import 'package:flutter/material.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

class AppMuscleSideIndicator extends StatelessWidget {
  final String side;
  const AppMuscleSideIndicator({
    required this.side,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 1, 8, 1),
      decoration: BoxDecoration(
        color: side == 'left'
            ? Color(0xff1727B3).withOpacity(0.3)
            : Color(0xff004457).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1.0,
          color: side == 'left' ? Color(0xff1727B3) : Color(0xff004457),
        ),
      ),
      child: Text(side.toString(),
          style: AppTheme.appDarkTheme.textTheme.caption?.copyWith(
            color: side == 'left' ? Color(0xff1727B3) : Color(0xff004457),
          )),
    );
  }
}
