import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class DioLogger extends Interceptor {
  final logger = Logger(
      level: Level.info,
      filter: DebugFilter(),
      printer: PrettyPrinter(
          printTime: false,
          printEmojis: false,
          colors: false,
          methodCount: 100,
          errorMethodCount: 100));
  static const String _http = "HTTP";

  /// InitialTab count to logPrint json response
  static const int initialTab = 1;

  /// 1 tab length
  static const String tabStep = '    ';

  /// Width size per logPrint
  final int maxWidth;

  /// Print error message
  final bool error;

  /// Print compact json response
  final bool compact;

  String _HTTP = "HTTP";

  DioLogger({this.error = true, this.maxWidth = 90, this.compact = true});

  @override
  Future onRequest(RequestOptions options) async {
    final uri = options?.uri;
    final method = options?.method;
    logger.e(
        '$_http ===========================START REQUEST===========================');
    logger.e('$_http ║ Method: $method ');
    logger.e('$_http ║ URL: ${uri.toString()}');

    //Query params
    options.queryParameters.forEach(
        (key, value) => {logger.e('$_http ║ $key: ${value.toString()}')});

    //Header default
    final requestHeaders = Map();
    if (options.headers != null) {
      requestHeaders.addAll(options.headers);
    }
    requestHeaders['contentType'] = options.contentType?.toString();
    requestHeaders['responseType'] = options.responseType?.toString();
    requestHeaders['followRedirects'] = options.followRedirects;
    requestHeaders['connectTimeout'] = options.connectTimeout;
    requestHeaders['receiveTimeout'] = options.receiveTimeout;
    requestHeaders.forEach(
        (key, value) => {logger.e('$_http ║ $key: ${value.toString()}')});

    //Header custom
    options.headers.forEach(
        (key, value) => {logger.e('$_http ║ $key: ${value.toString()}')});

    //Extras custom
    options.extra.forEach(
        (key, value) => {logger.e('$_http ║ $key: ${value.toString()}')});
    logger.e(
        '$_http ===========================END REQUEST===========================');
    return options;
  }

  @override
  Future onError(DioError err) async {
    logger.e(
        '$_http ===========================START ERROR===========================');
    if (error) {
      if (err.type == DioErrorType.RESPONSE) {
        final uri = err.response.request.uri;
        _printBoxed(
            header:
                '$_HTTP DioError ║ Status: ${err.response.statusCode} ${err.response.statusMessage}',
            text: uri.toString());
        if (err.response != null && err.response.data != null) {
          logger.e('$_http ║${err.type.toString()}');
          _printResponse(err.response);
        }
      } else {
        _printBoxed(header: 'DioError ║ ${err.type}', text: err.message);
      }
    }
    logger.e(
        '$_http ===========================END ERROR===========================');
    return err;
  }

  void _printBoxed({String header, String text}) {
    logger.e('$_http ║$header');
    logger.e('$_http ║$text');
  }

  void _printResponse(Response response) {
    if (response.data != null) {
      if (response.data is Map)
        _printPrettyMap(response.data);
      else if (response.data is List) {
        logger.e('$_http ║${_indent()}[');
        _printList(response.data);
        logger.e('$_http ║${_indent()}[');
      } else
        _printBlock(response.data.toString());
    }
  }

  @override
  Future onResponse(Response response) async {
    logger.e(
        '$_http ===========================START RESPONSE===========================');
    _printResponse(response);
    logger.e(
        '$_http ===========================JSON STRING===========================');
    logger.e('$_http ║ ${response.toString()}');
    logger.e(
        '$_http ===========================END RESPONSE===========================');
    return response;
  }

  void _printBlock(String msg) {
    int lines = (msg.length / maxWidth).ceil();
    for (int i = 0; i < lines; ++i) {
      logger.e((i >= 0 ? '$_HTTP ║ ' : '') +
          msg.substring(i * maxWidth,
              math.min<int>(i * maxWidth + maxWidth, msg.length)));
    }
  }

  void _printPrettyMap(Map data,
      {int tabs = initialTab, bool isListItem = false, bool isLast = false}) {
    final bool isRoot = tabs == initialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) logger.e('$_http ║$initialIndent{');

    data.keys.toList().asMap().forEach((index, key) {
      final isLast = index == data.length - 1;
      var value = data[key];
      if (value is String)
        value = '\"${value.toString().replaceAll(RegExp(r'(\r|\n)+'), " ")}\"';
      if (value is Map) {
        if (_canFlattenMap(value))
          logger
              .e('$_http ║${_indent(tabs)} $key: $value${!isLast ? ',' : ''}');
        else {
          logger.e('$_http ║${_indent(tabs)} $key: {');
          _printPrettyMap(value, tabs: tabs);
        }
      } else if (value is List) {
        if (_canFlattenList(value))
          logger.e('$_http ║${_indent(tabs)} $key: ${value.toString()}');
        else {
          logger.e('$_http ║${_indent(tabs)} $key: [');
          _printList(value, tabs: tabs);
          logger.e('$_http ║${_indent(tabs)} ]${isLast ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          int lines = (msg.length / linWidth).ceil();
          for (int i = 0; i < lines; ++i) {
            logger.e(
                '$_http ║${_indent(tabs)} ${msg.substring(i * linWidth, math.min<int>(i * linWidth + linWidth, msg.length))}');
          }
        } else {
          logger.e('$_http ║${_indent(tabs)} $key: $msg${!isLast ? ',' : ''}');
        }
      }
    });
    logger.e('$_http ║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _printList(List list, {int tabs = initialTab}) {
    list.asMap().forEach((i, e) {
      final isLast = i == list.length - 1;
      if (e is Map) {
        if (compact && _canFlattenMap(e)) {
          logger.e('$_http ║${_indent(tabs)}  $e${!isLast ? ',' : ''}');
        } else {
          _printPrettyMap(e, tabs: tabs + 1, isListItem: true, isLast: isLast);
        }
      } else {
        logger.e('$_http ║${_indent(tabs + 2)} $e${isLast ? '' : ','}');
      }
    });
  }

  bool _canFlattenMap(Map map) {
    return map.values.where((val) => val is Map || val is List).isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List list) {
    return (list.length < 10 && list.toString().length < maxWidth);
  }

  String _indent([int tabCount = initialTab]) => tabStep * tabCount;
}
