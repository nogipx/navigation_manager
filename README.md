# Navigation plugin

## Features

- [x] Navigator 2.0 support
- [x] Duplicate strategies and [**tree concept**](doc/subtrees.md)
- [x] Uri templates parsing. Check [**uri package**](https://pub.dev/packages/uri) and [RFC 6570](https://datatracker.ietf.org/doc/html/rfc6570)
- [ ] Global(ok) / per route transitions

## Good to read

- You could read [**sub-tree concept**](doc/subtrees.md) doc for better understand duplicate strategies.

## Minimal Installation

Define routes

```dart
import 'package:flutter/material.dart';
import 'package:navigation_manager/navigation_manager.dart';

abstract class Routes {
  static final main = AppRoute.subroot(
    '/',
    (Map<String, dynamic> data) => const YourPageWidget(),
    duplicateStrategy: SubRootDuplicateStrategy.MakeVisible, // optional, default value
  );

  static final unknown = AppRoute(
    '/404',
    (data) => YourUnkwownRoutePage(),
    duplicateStrategy: DuplicateStrategy.Ignore // optional, default value
  );

  static final appRoutes = [
    main,
  ];
}
```

Setup navigator

```dart
// main.dart

import 'package:flutter/material.dart';
import 'package:navigation_manager/navigation_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final RouteManager routeManager;

  @override
  void initState() {
    routeManager = RouteManager(
      initialRoute: Routes.main, // required
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: AppRouteDelegate(
        routeManager: routeManager, // required
      ),
      routeInformationParser: AppRouteInformationParser(
        unknownRoute: Routes.unknown, // required 
        routes: Routes.appRoutes, ?? // required
      ),
    );
  }
}
```

And use them

```dart
routeManager.push(AppRoute, {Map<String, dynamic> data})
routeManager.pop()

/// Removes the specified route from the routes list.
/// If the specified route is sub-root then entire sub-tree will be deleted.
routeManager.remove(AppRoute)

/// Removes all routes from the routes list after the specified.
routeManager.removeUntil(AppRoute)
```
