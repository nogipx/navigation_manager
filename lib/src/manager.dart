import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';
import 'package:navigation_manager/src/observer.dart';

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

class RouteManager with ChangeNotifier {
  static AppRouteObserver? observer;
  final bool debugging;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Route with which app will be initialized.
  final AppRoute _initialRoute;

  /// Optional arguments for initial route.
  final Map<String, dynamic> _initialRouteArgs;

  /// Called when new route pushed.
  /// Allows to wrap every route with custom widgets.
  final PageWrapper? _routeBuildInterceptor;

  final Duration? _transitionDuration;
  final Duration? _reverseTransitionDuration;

  final TransitionProvider? _transitionProvider;

  late List<AppPage> _pages;

  RouteManager({
    required AppRoute initialRoute,
    this.debugging = false,
    Map<String, dynamic> initialRouteArgs = const <String, dynamic>{},
    PageWrapper? routeBuildInterceptor,
    TransitionProvider? transitionProvider,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
  })  : _initialRoute = initialRoute,
        _initialRouteArgs = initialRouteArgs,
        _routeBuildInterceptor = routeBuildInterceptor,
        _transitionProvider = transitionProvider,
        _transitionDuration = transitionDuration,
        _reverseTransitionDuration = reverseTransitionDuration {
    final _initRoute = _initialRoute.fill();
    _pages = [
      AppPage(
        key: ObjectKey(_initRoute),
        route: _initRoute,
        child: _getPageBuilder(_initRoute).call(_initialRouteArgs),
        name: _initRoute.actualUri.toString(),
        restorationId: _initRoute.template,
        transitionProvider: _transitionProvider,
        transitionDuration: _transitionDuration,
        reverseTransitionDuration: _reverseTransitionDuration,
      )
    ];
  }

  @internal
  List<AppPage> get pages => List.unmodifiable(_pages);

  List<AppRoute> get routes =>
      List.unmodifiable(pages.map<AppRoute>((e) => e.route));

  AppPage get _currentPage => pages.last;
  AppRoute get currentRoute => _currentPage.route;

  void _log(Object message) => debugging
      ? dev.log(message.toString(), name: runtimeType.toString())
      : null;

