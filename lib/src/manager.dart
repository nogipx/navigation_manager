import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

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
  List<AppRoute> _appRoutes;
  List<Page> get pages => List.unmodifiable(_pages);

  Map<AppRoute, List<RouteSettings>> _subRoutes;

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
      CustomPage(
        key: ObjectKey(_initRoute),
        child: _getPageBuilder(routes, _initRoute).call(<String, dynamic>{}),
        name: _initRoute.actualUri.toString(),
        transitionProvider: transitionProvider,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
      )
    ];
    _appRoutes = routes.keys.toList();
  }

  Future<AppRoute> get currentRoute async {
    final routes = await _pages.asRoutes(_appRoutes);
    return routes.last?.value?.fill();
  }

  void removePage(Page page, dynamic result) async {
    try {
      onRemoveRoute?.call(this, await currentRoute);
      _pages.remove(page);
    } catch (e) {
      throw Exception("Remove route aborted. \n$e");
    }
    notifyListeners();
  }

  void popRoute() => removePage(_pages.last, null);

  Future<void> pushRoute(AppRoute route, {Map<String, dynamic> data}) async {
    assert(route != null);
    if (route == null) {
      throw Exception("Null route is not allowed.");
    }

    final curRoute = await currentRoute;

    // If pushed route is sub-root then find last sub-route
    // It could be identical - choose strategy (keep or reset)
    // Or it could be different - then switch sub tree
    if (route.isSubRoot) {
      final lastSubroot = await pages.findLastSubRootIndex(_appRoutes);

      // Check is new sub-root is the same with last in tree.
      if (lastSubroot.value == route) {
        final hasNoSubRootChildren = lastSubroot.key == _pages.length - 1;
        if (hasNoSubRootChildren) {
          dev.log("${lastSubroot.value} has no children pages.");
          return;
        }
        if (_shouldDoubleSubRootRouteReset(route)) {
          _pages.sublist(lastSubroot.key + 1, _pages.length).forEach((e) {
            removePage(e, null);
          });
        }
      } else if (lastSubroot.value == null) {
        _pushRoute(route, data: data);
      } else {
        // Swap sub-trees if routes are different
      }
    } else {
      if (curRoute == route) {
        if (_shouldDoubleRoutePush(route)) {
          _pushRoute(route, data: data);
        }
      } else {
        final uniqRoute = AppRoute.uniq(route.template, data: data);
        _pushRoute(uniqRoute, data: data);
      }
    }

    notifyListeners();
  }

  void _pushRoute(AppRoute route, {Map<String, dynamic> data}) {
    final _route = route.fill(data: data);
    final page = CustomPage(
      key: ObjectKey(_route),
      name: _route.actualUri.toString(),
      child: _getPageBuilder(routes, _route).call(data),
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

  bool _shouldDoubleSubRootRouteReset(AppRoute _pushedRoute) {
    return onDoublePushSubRootRoute?.call(this, _pushedRoute) ?? false;
  }

  bool _shouldDoubleRoutePush(AppRoute _pushedRoute) {
    return onDoublePushRoute?.call(this, _pushedRoute) ?? false;
  }

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

extension RouteList on List<RouteSettings> {
  Future<MapEntry<int, AppRoute>> findLastSubRootIndex(List<AppRoute> appRoutes) async {
    final pageRoutes = await this.asRoutes(appRoutes);

    final subRoots =
        pageRoutes.where((e) => e.value != null && e.value.isSubRoot).toList();
    final result = subRoots.fold(
      MapEntry(-1, null),
      (a, b) => b.key > a.key ? b : a,
    );
    return result;
  }

  List<RouteSettings> resetToLastRoute(AppRoute route) {}

  MapEntry<int, AppRoute> findPageByRoute(AppRoute) {}

  Future<List<MapEntry<int, AppRoute>>> asRoutes(List<AppRoute> appRoutes) async {
    final appRouteParsers = appRoutes.map((e) => UriParser(e.uriTemplate)).toList();
    final pageUriNames =
        asMap().map((k, v) => MapEntry(k, Uri.parse(v.name))).entries.toList();

    final List<MapEntry<int, AppRoute>> pageRoutes = await Future.wait(
      pageUriNames.map(
        (pageName) async {
          final routeTemplate = appRouteParsers
              .lastWhere((parser) => parser.matches(pageName.value), orElse: () => null)
              ?.template
              ?.template;
          if (routeTemplate != null) {
            final route = appRoutes.firstWhere(
              (e) => e.template.contains(routeTemplate),
              orElse: () => null,
            );
            return MapEntry<int, AppRoute>(pageName.key, route);
          } else {
            return null;
          }
        },
      ),
    );
    return pageRoutes;
  }
}
