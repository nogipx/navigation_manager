import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';

class RouteManager with ChangeNotifier {
  final AppRoute initialRoute;
  final AppRoute Function(AppRoute route) onUnknownRoute;
  final Map<AppRoute, Widget Function(Map<String, dynamic> data)> routes;
  final Widget Function(RouteManager manager, AppRoute route, Widget page) pageWrapper;

  /// Called after pushing a route.
  final Function(RouteManager, AppRoute) onPushRoute;

  /// Called before removing a route.
  final Function(RouteManager, AppRoute) onRemoveRoute;

  /// Called when pushed route is the same with current.
  /// If `onDoublePushRoute` returns `true` then route will be pushed.
  /// Otherwise if returns `false` then prevents push.
  /// Returns `false` by default.
  final bool Function(RouteManager, AppRoute) onDoublePushRoute;

  /// Called when pushed route is the same with current and route is root.
  /// If `onDoublePushSubRootRoute` returns `true`
  /// then other routes after pushed route will be deleted.
  /// Otherwise if returns `false` then prevent push, that is, does nothing.
  /// Returns `false` by default.
  final bool Function(RouteManager, AppRoute) onDoublePushSubRootRoute;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  final Widget Function(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) transitionProvider;

  List<RouteSettings> _pages;
  List<AppPage> get pages => List.unmodifiable(_pages);

  RouteManager({
    @required this.initialRoute,
    @required this.routes,
    @required this.onUnknownRoute,
    this.pageWrapper,
    this.onPushRoute,
    this.onRemoveRoute,
    this.onDoublePushRoute,
    this.onDoublePushSubRootRoute,
    this.transitionProvider,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
  }) : assert(routes != null && onUnknownRoute != null && initialRoute != null) {
    final _initRoute = initialRoute.fill();
    _pages = [
      AppPage(
        key: ObjectKey(_initRoute),
        route: _initRoute,
        child: _getPageBuilder(routes, _initRoute).call(<String, dynamic>{}),
        name: _initRoute.actualUri.toString(),
        restorationId: _initRoute.template,
        transitionProvider: transitionProvider,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
      )
    ];
  }

  AppPage get currentPage => pages.last;

  void removePage(AppPage page, dynamic result) async {
    try {
      onRemoveRoute?.call(this, page.route);
      _pages.remove(page);
    } catch (e) {
      throw Exception("Remove route aborted. \n$e");
    }
    notifyListeners();
  }

  void popRoute() => removePage(currentPage, null);

  Future<void> pushRoute(AppRoute route, {Map<String, dynamic> data}) async {
    assert(route != null);
    if (route == null) {
      throw Exception("Null route is not allowed.");
    }
    final _route = route.fill(data: data);

    // If pushed route is sub-root then find nearest sub-route
    // It could be identical - choose strategy (keep or reset)
    // Or it could be different - then switch sub tree
    if (route.isSubRoot) {
      final subTree = pages.getSubTrees().find(route);
      if (subTree != null) {
        final needReset = _shouldResetSubtree(route);
        final newRoutes = pages.subTreeMovedDown(route, reset: needReset);
        _pages = newRoutes;
      } else {
        _pushRoute(route, data: data);
      }
    }

    // If new route is not sub root then just push it.
    else {
      if (currentPage.route == _route) {
        if (_shouldPushSameRoute(_route)) {
          _pushRoute(_route, data: data);
        }
      } else {
        _pushRoute(_route, data: data);
      }
    }

    notifyListeners();
  }

  void _pushRoute(AppRoute route, {Map<String, dynamic> data}) {
    final _route = route.fill(data: data);
    final page = AppPage(
      key: ObjectKey(_route),
      route: _route,
      name: _route.actualUri.toString(),
      child: _getPageBuilder(routes, _route).call(data),
      restorationId: _route.actualUri.toString(),
      transitionProvider: transitionProvider,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
    _pages.add(page);
    try {
      onPushRoute?.call(this, _route);
    } catch (e) {
      _pages.remove(page);
      throw Exception("Push route aborted. \n$e");
    }
  }

  bool _shouldResetSubtree(AppRoute route) =>
      route.isSubRoot && (onDoublePushSubRootRoute?.call(this, route) ?? false);

  bool _shouldPushSameRoute(AppRoute route) =>
      onDoublePushRoute?.call(this, route) ?? false;

  /// Returns page builder function defined in mapping.
  /// If route is unknown, then ask for redirection route.
  Widget Function(Map<String, dynamic> data) _getPageBuilder(Map routes, AppRoute route) {
    Widget Function(Map<String, dynamic> data) _pageBuilder = routes[route];

    if (_pageBuilder == null) {
      dev.log("No page builder for $route", name: runtimeType.toString());

      final _unknownRoute = onUnknownRoute(route)?.fill(data: route.data);
      if (routes.containsKey(_unknownRoute)) {
        _pageBuilder = routes[_unknownRoute];
      }

      if (_pageBuilder == null) {
        throw Exception(
          "Push route aborted. No page builder for 'unknown' $_unknownRoute",
        );
      }
    }

    if (pageWrapper != null) {
      return (Map<String, dynamic> data) {
        return pageWrapper.call(this, route, _pageBuilder.call(data));
      };
    } else {
      return _pageBuilder;
    }
  }
}
