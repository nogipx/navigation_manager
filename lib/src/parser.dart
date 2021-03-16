import 'dart:developer' as dev;

import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

class AppRouteInformationParser extends RouteInformationParser<AppRoute> {
  final List<AppRoute> routes;
  final AppRoute unknownRoute;
  final Uri Function(Uri initialUri) transformUri;
  final Function(Uri uri, AppRoute selectedRoute) onExternalRoute;

  AppRouteInformationParser({
    @required this.routes,
    @required this.unknownRoute,
    this.transformUri,
    this.onExternalRoute,
  });

  @override
  Future<AppRoute> parseRouteInformation(RouteInformation routeInformation) async {
    final _initial = Uri.parse(routeInformation.location);
    final _uri = transformUri?.call(_initial) ?? _initial;
    final route = routes.firstWhere(
      (route) => UriParser(route.uriTemplate).matches(_uri),
      orElse: () {
        dev.log(
          "No route for path from system: '$_uri'",
          name: runtimeType.toString(),
        );
        return unknownRoute;
      },
    );
    final _route = route.fill(rawData: UriParser(route.uriTemplate).parse(_uri));
    onExternalRoute?.call(_uri, _route);
    return _route;
  }
}