  @internal
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
        _log("No subtree with root $route");
      }
    } else {
      _actualRemovePage(page, result);
    }
    notifyListeners();
  }

  /// Removes the specified route from the routes list.
  /// If the specified route is sub-root then entire sub-tree will be deleted.
  void remove(AppRoute route, {dynamic data}) {
    final page = pages.getPageWithIndex(route);
    if (page != null) {
      removePage(page.value, data);
    } else {
      _log("No page with $route found.");
    }
  }

  /// Removes all routes from the routes list after the specified.
  void removeUntil(AppRoute route) {
    final page = pages.getPageWithIndex(route);
    if (page != null) {
      final lastPageIndex = _pages.length - 1;
      if (page.key != lastPageIndex) {
        _pages.removeRange(page.key + 1, lastPageIndex);
      }
      notifyListeners();
    } else {
      _log("No page for $route");
    }
  }

  void replaceAll(List<AppRoute> replaceWith) {
    if (replaceWith.isNotEmpty) {
      _pages.clear();
      replaceWith.forEach((e) => _performPushRoute(e.fill()));
      notifyListeners();
    } else {
      _log('List of routes to replace should not be empty.');
    }
  }

  // void replaceUntil(AppRoute route, List<AppRoute> replaceWith) {}

  void replaceLast(AppRoute replaceWith, {Map<String, dynamic>? data}) {
    _pages.removeLast();
    push(replaceWith, data: data);
  }

  void pop() => removePage(_currentPage, null);

  void push(AppRoute route, {Map<String, dynamic>? data}) {
    final _route = route.fill(data: data);
    _performPushRoute(_route);
    notifyListeners();
  }

  void _performPushRoute(AppRoute route) {
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
      else if (_pages.isNotEmpty && _currentPage.route == route) {
        switch (strategy) {
          case SubRootDuplicateStrategy.Ignore:
            _log("[$strategy] Ignore pushing duplicate of $route.");
            break;
          case SubRootDuplicateStrategy.Append:
            _actualPushRoute(route);
            break;
          case SubRootDuplicateStrategy.MakeVisibleOrReset:
            _log("[$strategy] Pushed $route is the same with current visible.");
            break;
          case SubRootDuplicateStrategy.MakeVisibleOrPop:
            _log("[$strategy] Pushed $route is the same with current visible.");
            break;
          case SubRootDuplicateStrategy.MakeVisible:
            _log("[$strategy] Pushed $route is the same with current visible.");
            break;
          case SubRootDuplicateStrategy.None:
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
              _log("[$strategy] Ignore pushing duplicate of $route.");
              break;
            case SubRootDuplicateStrategy.MakeVisible:
              _log("[$strategy] Sub-tree with root $route is already visible.");
              break;
            case SubRootDuplicateStrategy.MakeVisibleOrReset:
              final newRoutes = pages.subTreeMovedDown(route, reset: true);
              _pages = newRoutes;
              observer?.notifyDouble(route);
              break;
            case SubRootDuplicateStrategy.MakeVisibleOrPop:
              final newRoutes = pages.subTreeMovedDown(route, pop: true);
              _pages = newRoutes;
              observer?.notifyDouble(route);
              break;
            case SubRootDuplicateStrategy.Append:
              _actualPushRoute(route);
              break;
            case SubRootDuplicateStrategy.None:
              break;
          }
        } else {
          switch (strategy) {
            case SubRootDuplicateStrategy.Ignore:
              _log("[$strategy] Ignore pushing duplicate of $route.");
              break;
            case SubRootDuplicateStrategy.MakeVisible:
              final newRoutes = pages.subTreeMovedDown(route);
              _pages = newRoutes;
              observer?.notifyDouble(route);
              break;
            case SubRootDuplicateStrategy.MakeVisibleOrReset:
              final newRoutes = pages.subTreeMovedDown(route);
              _pages = newRoutes;
              observer?.notifyDouble(route);
              break;
            case SubRootDuplicateStrategy.MakeVisibleOrPop:
              final newRoutes = pages.subTreeMovedDown(route);
              _pages = newRoutes;
              observer?.notifyDouble(route);
              break;
            case SubRootDuplicateStrategy.Append:
              _actualPushRoute(route);
              break;
            case SubRootDuplicateStrategy.None:
              break;
          }
        }
      }
    }

    // If new route is not sub root then just push it.
    else {
      if (_pages.isNotEmpty && _currentPage.route == route) {
        final strategy = route.duplicateStrategy;
        switch (strategy) {
          case DuplicateStrategy.Ignore:
            _log("Ignore pushing duplicate of $route");
            break;
          case DuplicateStrategy.Replace:
            remove(route);
            _actualPushRoute(route);
            break;
          case DuplicateStrategy.Append:
            _actualPushRoute(route);
            break;
          case DuplicateStrategy.None:
            break;
        }
      } else {
        _actualPushRoute(route);
      }
    }
  }

  void _actualPushRoute(AppRoute route) {
    final page = AppPage(
      key: ObjectKey(route),
      route: route,
      name: route.actualUri.toString(),
      child: _getPageBuilder(route).call(route.data),
      restorationId: route.actualUri.toString(),
      transitionProvider: route.transition ?? _transitionProvider,
      transitionDuration: route.duration ?? _transitionDuration,
      reverseTransitionDuration:
          route.reverseDuration ?? _reverseTransitionDuration,
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
  Widget Function(Map<String, dynamic>? data) _getPageBuilder(AppRoute route) {
    if (_routeBuildInterceptor != null) {
      return (Map<String, dynamic>? data) =>
          _routeBuildInterceptor!(this, route, route.builder.call(data));
    } else {
      return route.builder;
    }
  }
}
