import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:navigation_manager/navigation_manager.dart';

class AppPage extends Page<AppPage> {
  final AppRoute route;
  final Widget child;

  final Duration? defaultDuration;
  final Duration? defaultReverseDuration;

  final TransitionProvider? defaultTransition;
  final bool isCupertinoByDefault;

  const AppPage({
    LocalKey? key,
    required String name,
    required this.child,
    required this.route,
    String? restorationId,
    Object? arguments,
    this.defaultTransition,
    this.defaultDuration,
    this.defaultReverseDuration,
    this.isCupertinoByDefault = false,
  }) : super(
          key: key,
          name: name,
          restorationId: restorationId,
          arguments: arguments,
        );

  @override
  Route<AppPage> createRoute(BuildContext context) {
    if (route.isCupertino != null) {
      return _selectPageRoute(route.isCupertino!);
    } else if (isCupertinoByDefault) {
      return _selectPageRoute(true);
    } else if ((route.transition ?? defaultTransition) != null) {
      return _getCustomRouteBuilder();
    } else {
      return _selectPageRoute(false);
    }
  }

  PageRouteBuilder<AppPage> _getCustomRouteBuilder() {
    final duration = route.duration ?? defaultDuration;
    final reverseDuration = route.reverseDuration ?? defaultReverseDuration;

    if (duration != null) {
      return PageRouteBuilder<AppPage>(
        settings: this,
        transitionDuration: duration,
        reverseTransitionDuration: reverseDuration ?? duration,
        pageBuilder: (context, _, __) => child,
        transitionsBuilder: (context, animation, animation2, page) {
          return (route.transition ?? defaultTransition)
                  ?.call(context, animation, animation2, page) ??
              SizedBox();
        },
      );
    } else {
      return PageRouteBuilder<AppPage>(
        settings: this,
        pageBuilder: (context, _, __) => child,
        transitionsBuilder: (context, animation, animation2, page) {
          return (route.transition ?? defaultTransition)
                  ?.call(context, animation, animation2, page) ??
              SizedBox();
        },
      );
    }
  }

  PageRoute<AppPage> _selectPageRoute(bool isCupertino) {
    if (isCupertino) {
      return AlwaysSwipeBackCupertinoPageRoute(
        settings: this,
        builder: (context) => child,
      );
    } else if ((route.transition ?? defaultTransition) != null) {
      return _getCustomRouteBuilder();
    } else {
      return MaterialPageRoute(
        settings: this,
        builder: (context) => child,
      );
    }
  }
}

class AlwaysSwipeBackCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  AlwaysSwipeBackCupertinoPageRoute({
    required WidgetBuilder builder,
    String? title,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          maintainState: maintainState,
          title: title,
          settings: settings,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  bool get hasScopedWillPopCallback => false;
}
