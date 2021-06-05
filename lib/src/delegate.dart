import 'dart:developer' as dev;
import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';

class AppRouteDelegate extends RouterDelegate<AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoute> {
  final RouteManager routeManager;
  final Widget Function(Widget navigator) navigatorWrapper;

  AppRouteDelegate({
    @required this.routeManager,
    this.navigatorWrapper,
  }) : assert(routeManager != null) {
    routeManager.addListener(notifyListeners);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator(
      key: navigatorKey,
      pages: routeManager.pages,
      onPopPage: (route, dynamic result) {
        final didPop = route.didPop(result);
        if (!didPop) {
          return false;
        }
        if (route.settings is AppPage) {
          try {
            routeManager.removePage(route.settings as AppPage, result);
          } catch (e) {
            dev.log("[${route.settings.name}] $e",
                name: runtimeType.toString());
          }
        }
        return true;
      },
    );
    return navigatorWrapper?.call(navigator) ?? navigator;
  }

  @override
  Future<void> setNewRoutePath(AppRoute configuration) async =>
      await routeManager.push(configuration);

  @override
  GlobalKey<NavigatorState> get navigatorKey => routeManager.navigatorKey;
}
