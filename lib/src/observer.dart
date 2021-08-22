import 'package:meta/meta.dart';
import 'package:navigation_manager/navigation_manager.dart';

enum RouteActionType { PUSH, REMOVE, DOUBLE }

typedef RouteObserverCallback = void Function(AppRoute, RouteActionType);

class AppRouteObserver {
  final RouteObserverCallback onRouteChange;

  const AppRouteObserver(this.onRouteChange);

  @internal
  void notifyRemove(AppRoute route) =>
      _safeRun(() => onRouteChange(route, RouteActionType.REMOVE));

  @internal
  void notifyPush(AppRoute route) =>
      _safeRun(() => onRouteChange(route, RouteActionType.PUSH));

  @internal
  void notifyDouble(AppRoute route) =>
      _safeRun(() => onRouteChange(route, RouteActionType.DOUBLE));

  void _safeRun(Function f) {
    try {
      f();
    } catch (e, stackTrace) {
      print("Error happened in $runtimeType. \n$e");
      print(stackTrace);
    }
  }
}
