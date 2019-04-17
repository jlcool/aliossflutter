import 'package:flutter/material.dart';
import 'dart:io';
import 'package:aliossflutter/aliossflutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _msg = "消息";
  double _progress = 0;
  String _rs = "";
  AliOSSFlutter alioss = AliOSSFlutter();
  String _path = "";

  String stsserver = "";
  String endpoint = "";
  String cryptkey = "";
  String bucket = "";
  String key = "bbb.jpg";
  String callbackUrl = "";
  String callbackHost = "";

  ///支持 application/x-www-form-urlencoded 和application/json
  String callbackBodyType = "application/json";
  String callbackBody =
      "{\"j_bucket\":\${bucket},\"j_object\":\${object},\"j_etag\":\${etag},\"j_size\":\${size},\"j_mimeType\":\${mimeType},\"j_height\":\${imageInfo.height},\"j_width\":\${imageInfo.width},\"j_format\":\${imageInfo.format},\"j_memberId\":\${x:var1}}";
  String callbackVars = "{\"x:var1\":\"123\"}";

  @override
  void initState() {
    super.initState();

    alioss.responseFromProgress.listen((data) {
      print("_progress:" + data.getProgress().toString());
      setState(() {
        _progress = data.getProgress();
      });
    });
    alioss.responseFromInit.listen((data) {
      if (data) {
        setState(() {
          _msg = "初始化成功";
        });
      } else {
        setState(() {
          _msg = "初始化失败";
        });
      }
    });
    alioss.responseFromSign.listen((data) {
      if (data.success) {
        setState(() {
          _msg = "url 签名 ：" + data.url;
        });
      } else {
        setState(() {
          _msg = "url 签名失败";
        });
      }
    });
    alioss.responseFromUpload.listen((data) {
      if (data.success) {
        setState(() {
          _msg = "上传成功 key:" + data.key + " 服务器返回值：" + data.servercallback;
        });
      } else {
        setState(() {
          _msg = "上传失败" + data.msg;
        });
      }
    });
    alioss.responseFromDownload.listen((data) {
      if (data.success) {
        setState(() {
          _path = data.path;
          _msg = "下载成功：" + _path;
        });
      } else {
        setState(() {
          _msg = "下载失败";
        });
      }
    });
    alioss.responseFromDelete.listen((data) {
      if (data.success) {
        setState(() {
          _msg = data.key + "删除成功";
        });
      } else {
        setState(() {
          _msg = data.key + "删除失败";
        });
      }
    });
  }

  void _init() async {
    //初始化
    alioss.init(stsserver, endpoint,
        cryptkey: cryptkey,
        crypttype: "aes"); //,cryptkey: cryptkey,crypttype: "aes"
  }

  void _uploadPic() async {
    String filePath = "";
    alioss.upload(bucket, filePath, key,
        callbackBody: callbackBody,
        callbackBodyType: callbackBodyType,
        callbackHost: callbackHost,
        callbackUrl: callbackUrl,
        callbackVars: callbackVars);
  }

  void _sign() async {
    alioss.signUrl(bucket, key, type: "1");
  }

  void _des() async {
    alioss.des(cryptkey, "encrypt", "123").then((data) {
      setState(() {
        _rs = data;
        _msg = "123加密后：" + data;
      });
    });
  }

  void _des1() async {
    alioss.des(cryptkey, "decrypt", _rs).then((data) {
      setState(() {
        _msg = _rs + "解密后：" + data;
      });
    });
  }

  void _delete() async {
    alioss.delete(bucket, key);
  }

  void _download() async {
    String downloadPath = "";
    alioss.download(bucket, key, downloadPath + "/" + key);
  }

  void _exist() async {
    alioss.exist(bucket, key).then((exist) {
      if (exist) {
        _msg = "已存在";
      } else if (!exist) {
        _msg = "不存在";
      }
      setState(() {});
    }).catchError((err) {
      _msg = "错误：$err";
      setState(() {});
    });

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('AliOss Flutter Plugin'),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(_msg),
                  LinearProgressIndicator(
                    value: _progress,
                  ),
                  MaterialButton(
                    onPressed: _init,
                    child: Text("初始化"),
                  ),
                  MaterialButton(
                    onPressed: _uploadPic,
                    child: Text("选择图片"),
                  ),
                  MaterialButton(
                    onPressed: _exist,
                    child: Text("是否存在"),
                  ),
                  MaterialButton(
                    onPressed: _sign,
                    child: Text("Url签名"),
                  ),
                  MaterialButton(
                    onPressed: _download,
                    child: Text("下载图片"),
                  ),
                  MaterialButton(
                    onPressed: _des,
                    child: Text("3des加密"),
                  ),
                  MaterialButton(
                    onPressed: _des1,
                    child: Text("3des解密"),
                  ),
                  MaterialButton(
                    onPressed: _delete,
                    child: Text("删除图片"),
                  )
                ],
              ),
            ),
          )),
    );
  }
}
