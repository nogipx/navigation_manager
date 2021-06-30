import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';
import 'package:navigation_manager/src/observer.dart';

class RouteManager with ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final bool debugging;
  static AppRouteObserver observer;

  final AppRoute initialRoute;
  final Map<String, dynamic> initialRouteArgs;
  final AppRoute Function(AppRoute route) onUnknownRoute;
  final Widget Function(RouteManager manager, AppRoute route, Widget page)
      pageWrapper;

  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  final Widget Function(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) transitionProvider;

  List<AppPage> _pages;

  RouteManager({
    @required this.initialRoute,
    @required this.onUnknownRoute,
    this.debugging = false,
    this.initialRouteArgs,
    this.pageWrapper,
    this.transitionProvider,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
  }) : assert(onUnknownRoute != null && initialRoute != null) {
    final _initRoute = initialRoute.fill();
    _pages = [
      AppPage(
        key: ObjectKey(_initRoute),
        route: _initRoute,
        child: _getPageBuilder(_initRoute).call(initialRouteArgs),
        name: _initRoute.actualUri.toString(),
        restorationId: _initRoute.template,
        transitionProvider: transitionProvider,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
      )
    ];
  }

  List<AppPage> get pages => List.unmodifiable(_pages);
  List<AppRoute> get routes =>
      List.unmodifiable(pages.map<AppRoute>((e) => e.route));

  AppPage get _currentPage => pages.isNotEmpty ? pages.last : null;
  AppRoute get currentRoute => _currentPage?.route;

  void log(Object message) => debugging
      ? dev.log(message.toString(), name: runtimeType.toString())
      : null;

  void removePage(AppPage page, dynamic result) {
    final route = page.route;

    if (route.isSubRoot) {
      final subTree = pages.getSubTrees().find(route);

      if (subTree != null) {
        final newRoutes = pages.removeSubTree(route);
        subTree.children.reversed.forEach((page) {
          observer?.notifyRemove(page.customPage.route);
        });
        observer?.notifyRemove(subTree.root.customPage.route);

        _pages = newRoutes;
      } else {
        log("No subtree with root $route");
      }
    } else {
      _actualRemovePage(page, result);
    }
    notifyListeners();
  }

  void remove(AppRoute route, {dynamic data}) {
    final page = pages.getPageWithIndex(route);
    if (page != null) {
      removePage(page.value, data);
    } else {
      log("No page with $route found.");
    }
  }

  void removeUntil(AppRoute route) {
    final page = pages.getPageWithIndex(route);
    if (page != null) {
      final lastPageIndex = _pages.length - 1;
      if (page.key != lastPageIndex) {
        _pages.removeRange(page.key + 1, lastPageIndex);
      }
      notifyListeners();
    } else {
      log("No page for $route");
    }
  }

  void pop() => removePage(_currentPage, null);

  void push(AppRoute route, {Map<String, dynamic> data}) {
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
      }

      // Cases when the new route is a sub-root
      // and is the same as the current visible route.
      else if (_currentPage.route == route) {
        switch (strategy) {
          case SubRootDuplicateStrategy.Ignore:
            log("[$strategy] Ignore pushing duplicate of $route.");
            break;
          case SubRootDuplicateStrategy.Append:
            _actualPushRoute(route);
            break;
          case SubRootDuplicateStrategy.MakeVisibleOrReset:
            log("[$strategy] Pushed $route is the same with current visible.");
            break;
          case SubRootDuplicateStrategy.MakeVisible:
            log("[$strategy] Pushed $route is the same with current visible.");
            break;
        }
      }

      // Cases when the new route is a sub-root
      // and is NOT same with current visible route.
      // For example, other bottom navigation tab.
      else {
        final visibleSubtree = subTrees.isNotEmpty ? subTrees.last : null;

        if (visibleSubtree == null) {
          _actualPushRoute(route);
        } else if (visibleSubtree.root.customPage.route == route) {
          switch (strategy) {
            case SubRootDuplicateStrategy.Ignore:
              log("[$strategy] Ignore pushing duplicate of $route.");
              break;
            case SubRootDuplicateStrategy.MakeVisible:
              log("[$strategy] Sub-tree with root $route is already visible.");
              break;
            case SubRootDuplicateStrategy.MakeVisibleOrReset:
              final newRoutes = pages.subTreeMovedDown(route, reset: true);
              _pages = newRoutes;
              observer?.notifyDouble(route);
              break;
            case SubRootDuplicateStrategy.Append:
              _actualPushRoute(route);
              break;
          }
        } else {
          switch (strategy) {
            case SubRootDuplicateStrategy.Ignore:
              log("[$strategy] Ignore pushing duplicate of $route.");
              break;
            case SubRootDuplicateStrategy.MakeVisible:
              final newRoutes = pages.subTreeMovedDown(route, reset: false);
              _pages = newRoutes;
              observer?.notifyDouble(route);
              break;
            case SubRootDuplicateStrategy.MakeVisibleOrReset:
              final newRoutes = pages.subTreeMovedDown(route, reset: false);
              _pages = newRoutes;
              observer?.notifyDouble(route);
              break;
            case SubRootDuplicateStrategy.Append:
              _actualPushRoute(route);
              break;
          }
        }
      }
    }

    // If new route is not sub root then just push it.
    else {
      if (_currentPage.route == route) {
        final strategy = route.duplicateStrategy;
        switch (strategy) {
          case DuplicateStrategy.Ignore:
            log("Ignore pushing duplicate of $route");
            break;
          case DuplicateStrategy.Replace:
            remove(route);
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
      child: _getPageBuilder(route).call(route.data),
      restorationId: route.actualUri.toString(),
      transitionProvider: transitionProvider,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
    observer?.notifyPush(route);
    _pages.add(page);
  }

  void _actualRemovePage(AppPage page, dynamic result) {
    observer?.notifyRemove(page.route);
    _pages.remove(page);
  }

  /// Returns page builder function defined in mapping.
  /// If route has not builder, throws [ArgumentError].
  Widget Function(Map<String, dynamic> data) _getPageBuilder(AppRoute route) {
    if (route.builder != null) {
      if (pageWrapper != null) {
        return (Map<String, dynamic> data) {
          return pageWrapper.call(this, route, route.builder.call(data));
        };
      } else {
        return route.builder;
      }
    } else {
      throw ArgumentError.notNull('builder');
    }
  }
}
