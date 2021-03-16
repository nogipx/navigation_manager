import 'package:equatable/equatable.dart';
import 'package:uri/uri.dart';

abstract class AppRouteArgs {
  Map<String, dynamic> toJson();
  AppRouteArgs fromJson(Map<String, dynamic> json);
}

// ignore: must_be_immutable
class AppRoute<Args extends AppRouteArgs> extends Equatable {
  final String template;
  final Args data;

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

  AppRoute fill({Args data}) {
    return copyWith(
      actualUri: UriParser(uriTemplate).expand(data?.toJson() ?? {}),
      data: data,
    );
  }

  @override
  List<Object> get props => [template, _uniqField];

  @override
  String toString() => "${isSubRoot ? 'SubRoot ' : ''}AppRoute "
      "{ template: $template, actualUri: $actualUri, data: $data }";
}
