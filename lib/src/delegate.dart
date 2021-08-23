import 'dart:developer' as dev;
import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';

typedef NavigatorWrapper = Widget Function(Navigator navigator);

class AppRouteDelegate extends RouterDelegate<AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoute> {
  final RouteManager _routeManager;

  /// Called when delegate builds.
  /// Allows to wrap navigator with custom widgets.
  final NavigatorWrapper? _navigatorWrapper;

  AppRouteDelegate({
    required RouteManager routeManager,
    NavigatorWrapper? navigatorWrapper,
  })  : _routeManager = routeManager,
        _navigatorWrapper = navigatorWrapper {
    routeManager.addListener(notifyListeners);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator(
      key: navigatorKey,
      pages: _routeManager.pages,
      onPopPage: (route, dynamic result) {
        final didPop = route.didPop(result);
        if (!didPop) {
          return false;
        }
        if (route.settings is AppPage) {
          try {
            _routeManager.removePage(route.settings as AppPage, result);
          } catch (e) {
            dev.log("[${route.settings.name}] $e",
                name: runtimeType.toString());
          }
        }
        return true;
      },
    );
    return _navigatorWrapper?.call(navigator) ?? navigator;
  }

  @override
  Future<void> setNewRoutePath(AppRoute configuration) async =>
      _routeManager.push(configuration);

  @override
  GlobalKey<NavigatorState> get navigatorKey => _routeManager.navigatorKey;
}
