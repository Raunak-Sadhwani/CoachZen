import 'package:animations/animations.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
  final screenHeight =
      WidgetsBinding.instance.platformDispatcher.views.last.physicalSize.height;
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leftIcon;
  final List<Widget>? rightIcons;
  final String? title;
  final Widget? ftitle;
  final int? elevation;
  const MyAppBar({
    super.key,
    this.leftIcon,
    this.elevation,
    this.rightIcons,
    this.ftitle,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: elevation?.toDouble() ?? 0,
      leading: leftIcon,
      title: ftitle ??
          Text(
            title ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
      backgroundColor: Colors.white,
      actions: rightIcons,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


class OpenContainerWrapper extends StatelessWidget {
  const OpenContainerWrapper({
    super.key,
    required this.page,
    required this.content,
    this.openColor,
    this.onClosed,
    
  });

  
  final Widget page;
  final Widget content;
  final Color? openColor;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    return OpenContainer<bool>(
      openColor: openColor ?? Colors.white,
      closedColor: openColor ?? Colors.white,
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext context, VoidCallback _) {
        return page;
      },
      onClosed: null,
      tappable: false,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return GestureDetector(
          onTap: () {
            onClosed?.call();
            openContainer();
          },
          child: content,
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }
}

class Method {
  static Future<bool> checkInternetConnection(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      if (context.mounted) {
        Flushbar(
          margin: const EdgeInsets.all(7),
          borderRadius: BorderRadius.circular(15),
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.TOP,
          message: "No internet connection",
          icon: Icon(
            Icons.wifi_off,
            size: 28.0,
            color: Colors.blue[300],
          ),
          duration: const Duration(milliseconds: 3000),
          leftBarIndicatorColor: Colors.blue[300],
        ).show(context);
      }
      return false;
    }
    return true;
  }
}

