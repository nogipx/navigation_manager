import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';

class AppRouteDelegate extends RouterDelegate<AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoute> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();
  final RouteManager routeManager;

  AppRouteDelegate({
    @required this.routeManager,
  }) : assert(routeManager != null) {
    routeManager.addListener(notifyListeners);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      pages: routeManager.pages,
      onPopPage: (route, dynamic result) {
        final didPop = route.didPop(result);
        if (!didPop) {
          return false;
        }
        if (route.settings is MaterialPage) {
          routeManager.removeRoute(route.settings as MaterialPage, result);
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoute configuration) async =>
      routeManager.pushRoute(configuration);

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}
