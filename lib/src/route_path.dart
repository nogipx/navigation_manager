import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

enum DuplicateStrategy {
  /// Ignore pushing route.
  Ignore,

  /// Replace current route with pushed.
  Replace,

  /// Just push route.
  Append,
}

enum SubRootDuplicateStrategy {
  /// Ignore pushing duplicate of sub-root route.
  Ignore,

  /// Pushing a subroot will make its tree visible if it is not already visible.
  /// Otherwise, if the tree of the route being pushed is currently visible,
  /// the children of its tree will be removed.
  MakeVisibleOrReset,

  /// Pushing a subroot will make its tree visible if it is not already visible.
  /// Otherwise, pushing will be ignored.
  MakeVisible,

  /// Just push route.
  Append
}

// ignore: must_be_immutable
class AppRoute extends Equatable {
  final DuplicateStrategy duplicateStrategy;
  final SubRootDuplicateStrategy subRootDuplicateStrategy;

  final String template;
  final Map<String, dynamic> data;
  final Widget Function(Map<String, dynamic> data) builder;

  UriTemplate _uriTemplate;
  UriTemplate get uriTemplate => _uriTemplate;
  final Uri actualUri;

  bool _isSubRoot;
  bool get isSubRoot => _isSubRoot;

  // ignore: unused_field
  int _uniqField;

  AppRoute(
    this.template,
    this.builder, {
    this.actualUri,
    this.data,
    this.duplicateStrategy = DuplicateStrategy.Ignore,
  }) : subRootDuplicateStrategy = null {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = false;
  }

  AppRoute.subroot(
    this.template,
    this.builder, {
    this.actualUri,
    this.data,
    SubRootDuplicateStrategy duplicateStrategy =
        SubRootDuplicateStrategy.MakeVisible,
  })  : duplicateStrategy = null,
        subRootDuplicateStrategy = duplicateStrategy {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = true;
  }
  AppRoute.uniq(
    this.template,
    this.builder, {
    this.actualUri,
    this.data,
    this.duplicateStrategy = DuplicateStrategy.Ignore,
  }) : subRootDuplicateStrategy = null {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = false;
    _uniqField = DateTime.now().millisecondsSinceEpoch;
  }

  AppRoute copyWith({Uri actualUri, Map<String, dynamic> data}) {
    if (isSubRoot) {
      return AppRoute.subroot(
        template,
        builder,
        actualUri: actualUri ?? this.actualUri,
        data: data,
        duplicateStrategy: subRootDuplicateStrategy,
      );
    } else {
      return AppRoute(
        template,
        builder,
        actualUri: actualUri ?? this.actualUri,
        data: data,
        duplicateStrategy: duplicateStrategy,
      );
    }
  }

  AppRoute fill({Map<String, dynamic> data}) {
    if (data != null && data.isNotEmpty) {
      return copyWith(
        actualUri: UriParser(uriTemplate).expand(data),
        data: (this.data ?? <String, dynamic>{})..addAll(data),
      );
    } else {
      return this;
    }
  }

  @override
  List<Object> get props => [template, _uniqField];

  @override
  String toString() => "${isSubRoot ? 'SubRoot ' : ''}AppRoute"
      "(template: $template, actualUri: $actualUri, data: $data)";
}
