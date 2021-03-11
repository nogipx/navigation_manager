import 'dart:developer' as dev;

import 'package:navigation_manager/navigation_manager.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

class AppRouteInformationParser extends RouteInformationParser<AppRoute> {
  final List<AppRoute> routes;
  final AppRoute unknownRoute;

  AppRouteInformationParser({
    @required this.routes,
    @required this.unknownRoute,
  });

  @override
  Future<AppRoute> parseRouteInformation(RouteInformation routeInformation) async {
    final _uri = Uri.parse(routeInformation.location);
    final route = routes.firstWhere(
      (route) => UriParser(route.uriTemplate).matches(_uri),
      orElse: () {
        dev.log(
          "No route for path from system: '$_uri'",
          name: runtimeType.toString(),
        );
        return unknownRoute;
      },
    ).copyWith(actualUri: _uri);
    return route;
  }
}
