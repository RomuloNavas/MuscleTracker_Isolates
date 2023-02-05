import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class AppBottomSheetHeader extends StatelessWidget {
  final String text;
  const AppBottomSheetHeader({
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            text,
            style: AppTheme.appTheme.textTheme.headline5?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class AppBottomSheetButton extends StatelessWidget {
  const AppBottomSheetButton({
    Key? key,
    required this.text,
    required this.svgFileName,
    required this.onPressed,
  }) : super(key: key);

  final String svgFileName;
  final String text;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ZoomTapAnimation(
      end: 0.98,
      onTap: onPressed,
      child: ListTile(
        title: Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
        leading: SvgPicture.asset(
          'assets/icons/ui/$svgFileName.svg',
          width: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
