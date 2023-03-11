import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leftIcon;
  final List<Widget>? rightIcons;
  final String? title;
  final Widget? ftitle;
  const MyAppBar({
    super.key,
    this.leftIcon,
    this.rightIcons,
    this.ftitle,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
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
