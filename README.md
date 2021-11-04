# Navigation plugin

## Features

- ✅ Navigator 2.0 support
- ✅ Duplicate strategies and [**tree concept**](doc/subtrees.md)
- ✅ Uri templates parsing. Check [**uri package**](https://pub.dev/packages/uri) and [RFC 6570](https://datatracker.ietf.org/doc/html/rfc6570)
- ✅ Global / per route transitions + automatic Cupertino transition
- 🛠️ Nested sub-trees

## Good to read

- You could read [**sub-tree concept**](doc/subtrees.md) doc for better understand duplicate strategies.

## Minimal Installation

Define routes

#### routes.dart
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

  static final deeplinkRoutes = [
    main,
  ];
}
```


Setup navigator

#### main.dart
```dart
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
        routes: Routes.deeplinkRoutes, // required
      ),
    );
  }
}
```

And use them

```dart
routeManager.push(AppRoute, {Map<String, dynamic> data});
routeManager.pop();

/// Removes the specified route from the routes list.
/// If the specified route is sub-root then entire sub-tree will be deleted.
routeManager.remove(AppRoute);

/// Removes all routes from the routes list after the specified.
routeManager.removeUntil(AppRoute);

routeManager.replaceLast(AppRoute replaceWith);

/// newRoutes must not be empty.
routeManager.replaceAll(List<AppRoute> newRoutes);
```

## Parameters

#### RouteManager
```dart
void _() {
  RouteManager(
    /// Application first route.
    initialRoute: Routes.main, // required
    
    /// Should manager print logs in console.
    debugging: true, // default,

    /// Initial route dynamic arguments.
    initialRouteArgs: const <String, dynamic>{}, // default empty,
    
    /// You could wrap every route with this parameter.
    /// 
    /// typedef PageWrapper = Widget Function(RouteManager, AppRoute, Widget);
    routeBuildInterceptor: (manager, route, page) {},
    
    /// Also you can define default transition for all routes.
    /// 
    /// typedef TransitionProvider = 
    ///   Widget Function(BuildContext, Animation<double>, Animation<double>, Widget);
    defaultTransition: (context, anim1, anim2, child) {},
    
    /// Default forward and reverse transition duration.
    /// If not specified then system defaults used.
    transitionDuration: null,
    reverseTransitionDuration: null,

    /// Sets Cupertino page transition as default for all routes.
    ///
    /// On iOS and macOs [true] by default. Cupertino could be disabled
    /// for particular route by setting [AppRoute.isCupertino] to [false].
    ///
    /// On other platforms [false] by default. Cupertino could be enabled
    /// for particular route by setting [AppRoute.isCupertino] to [true].
    defaultCupertinoTransition: Platform.isIOS || Platform.isMacOs,
  );
}
```

#### AppRoute
[**sub-tree concept**](doc/subtrees.md)

```dart
void _() {
  AppRoute(
    /// Route path. Should match RFC 6570 (https://pub.dev/packages/uri#uritemplate)
    template: '/',
    
    /// Return your page widget here.
    builder: (Map<String, dynamic>? data) => YourPageWidget(),

    /// Here you can define duplicate behavior for route.
    /// More information at "sub-tree concept" above.
    duplicateStrategy: DuplicateStrategy.Ignore, // default

    /// Sets route transition to Cupertino.
    /// If specified then [AppRoute.transition] will be ignored.
    isCupertino: null, // bool value
    
    /// Custom transition.
    /// Makes sense only if [RouteManager.defaultCupertinoTransition] = false
    /// and [AppRoute.isCupertino] = false
    /// 
    /// typedef TransitionProvider = 
    ///   Widget Function(BuildContext, Animation<double>, Animation<double>, Widget);
    transition: (context, anim1, anim2, page) {},
      
    /// Custom forward transition duration.
    duration: Duration(), // null by default
    
    /// Custom reverse transition duration.
    reverseDuration: Duration(), // null by default
  );
}
```



