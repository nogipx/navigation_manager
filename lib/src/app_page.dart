import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:navigation_manager/navigation_manager.dart';

class AppPage extends Page<AppPage> {
  final AppRoute route;
  final Widget child;

  final Duration? transitionDuration;
  final Duration? reverseTransitionDuration;

  final TransitionProvider? transitionProvider;
  final AppRouteType? customDefaultRouteType;

  const AppPage({
    LocalKey? key,
    required String name,
    required this.child,
    required this.route,
    String? restorationId,
    Object? arguments,
    this.transitionProvider,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.customDefaultRouteType,
  }) : super(
          key: key,
          name: name,
          restorationId: restorationId,
          arguments: arguments,
        );

  @override
  Route<AppPage> createRoute(BuildContext context) {
    if (transitionProvider != null) {
      if (transitionDuration != null) {
        return PageRouteBuilder(
          settings: this,
          transitionDuration: transitionDuration!,
          reverseTransitionDuration:
              reverseTransitionDuration ?? transitionDuration!,
          pageBuilder: (context, _, __) => child,
          transitionsBuilder: (context, animation, animation2, page) {
            return transitionProvider?.call(
                    context, animation, animation2, page) ??
                SizedBox();
          },
        );
      } else {
        return PageRouteBuilder(
          settings: this,
          pageBuilder: (context, _, __) => child,
          transitionsBuilder: (context, animation, animation2, page) {
            return transitionProvider?.call(
                    context, animation, animation2, page) ??
                SizedBox();
          },
        );
      }
    } else {
      if (route.type != null) {
        return _selectPageRoute(route.type!);
      } else if (customDefaultRouteType != null) {
        return _selectPageRoute(customDefaultRouteType!);
      } else {
        return _selectPageRoute(_defaultRouteType);
      }
    }
  }

  AppRouteType get _defaultRouteType {
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      return AppRouteType.Cupertino;
    }
    return AppRouteType.Material;
  }

  PageRoute<T> _selectPageRoute<T>(AppRouteType type) {
    if (type == AppRouteType.Cupertino) {
      return CupertinoPageRoute(
        settings: this,
        builder: (context) => child,
      );
    }
    return MaterialPageRoute(
      settings: this,
      builder: (context) => child,
    );
  }
}
