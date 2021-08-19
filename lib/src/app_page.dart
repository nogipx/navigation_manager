import 'package:flutter/material.dart';
import 'package:navigation_manager/navigation_manager.dart';

class AppPage extends Page<AppPage> {
  final AppRoute route;
  final Widget child;

  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  final Widget Function(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  )? transitionProvider;

  const AppPage({
    LocalKey? key,
    required String name,
    required this.child,
    required this.route,
    String? restorationId,
    Object? arguments,
    this.transitionProvider,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
  }) : super(
          key: key,
          name: name,
          restorationId: restorationId,
          arguments: arguments,
        );

  @override
  Route<AppPage> createRoute(BuildContext context) {
    if (transitionProvider != null) {
      return PageRouteBuilder(
        settings: this,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
        pageBuilder: (context, _, __) => child,
        transitionsBuilder: (context, animation, animation2, page) {
          return transitionProvider?.call(page, animation, animation2) ??
              SizedBox();
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
