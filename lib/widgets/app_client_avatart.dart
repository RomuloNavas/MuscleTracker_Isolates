import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';

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
                  45,
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
                      80,
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
