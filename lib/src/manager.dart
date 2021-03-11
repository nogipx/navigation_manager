import 'dart:developer' as dev;

import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

class RouteManager with ChangeNotifier {
  final AppRoute initialRoute;
  final AppRoute Function(AppRoute route) onUnknownRoute;
  final Map<AppRoute, Widget Function(Map<String, dynamic> data)> mapRoute;
  final Widget Function(RouteManager manager, AppRoute route, Widget page) pageWrapper;

  final Function(RouteManager, AppRoute) onPushRoute;
  final Function(RouteManager, AppRoute) onRemoveRoute;
  final bool Function(RouteManager, AppRoute) onDoublePushRoute;

  List<Page> _pages;
  List<Page> get pages => List.unmodifiable(_pages);

  RouteManager({
    @required this.initialRoute,
    @required this.mapRoute,
    @required this.onUnknownRoute,
    this.pageWrapper,
    this.onPushRoute,
    this.onRemoveRoute,
    this.onDoublePushRoute,
  }) : assert(mapRoute != null && onUnknownRoute != null && initialRoute != null) {
    _pages = [
      MaterialPage<dynamic>(
        key: ValueKey(initialRoute.actualUri),
        child: getPageBuilder(initialRoute).call(<String, dynamic>{}),
        name: initialRoute.fill().actualUri.toString(),
      )
    ];
  }

  AppRoute get currentRoute {
    final currentPath = Uri.parse(pages.last.name);
    final route = mapRoute.keys.firstWhere((route) {
      return UriParser(route.uriTemplate).matches(currentPath) ?? false;
    });
    return route.fill();
  }

  void removeRoute(Page page, dynamic result) {
    _pages.remove(page);
    try {
      onRemoveRoute?.call(this, currentRoute);
    } catch (e) {
      _pages.add(page);
      throw Exception("Remove route aborted. \n$e");
    }
    notifyListeners();
  }

  void pushRoute(AppRoute route, {Map<String, dynamic> data}) {
    final _filledRoute = route.fill(data: data);
    final _actualUri = _filledRoute.actualUri.toString();

    if (_filledRoute == currentRoute) {
      final _allow = onDoublePushRoute?.call(this, _filledRoute) ?? false;
      if (!_allow) {
        return;
      }
    }

    final page = MaterialPage<dynamic>(
      key: ValueKey(_actualUri),
      child: getPageBuilder(_filledRoute).call(data),
      name: _actualUri,
    );
    _pages.add(page);

    try {
      onPushRoute?.call(this, _filledRoute);
    } catch (e) {
      _pages.remove(page);
      throw Exception("Push route aborted. \n$e");
    }

    notifyListeners();
  }

  /// Returns page builder function defined in mapping.
  /// If route is unknown, then ask for redirection route.
  Widget Function(Map<String, dynamic> data) getPageBuilder(AppRoute route) {
    Widget Function(Map<String, dynamic> data) _pageBuilder = mapRoute[route];

    if (_pageBuilder == null) {
      dev.log("No page builder for $route", name: runtimeType.toString());

      final _unknownRoute = onUnknownRoute(route).fill(data: route.data);
      _pageBuilder = mapRoute[_unknownRoute];

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
