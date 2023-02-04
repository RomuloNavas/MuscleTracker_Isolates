import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:neuro_sdk_isolate_example/database/client_operations.dart';
import 'package:neuro_sdk_isolate_example/theme.dart';
import 'package:neuro_sdk_isolate_example/widgets/app_pop_menu_item_child.dart';

class PopMenuButtonClients extends StatelessWidget {
  final Function() notifyParentClientDeleted;
  final Function() notifyParentClientAddedToFavorites;
  final Client client;
  PopMenuButtonClients({
    Key? key,
    required this.client,
    required this.notifyParentClientDeleted,
    required this.notifyParentClientAddedToFavorites,
  }) : super(key: key);

  final clientOperations = ClientOperations();

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
        icon: ScaleTap(
          scaleMinValue: 0.9,
          opacityMinValue: 0.4,
          scaleCurve: Curves.decelerate,
          opacityCurve: Curves.fastOutSlowIn,
          child: SvgPicture.asset(
            'assets/icons/ui/more-vert.svg',
            width: 32,
            color: Get.isDarkMode
                ? AppTheme.appDarkTheme.colorScheme.tertiary
                : AppTheme.appTheme.colorScheme.tertiary,
          ),
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
                  await clientOperations.updateClient(client);
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
                  await clientOperations.deleteClient(client);
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
