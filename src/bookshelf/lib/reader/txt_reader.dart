import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        accentColor: Colors.green,

      ),
      home: txtView(),
    );
  }
}

//pdf reader
class txtView extends StatefulWidget {
  @override
  _txtViewState createState() => _txtViewState();
}

class _txtViewState extends State<txtView> {
  String _assetpath="";
  String _type="";
  var _allText="";

  @override
  Widget build(BuildContext context) {

    //提供方法获取pdf文档内容
    Future getfileFromAssets() async {
      //获取file中的数据
      //StreamController<Uint8List> controller = StreamController<Uint8List>();
      String token = "token=yiwei@jiaotong:jiaotong";
      String method = "&response-content-disposition=inline";
      String filename = "2city10.txt";
      String uri_filename = Uri.encodeComponent(filename);
      final url = "http://yhzzzz.natapp1.cc/api/v1/s3/test2/" + uri_filename +
          "?" + token + method;
      var request = await HttpClient().getUrl(Uri.parse(url));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      String dir = (await getApplicationDocumentsDirectory()).path;
      File file = new File('$dir/$filename');
      await file.writeAsBytes(bytes);
      _type = filename.substring(filename.lastIndexOf(".") + 1);
      _assetpath = file.path;

      //txt 写入
      if(_type=="txt"){
        String contents=await file.readAsString();
        _allText=contents;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("txt reader"),
      ),
      body: Column(
        children: <Widget>[
          RaisedButton(

            onPressed: () {
              getfileFromAssets();
              if(this._assetpath=="" && this._allText==""){
                print("waiting");
              }
              else if(_type=="txt"){
                print("txt!!!!!!!");
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TxtPage(content:_allText),
                )
                );
              }
            },
            child: Text("file from assets"),
          ),
        ],
      ),
    );
  }
}

//Detailed setup of the page

class TxtPage extends StatefulWidget {
  String content="";

  TxtPage({Key key, this.content}) : super(key: key);

  @override
  _TxtPageState createState() => _TxtPageState();
}

class _TxtPageState extends State<TxtPage> {

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: AppBar(
        title: Text("Txt"),
      ),
      body:

        new ListView(
          children: <Widget>[
          new Container(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              widget.content,
              textAlign: TextAlign.left, //文本对齐方式  居中
              textDirection: TextDirection.ltr, //文本方向
              softWrap: true, //是否自动换行 false文字不考虑容器大小  单行显示   超出；屏幕部分将默认截断处理
              overflow: TextOverflow.fade,
              textScaleFactor: 2.0, //字体显示的赔率
              //maxLines: , //最大行数
              style: new TextStyle(
                decorationColor: const Color(0xffffffff), //线的颜色
                decoration: TextDecoration.none,
                decorationStyle: TextDecorationStyle.solid, //文字装饰的风格  dashed,dotted虚线(简短间隔大小区分)  double三条线  solid两条线
                wordSpacing: 0.0, //单词间隙(负值可以让单词更紧凑)
                letterSpacing: 0.0, //字母间隙(负值可以让字母更紧凑)
                fontStyle: FontStyle.normal, //文字样式，斜体和正常
                fontSize: 12.0, //字体大小
                fontWeight: FontWeight.normal, //字体粗细  粗体和正常
                color: Colors.black, //文字颜色
              ),
            )
    ),

        ],
      )




    );
  }
}