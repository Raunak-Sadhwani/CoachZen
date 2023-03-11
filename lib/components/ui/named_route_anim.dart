import 'package:slimtrap/main.dart';
import 'package:flutter/material.dart';

GlobalKey materialAppKey = MyApp.mtAppKey;

class CustomNamedPageTransition extends PageRouteBuilder {
  CustomNamedPageTransition(
    String routeName, {
    Object? arguments,
  }) : super(
          settings: RouteSettings(
            arguments: arguments,
            name: routeName,
          ),
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            assert(materialAppKey.currentWidget != null);
            assert(materialAppKey.currentWidget is MaterialApp);
            var mtapp = materialAppKey.currentWidget as MaterialApp;
            var routes = mtapp.routes;
            assert(routes!.containsKey(routeName));
            return routes![routeName]!(context);
          },
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              // zoom in from the clicked widget to the new page
              ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 1000),
        );
}
