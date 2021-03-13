import 'package:flutter/material.dart';
import 'package:navigation_manager/navigation_manager.dart';

class AppPage extends Page {
  final String name;
  final Widget child;
  final Object arguments;
  final String restorationId;
  final AppRoute route;

  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  final Widget Function(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) transitionProvider;

  AppPage({
    Key key,
    @required this.name,
    @required this.child,
    @required this.route,
    this.restorationId,
    this.arguments,
    this.transitionProvider,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
  }) : super(key: key, name: name, restorationId: restorationId);

  Route createRoute(BuildContext context) {
    if (transitionProvider != null) {
      return PageRouteBuilder(
        settings: this,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
        pageBuilder: (context, _, __) => child,
        transitionsBuilder: (context, animation, animation2, page) {
          return transitionProvider(page, animation, animation2);
        },
      );
    } else {
      return MaterialPageRoute(
        settings: this,
        builder: (context) => child,
      );
    }
  }
}
