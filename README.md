# aliossflutter

阿里云oss
初始化
 ```dart
    import 'package:aliossflutter/aliossflutter.dart' as alioss;
    alioss.init("sts url", "http://oss-cn-hangzhou.aliyuncs.com");
    //可选一种 sts token 3DES加密方式 可以查看 AliDecoder
    //alioss.init("sts url", "http://oss-cn-hangzhou.aliyuncs.com",cryptkey:"key");
 ```
上传
 ```dart
    alioss.upload("bucket", file.path, "key").then((data){
    //  Map返回值    {result: success, requestid: XXX, tag: XXXX}
          print("update:"+data.toString());
        });
 ```
 进度
  ```dart
      alioss.responseFromProgress.listen((data){
           setState(() {
            _progress=data.getProgress();
           });
         });
  ```
## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).
