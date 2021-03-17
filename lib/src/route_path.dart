import 'package:equatable/equatable.dart';
import 'package:uri/uri.dart';

abstract class AppRouteArgs {
  Map<String, dynamic> toJson();
}

enum DuplicateStrategy { Ignore, Replace, Append }

enum SubRootDuplicateStrategy { Ignore, Reset, MakeVisibleAndReset, MakeVisible, Append }

// ignore: must_be_immutable
class AppRoute<Args extends AppRouteArgs> extends Equatable {
  final String template;
  final Args data;
  final DuplicateStrategy duplicateStrategy;
  final SubRootDuplicateStrategy subRootDuplicateStrategy;

  UriTemplate _uriTemplate;
  UriTemplate get uriTemplate => _uriTemplate;
  final Uri actualUri;

  bool _isSubRoot;
  bool get isSubRoot => _isSubRoot;

  // ignore: unused_field
  int _uniqField;

  AppRoute(
    this.template, {
    this.actualUri,
    this.data,
    this.duplicateStrategy = DuplicateStrategy.Ignore,
  }) : subRootDuplicateStrategy = null {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = false;
  }

  AppRoute.subroot(
    this.template, {
    this.actualUri,
    this.data,
    SubRootDuplicateStrategy duplicateStrategy = SubRootDuplicateStrategy.MakeVisible,
  })  : duplicateStrategy = null,
        subRootDuplicateStrategy = duplicateStrategy {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = true;
  }
  AppRoute.uniq(
    this.template, {
    this.actualUri,
    this.data,
    this.duplicateStrategy = DuplicateStrategy.Ignore,
  }) : subRootDuplicateStrategy = null {
    _uriTemplate = UriTemplate(template);
    _isSubRoot = false;
    _uniqField = DateTime.now().millisecondsSinceEpoch;
  }

  AppRoute copyWith({Uri actualUri, Args data}) {
    if (isSubRoot) {
      return AppRoute<Args>.subroot(
        template,
        actualUri: actualUri ?? this.actualUri,
        data: data,
      );
    } else {
      return AppRoute<Args>(
        template,
        actualUri: actualUri ?? this.actualUri,
        data: data,
      );
    }
  }

  AppRoute fill({Args data, Map<String, dynamic> rawData}) {
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
