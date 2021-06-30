import 'package:navigation_manager/navigation_manager.dart';

enum RouteActionType { PUSH, REMOVE, DOUBLE }

typedef RouteObserverCallback = Function(AppRoute, [RouteActionType]);

abstract class AppRouteObserver {
  RouteObserverCallback get onRouteChange;

  void notifyRemove(AppRoute route) =>
      _safeRun(() => onRouteChange?.call(route, RouteActionType.REMOVE));

  void notifyPush(AppRoute route) =>
      _safeRun(() => onRouteChange?.call(route, RouteActionType.PUSH));

  void notifyDouble(AppRoute route) =>
      _safeRun(() => onRouteChange?.call(route, RouteActionType.DOUBLE));

  void _safeRun(Function f) {
    try {
      f();
    } catch (e, stackTrace) {
      print("Error happened in $runtimeType. \n$e");
      print(stackTrace);
    }
  }
}
