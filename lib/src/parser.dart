import 'dart:developer' as dev;

import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

class AppRouteInformationParser extends RouteInformationParser<AppRoute> {
  final bool debugging;
  final List<AppRoute> routes;
  final AppRoute? initialRoute;
  final AppRoute unknownRoute;
  final Uri Function(Uri initialUri)? transformUri;
  final Function(Uri uri, AppRoute selectedRoute)? onExternalRoute;

  AppRouteInformationParser({
    required this.routes,
    required this.unknownRoute,
    this.debugging = false,
    this.initialRoute,
    this.transformUri,
    this.onExternalRoute,
  });

  void log(Object message) => debugging
      ? dev.log(message.toString(), name: runtimeType.toString())
      : null;

  @override
  Future<AppRoute> parseRouteInformation(
      RouteInformation routeInformation) async {
    final _initialUri = Uri.parse(routeInformation.location ?? '');
    final _uri = transformUri?.call(_initialUri) ?? _initialUri;

    if (routeInformation.location == "/") {
      return initialRoute ??
          routes.singleWhere((e) => e.template == "/", orElse: () {
            log("No initial route provided.");
            return unknownRoute;
          });
    } else {
      final routesWithoutInitial =
          routes.where((e) => e.template != "/" && e != initialRoute).toList();
      final matchedRoutes = routesWithoutInitial
          .where((e) => UriParser(e.uriTemplate).matches(_uri))
          .toList();
      if (matchedRoutes.isEmpty) {
        log("No match for system route: '$_uri'");
        return unknownRoute;
      } else {
        if (matchedRoutes.length > 1) {
          log("Few routes(${matchedRoutes.length}) "
              "has matched to '$_uri'. Last will be used.");
        }
        final route = matchedRoutes.last;
        return route.fill(data: UriParser(route.uriTemplate).parse(_uri));
      }
    }
  }
}
