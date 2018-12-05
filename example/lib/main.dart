import 'package:flutter/material.dart';
  
import 'package:aliossflutter/aliossflutter.dart' as alioss;
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  double _progress=0;
  @override
  void initState() {
    super.initState();
    //初始化
    alioss.responseFromProgress.listen((data){
//      print("_progress:"+data.currentSize.toString());
      setState(() {
       _progress=data.getProgress();
      });
    });
  }
  void _init() async{
    alioss.init("sts url", "http://oss-cn-hangzhou.aliyuncs.com");
  }
void _uploadPic() async{
    var file = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    alioss.upload("jiyi1", file.path, "aaaaa."+file.path.split('.').last).then((data){
//  Map返回值    {result: success, requestid: 5C07D06796CC8636720111EE, tag: ACB1D6EA048F7039974D5B82DE9FDB66}
      print("update:"+data.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
