# aliossflutter

example里的配置文件自行添加配置
```dart
class Config{
///https://help.aliyun.com/document_detail/102082.html?spm=a2c4g.11186623.6.626.15695d26D8hGYE
 static final  String stsserver="";
 ///https://help.aliyun.com/document_detail/31837.html?spm=a2c4g.11186623.6.573.2b6144fdkv167F
 static final String endpoint="";
 ///这是对sts认证的token加密用的key
 ///如果不加密这里不需要
 static final String cryptkey="";
 static final String bucket="";
 static final String key="";
///上传回调配置
///参考 https://help.aliyun.com/document_detail/93985.html?spm=a2c4g.11186623.6.954.390a7c57VfH42B
static final String callbackUrl="";
 static final String callbackHost="";
 ///支持 application/x-www-form-urlencoded 和application/json
 static final String callbackBodyType="application/json";
 static final String callbackBody="{\"j_bucket\":\${bucket},\"j_object\":\${object},\"j_etag\":\${etag},\"j_size\":\${size},\"j_mimeType\":\${mimeType},\"j_height\":\${imageInfo.height},\"j_width\":\${imageInfo.width},\"j_format\":\${imageInfo.format},\"j_memberId\":\${x:var1}}";
 static final String callbackVars="{\"x:var1\":\"123\"}";
}
 ```

阿里云oss
初始化一次就可以了，可以在main.dart里初始化，插件会自动管理sts token过期    
后台返回sts格式：
```
{
 "StatusCode": 200,
 "AccessKeyId":"STS.iA645eTOXEqP3cg3VeHf",
 "AccessKeySecret":"rV3VQrpFQ4BsyHSAvi5NVLpPIVffDJv4LojUBZCf",
 "Expiration":"2015-11-03T09:52:59Z",
 "SecurityToken":"CAES7QIIARKAAZPlqaN9ILiQZPS+JDkS/GSZN45RLx4YS/p3OgaUC+oJl3XSlbJ7StKpQ...."
}
```
加密sts返回格式：
```
{
 "Data": "3des加密后的 sts"
}
```
初始化
```dart
import 'package:aliossflutter/aliossflutter.dart';
AliOSSFlutter  alioss=AliOSSFlutter();
alioss.init("sts url", "http://oss-cn-hangzhou.aliyuncs.com");
//可选一种 sts token 3DES加密方式
//alioss.init("sts url", "http://oss-cn-hangzhou.aliyuncs.com",cryptkey:"key");
//监听初始化
alioss.responseFromInit.listen((data){
      if(data) { 
          _msg="初始化成功"; 
      }else{
        _msg="初始化失败";
      }
    });
 ```
上传
```dart
AliOSSFlutter  alioss=AliOSSFlutter();
alioss.upload("bucket", file.path, "key",callbackBody: Config.callbackBody,callbackBodyType: Config.callbackBodyType,callbackHost: Config.callbackHost,callbackUrl: Config.callbackUrl,callbackVars: Config.callbackVars);
//监听上传
alioss.responseFromUpload.listen((data) {
      if(data.success) {
        setState(() {
          _msg="上传成功 key:"+data.key+" 服务器回调返回值："+data.servercallback;
        });
      }else{
        _msg="上传失败";
      }
    });
 ```
下载
```dart
AliOSSFlutter  alioss=AliOSSFlutter();
alioss.download(bucket, key, path,{process = ""});
//监听下载回调
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
```
url签名：
```dart
//type=1 签名私有资源
//type=0 签名公开的访问URL
alioss.signUrl(bucket, key,{type = "0",interval = "1800",process = ""})

//监听url签名
alioss.responseFromSign.listen((data){
      if(data.success) {
        setState(() {
          _msg="url 签名 ："+data.url;
        });
      }else{
        _msg="url 签名失败";
      }
    });
```

 监听进度上传和下载共用
```dart
alioss.responseFromProgress.listen((data){
 setState(() {
  _progress=data.getProgress();
 });
});
  ```

写了个插件开发过程，可以参考下
[插件开发方法](https://github.com/jlcool/aliossflutter/wiki/%E6%8F%92%E4%BB%B6%E5%BC%80%E5%8F%91%E6%B5%81%E7%A8%8B).

