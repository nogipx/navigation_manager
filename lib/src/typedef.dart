import 'package:flutter/widgets.dart';
import 'package:navigation_manager/navigation_manager.dart';

typedef TransitionProvider = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);

typedef PageWrapper = Widget Function(
  RouteManager manager,
  AppRoute route,
  Widget page,
);

typedef NavigatorWrapper = Widget Function(Navigator navigator);
