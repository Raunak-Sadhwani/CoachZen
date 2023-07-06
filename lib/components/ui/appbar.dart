import 'package:animations/animations.dart';
import 'package:flutter/material.dart';



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

// ignore: unused_element
class OpenContainerWrapper extends StatelessWidget {
  const OpenContainerWrapper({super.key, 
    required this.page,
    required this.content,
    this.openColor,
    // required this.onClosed,
  });

  // final ClosedCallback<bool?> onClosed;
  final Widget page;
  final Widget content;
  final Color? openColor;

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
          onTap: openContainer,
          child: content,
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }
}