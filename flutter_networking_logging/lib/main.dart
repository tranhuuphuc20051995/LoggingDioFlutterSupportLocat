import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'dio_log.dart';

void main() async {
  Dio dio = Dio();
  dio.interceptors.add(DioLogger());

  try {
    final headers = Map<String, String>();
    final accept = {'accept': 'value accept'};
    headers.addAll(accept);
    final userAgent = {'user-agent': 'value user-agent'};
    headers.addAll(userAgent);
    Map<String, dynamic> queryParameters = Map<String, dynamic>();
    queryParameters = {'query 1': 'value query'};
    queryParameters = {'query 2': 'value query 2'};

    await dio.get('https://postman-echo.com/get?foo1=bar1&foo2=bar2',
        queryParameters: queryParameters, options: Options(headers: headers));
  } catch (e) {
    print(e);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Container(
          child: Center(
            child: Text('Dio Demo'),
          ),
        ),
      ),
    );
  }
}
