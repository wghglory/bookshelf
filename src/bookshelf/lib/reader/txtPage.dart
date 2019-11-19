import 'package:flutter/material.dart';
import 'package:bookshelf/tools.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';



class TxtPage extends StatefulWidget {
  @override
  _TxtPageState createState() => _TxtPageState();
}

class _TxtPageState extends State<TxtPage> {
  TxtPageArguments _arg;
  String _usertoken = '';
  String _bucketName = '';
  String _objectName = '';
  String _pathName = '';
  String _filePath = '';
  int pages = 0;
  bool _isReady = false;


  @override
  Widget build(BuildContext context) {
    this._arg = ModalRoute.of(context).settings.arguments;
    this._usertoken = this._arg.userToken;
    this._bucketName = this._arg.bucketName;
    this._objectName = this._arg.objectName;
    this._pathName = this._arg.pathName;
    this._filePath = this._pathName + '/' + this._objectName;

    final StreamController<String> _controller= StreamController<String>();
    double fontsize=12;

    File file=new File('$_filePath');
    String content='';
    Stream<List<int>> inputStream = file.openRead();
    inputStream
        .transform(utf8.decoder)       // Decode bytes to UTF-8.
        .listen((String line) {        // Process results.
      content=content+line;
      _controller.sink.add("1");
    },
        onDone: () { _isReady=true;//_controller.sink.add(content);//print(content);
        print(_isReady);
        //_controller.close();
        },
        onError: (e) { print(e.toString()); });

    //return TXTViewerScaffold(
    return Scaffold(
      appBar: AppBar(
        title: Text("${this._objectName}"),
        actions: <Widget>[
         new IconButton(
            icon: new Icon(Icons.zoom_out),
            onPressed: () {fontsize-=0.5;
            _controller.add("1");},
          ),
          new IconButton(
            icon: new Icon(Icons.zoom_in),
            onPressed: () {fontsize+=0.5;
            _controller.add("1");},
          ),
        ],
      ),
      body: new ListView(
        children: <Widget>[
          Container(
              padding: const EdgeInsets.all(32.0),
              child:
                StreamBuilder(
                  stream: _controller.stream,
                  initialData: " ",
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot){
                    //return
                      //!_isReady? Center(child: CircularProgressIndicator(),):
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.active:
                      case ConnectionState.waiting:
                      print(fontsize);return
                        Text(
                          content,
                          textAlign: TextAlign.left,
                          //文本对齐方式  居中
                          textDirection: TextDirection.ltr,
                          //文本方向
                          softWrap: true,
                          //是否自动换行 false文字不考虑容器大小  单行显示   超出；屏幕部分将默认截断处理
                          overflow: TextOverflow.fade,
                          textScaleFactor: 2.0,
                          //字体显示的赔率

                          //maxLines: , //最大行数
                          style: new TextStyle(
                            decorationColor: const Color(0xffffffff),
                            //线的颜色
                            decoration: TextDecoration.none,
                            decorationStyle: TextDecorationStyle.solid,
                            //文字装饰的风格  dashed,dotted虚线(简短间隔大小区分)  double三条线  solid两条线
                            wordSpacing: 0.0,
                            //单词间隙(负值可以让单词更紧凑)
                            letterSpacing: 0.0,
                            //字母间隙(负值可以让字母更紧凑)
                            fontStyle: FontStyle.normal,
                            //文字样式，斜体和正常
                            fontSize: fontsize,
                            //字体大小
                            fontWeight: FontWeight.normal,
                            //字体粗细  粗体和正常
                            color: Colors.black, //文字颜色
                          ),
                        );
                      case ConnectionState.done:
                        if (snapshot.hasError)
                          return SnackBar(
                            content: Text(
                                'Exception happens and Get Buckets Failed!'),
                            duration: Duration(seconds: 1),
                          );
                        else {
                        }

                    }
                    return Center(child: CircularProgressIndicator(),);
                  },
                )
          ),
        ],
      ),
    );
  }
}
