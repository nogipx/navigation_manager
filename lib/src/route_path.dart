import 'package:equatable/equatable.dart';
import 'package:uri/uri.dart';

// ignore: must_be_immutable
class AppRoute extends Equatable {
  final String template;

  UriTemplate _uriTemplate;
  UriTemplate get uriTemplate => _uriTemplate;

  final Map<String, dynamic> data;

  final Uri actualUri;

  AppRoute(this.template, {this.actualUri, this.data}) {
    _uriTemplate = UriTemplate(template);
  }

  AppRoute copyWith({Uri actualUri, Map<String, dynamic> data}) =>
      AppRoute(template, actualUri: actualUri ?? this.actualUri, data: data);

  AppRoute fill({Map<String, dynamic> data}) {
    final _data = data ?? <String, dynamic>{};
    return copyWith(
      actualUri: UriParser(uriTemplate).expand(_data),
      data: _data,
    );
  }

  @override
  List<Object> get props => [template];

  @override
  String toString() =>
      "AppRoute { template: $template, actualUri: $actualUri, data: $data }";
}
