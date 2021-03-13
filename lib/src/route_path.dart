import 'dart:math' show Random;

import 'package:equatable/equatable.dart';
import 'package:uri/uri.dart';

// ignore: must_be_immutable
class AppRoute extends Equatable {
  final String template;
  final Map<String, dynamic> data;

  UriTemplate _uriTemplate;
  UriTemplate get uriTemplate => _uriTemplate;
  final Uri actualUri;

  bool _isSubRoot;
  bool get isSubRoot => _isSubRoot;

  // ignore: unused_field
  int _uniqField;

  AppRoute(this.template, {this.actualUri, this.data}) {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = false;
  }

  AppRoute.subroot(this.template, {this.actualUri, this.data}) {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = true;
  }
  AppRoute.uniq(this.template, {this.actualUri, this.data}) {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = false;
    _uniqField = DateTime.now().millisecondsSinceEpoch;
  }

  AppRoute copyWith({Uri actualUri, Map<String, dynamic> data}) {
    if (isSubRoot) {
      return AppRoute.subroot(template,
          actualUri: actualUri ?? this.actualUri, data: data);
    } else {
      return AppRoute(template, actualUri: actualUri ?? this.actualUri, data: data);
    }
  }

  AppRoute fill({Map<String, dynamic> data}) {
    final _data = data ?? <String, dynamic>{};
    return copyWith(
      actualUri: UriParser(uriTemplate).expand(_data),
      data: _data,
    );
  }

  @override
  List<Object> get props => [template, _uniqField];

  @override
  String toString() => "${isSubRoot ? 'SubRoot ' : ''}AppRoute "
      "{ template: $template, actualUri: $actualUri, data: $data }";
}
