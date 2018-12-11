import 'package:aliossflutter_example/config.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:aliossflutter/aliossflutter.dart'   ;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _msg="消息";
  double _progress=0;
  AliOSSFlutter alioss=AliOSSFlutter();
  String _path="";
  @override
  void initState() {
    super.initState();

    alioss.responseFromProgress.listen((data){
      print("_progress:"+data.getProgress().toString());
      setState(() {
       _progress=data.getProgress();
      });
    });
    alioss.responseFromInit.listen((data){
      if(data) {
        setState(() {
          _msg="初始化成功";
        });
      }else{
        _msg="初始化失败";
      }
    });
    alioss.responseFromSign.listen((data){
      if(data.success) {
        setState(() {
          _msg="url 签名 ："+data.url;
        });
      }else{
        _msg="url 签名失败";
      }
    });
    alioss.responseFromUpload.listen((data) {
      if(data.success) {
        setState(() {
          _msg="上传成功 key:"+data.key;
        });
      }else{
        _msg="上传失败";
      }
    });
    alioss.responseFromDownload.listen((data) {
      if(data.success) {
        setState(() {
          _path=data.path;
          _msg="下载成功："+_path;
        });
      }else{
        _msg="下载失败";
      }
    });
  }
  void _init() async{
    //初始化
    alioss.init(Config.stsserver,Config.endpoint,cryptkey: Config.cryptkey);
  }
void _uploadPic() async{
    var file = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    alioss.upload(Config.bucket, file.path, Config.key);
  }
  void _sign() async{
    alioss.signUrl(Config.bucket,Config.key,type:"1");
  }
  void _download() async{
    Directory _cacheDir = await getTemporaryDirectory();
    alioss.download(Config.bucket, Config.key,_cacheDir.path+"/"+Config.key);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AliOss Flutter Plugin'),
        ),
        body: Center(
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
                onPressed: _sign,
                child: Text("Url签名"),
              ),
              MaterialButton(
                onPressed: _download,
                child: Text("下载图片"),
              )
            ],
          ),
        ),
      ),
    );
  }

}
