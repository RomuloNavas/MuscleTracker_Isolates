import 'package:flutter/material.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_buttons.dart';

class AppMuscleSideIndicator extends StatelessWidget {
  final String side;
  final ButtonSize? size;
  const AppMuscleSideIndicator({
    required this.side,
    this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color leftColor = Color(0xff5950EB);
    final Color rightColor = Color(0xffEB8A50);
    if (size == ButtonSize.big) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: side == 'left' ? leftColor : rightColor,
          borderRadius: size == ButtonSize.big
              ? BorderRadius.circular(4)
              : BorderRadius.circular(2),
          border: Border.all(
            width: 1.0,
            color: side == 'left' ? leftColor : rightColor,
          ),
        ),
        child: Text(side.toString(),
            style: AppTheme.appDarkTheme.textTheme.button?.copyWith(
              color: Colors.white,
            )),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      margin: size == ButtonSize.big ? EdgeInsets.all(2) : null,
      decoration: BoxDecoration(
        color: side == 'left'
            ? leftColor.withOpacity(0.3)
            : rightColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          width: 1.0,
          color: side == 'left' ? leftColor : rightColor,
        ),
      ),
      child: Text(side.toString(),
          style: AppTheme.appDarkTheme.textTheme.caption?.copyWith(
            color: side == 'left' ? leftColor : rightColor,
          )),
    );
  }
}
