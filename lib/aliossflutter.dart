import 'dart:async';

import 'package:aliossflutter/response.dart';
import 'package:flutter/services.dart';

   final  MethodChannel _channel =
      const MethodChannel('aliossflutter')..setMethodCallHandler(_handler);

  StreamController<ProgressResponse> _responseUploadController =
  new StreamController.broadcast();
//回調參數
  Stream<ProgressResponse> get responseFromProgress =>
      _responseUploadController.stream;

  //监听回调方法
  Future<dynamic> _handler(MethodCall methodCall) {
    print("_handler:"+ methodCall.method);
    if ("onProgress" == methodCall.method) {//进度
//      double currentSize=methodCall.arguments["currentSize"];
//      double totalSize=methodCall.arguments["totalSize"];
      print("_handler 2 currentSize2:"+methodCall.arguments["currentSize"].toString());
      ProgressResponse res=new  ProgressResponse(currentSize:double.parse(methodCall.arguments["currentSize"].toString()),totalSize:double.parse( methodCall.arguments["totalSize"].toString()));
      print("_handler222222:"+res.totalSize.toString());
      _responseUploadController
          .add(res);
    }
    return Future.value(true);
  }
  //上传
    Future upload(String bucket, String file, String key) async {
    return await _channel.invokeMethod('upload',
        <String, String>{"bucket": bucket, "file": file, "key": key});

  }
  //初始化
    Future init(String stsserver, String endpoint,{String cryptkey=""}) async {
    return await _channel.invokeMethod('init',
        <String, String>{"stsserver": stsserver, "endpoint": endpoint, "cryptkey": cryptkey});

  }

