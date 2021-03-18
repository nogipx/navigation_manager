import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';

class RouteManager with ChangeNotifier {
  final AppRoute initialRoute;
  final AppRouteArgs initialRouteArgs;
  final AppRoute Function(AppRoute route) onUnknownRoute;
  final Map<AppRoute, Widget Function(AppRouteArgs data)> routes;
  final Widget Function(RouteManager manager, AppRoute route, Widget page) pageWrapper;

  /// Called after pushing a route.
  final bool Function(RouteManager, AppRoute) onPushRoute;

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

  List<AppPage> _pages;
  List<AppPage> get pages => List.unmodifiable(_pages);

  RouteManager({
    @required this.initialRoute,
    @required this.routes,
    @required this.onUnknownRoute,
    this.initialRouteArgs,
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
        child: _getPageBuilder(routes, _initRoute).call(initialRouteArgs),
        name: _initRoute.actualUri.toString(),
        restorationId: _initRoute.template,
        transitionProvider: transitionProvider,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
      )
    ];
  }

  AppPage get currentPage => pages.last;
  void log(Object message) => dev.log(
        message.toString(),
        name: runtimeType.toString(),
      );

  void removePage(AppPage page, dynamic result) {
    try {
      final route = page.route;
      if (route.isSubRoot) {
        final subTree = pages.getSubTrees().find(route);
        if (subTree != null) {
          final newRoutes = pages.removeSubTree(route);
          onRemoveRoute?.call(this, page.route);
          _pages = newRoutes;
        } else {
          log("No subtree with root $route");
        }
      } else {
        _removePage(page, result);
      }
    } catch (e) {
      throw Exception("Remove route aborted. \n$e");
    }
    notifyListeners();
  }

  void removeRoute(AppRoute route, {dynamic data}) {
    final page = pages.getPageWithIndex(route);
    if (page != null) {
      removePage(page.value, data);
    } else {
      log("No page with $route found.");
    }
  }

  void removeUntilRoute(AppRoute route) {
    final page = pages.getPageWithIndex(route);
    if (page != null) {
      final lastPageIndex = _pages.length - 1;
      if (page.key != lastPageIndex) {
        _pages.removeRange(page.key + 1, lastPageIndex);
        notifyListeners();
      } else {
        notifyListeners();
      }
    } else {
      log("No page for $route");
    }
  }

  void popRoute() => removePage(currentPage, null);

  void pushRoute(AppRoute route, {AppRouteArgs data}) {
    final _route = route.fill(data: data);
    _performPushRoute(_route);
  }

  void _performPushRoute(AppRoute route) {
    assert(route != null);
    if (route == null) {
      throw Exception("Null route is not allowed.");
    }
    if (route.isSubRoot) {
      final strategy = route.subRootDuplicateStrategy;
      final subTrees = _pages.getSubTrees();
      final isReallyNewRoute =
          !subTrees.map((e) => e.root.customPage.route).contains(route);

      if (isReallyNewRoute) {
        _actualPushRoute(route);
      } else if (currentPage.route == route) {
        switch (strategy) {
          case SubRootDuplicateStrategy.Ignore:
            log("Ignore pushing duplicate of $route.");
            break;
          case SubRootDuplicateStrategy.Append:
            _actualPushRoute(route);
            break;
          default:
            log("Inapplicable $strategy for current visible route $route.");
        }
      } else {
        final visibleSubtree = subTrees.isNotEmpty ? subTrees.last : null;

        if (visibleSubtree == null) {
          _actualPushRoute(route);
        } else if (visibleSubtree.root.customPage.route == route) {
          switch (strategy) {
            case SubRootDuplicateStrategy.Ignore:
              log("Ignore pushing duplicate of $route.");
              break;
            case SubRootDuplicateStrategy.MakeVisibleOrReset:
              final newRoutes = pages.subTreeMovedDown(route, reset: true);
              _pages = newRoutes;
              break;
            case SubRootDuplicateStrategy.Append:
              _actualPushRoute(route);
              break;
            default:
              log("Inapplicable $strategy for current "
                  "visible sub-tree with root $route.");
          }
        } else {
          switch (strategy) {
            case SubRootDuplicateStrategy.Ignore:
              log("Ignore pushing duplicate of $route.");
              break;
            case SubRootDuplicateStrategy.MakeVisible:
              final newRoutes = pages.subTreeMovedDown(route, reset: false);
              _pages = newRoutes;
              break;
            case SubRootDuplicateStrategy.MakeVisibleOrReset:
              final newRoutes = pages.subTreeMovedDown(route, reset: false);
              _pages = newRoutes;
              break;
            case SubRootDuplicateStrategy.Append:
              _actualPushRoute(route);
              break;
            default:
              log("Inapplicable $strategy for sub-tree with root $route.");
          }
        }
      }
    }

    // If new route is not sub root then just push it.
    else {
      if (currentPage.route == route) {
        final strategy = route.duplicateStrategy;
        switch (strategy) {
          case DuplicateStrategy.Ignore:
            log("Ignore pushing duplicate of $route");
            break;
          case DuplicateStrategy.Replace:
            removeRoute(route);
            _actualPushRoute(route);
            break;
          case DuplicateStrategy.Append:
            _actualPushRoute(route);
            break;
        }
      } else {
        _actualPushRoute(route);
      }
    }

    notifyListeners();
  }

  void _actualPushRoute(AppRoute route) {
    final page = AppPage(
      key: ObjectKey(route),
      route: route,
      name: route.actualUri.toString(),
      child: _getPageBuilder(routes, route).call(route.data),
      restorationId: route.actualUri.toString(),
      transitionProvider: transitionProvider,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
    try {
      onPushRoute?.call(this, route);
      _pages.add(page);
      // if (allowPush) {
      // } else {
      //   log("Prevent push $route.");
      // }
    } catch (e) {
      _pages.remove(page);
      throw Exception("Push route aborted. \n$e");
    }
  }

  void _removePage(AppPage page, dynamic result) {
    onRemoveRoute?.call(this, page.route);
    _pages.remove(page);
  }

  /// Returns page builder function defined in mapping.
  /// If route is unknown, then ask for redirection route.
  Widget Function(AppRouteArgs data) _getPageBuilder(
    Map<AppRoute, Widget Function(AppRouteArgs data)> routes,
    AppRoute route,
  ) {
    Widget Function(AppRouteArgs data) _pageBuilder = routes[route];

    if (_pageBuilder == null) {
      log("No page builder for $route");

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
      return (AppRouteArgs data) {
        return pageWrapper.call(this, route, _pageBuilder.call(data));
      };
    } else {
      return _pageBuilder;
    }
  }
}
