import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

abstract class AppRouteArgs {
  Map<String, dynamic> toJson();
}

enum DuplicateStrategy { Ignore, Replace, Append }

enum SubRootDuplicateStrategy { Ignore, MakeVisibleOrReset, MakeVisible, Append }

// ignore: must_be_immutable
class AppRoute<A extends AppRouteArgs> extends Equatable {
  final String template;
  final A data;
  final DuplicateStrategy duplicateStrategy;
  final SubRootDuplicateStrategy subRootDuplicateStrategy;
  final Widget Function(AppRouteArgs) builder;

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
    SubRootDuplicateStrategy duplicateStrategy = SubRootDuplicateStrategy.MakeVisible,
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

  AppRoute copyWith({Uri actualUri, A data}) {
    if (isSubRoot) {
      return AppRoute<A>.subroot(
        template,
        builder,
        actualUri: actualUri ?? this.actualUri,
        data: data,
        duplicateStrategy: subRootDuplicateStrategy,
      );
    } else {
      return AppRoute<A>(
        template,
        builder,
        actualUri: actualUri ?? this.actualUri,
        data: data,
        duplicateStrategy: duplicateStrategy,
      );
    }
  }

  AppRoute fill({A data, Map<String, dynamic> rawData}) {
    final _data = data?.toJson() ?? rawData ?? <String, dynamic>{};
    return copyWith(
      actualUri: UriParser(uriTemplate).expand(_data),
      data: data,
    );
  }

  @override
  List<Object> get props => [template, _uniqField];

  @override
  String toString() => "${isSubRoot ? 'SubRoot ' : ''}AppRoute"
      "(template: $template, actualUri: $actualUri, data: $data)";
}
