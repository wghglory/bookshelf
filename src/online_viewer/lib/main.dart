import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

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
      home: PdfView(),
    );
  }
}

//pdf reader
class PdfView extends StatefulWidget {
  @override
  _PdfViewState createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  String assetpath="";
  String type="";
  String allText="";

  @override
  Widget build(BuildContext context) {

      //提供方法获取pdf文档内容
      Future getfileFromAssets() async {
        //获取file中的数据
        StreamController<Uint8List> controller = StreamController<Uint8List>();
        String token = "token=weijie@jiaotong:jiaotong";
        String method = "&response-content-disposition=inline";
        String filename = "Wiley.Algorithms.for.Image.Processing.and.Computer.Vision.2nd.Edition.pdf";
        String uri_filename = Uri.encodeComponent(filename);
        final url = "http://yhzzzz.natapp1.cc/api/v1/s3/weijie/" + uri_filename +
            "?" + token + method;
        var request = await HttpClient().getUrl(Uri.parse(url));
        var response = await request.close();
        var bytes = await consolidateHttpClientResponseBytes(response);
        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = new File('$dir/$filename');
        type = filename.substring(filename.lastIndexOf(".") + 1);
        assetpath = file.path;

        //pdf 写入
        if (type == "pdf") {
          StreamSubscription subscription = controller.stream.listen((value) {
            file.writeAsBytes(bytes);
          });
          controller.sink.add(bytes);
          controller.close();

          //return file;
        }

        //txt 写入
        else if(type=="txt"){
          print("1");
          await file.writeAsBytes(bytes);
          print("2");
          String contents=await file.readAsString();
          allText=contents;
        }
      }

    return Scaffold(
      appBar: AppBar(
        title: Text("pdf reader"),
      ),
      body: Column(
        children: <Widget>[
          RaisedButton(

            onPressed: () {
              getfileFromAssets();
              //print("BUG");
              if(assetpath=="" || allText==""){
                print("waiting");
              }
              else if(type=="pdf"){
                print("pdf!!!!!");
                Navigator.push(context,MaterialPageRoute(
                  builder: (context) => PdfPage(path: assetpath),
                ));
              }
              else if(type=="txt"){
                print("txt!!!!!!!");
                Navigator.push(context, MaterialPageRoute(
                      builder: (context) => TxtPage(content: allText),
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
class PdfPage extends StatefulWidget {
  String path="";

  PdfPage({Key key, this.path}) : super(key: key);

  @override
  _PdfPageState createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  bool pdfready = false;
  PDFViewController pdfviewController;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path),
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,
            autoSpacing: true,
            enableSwipe: true,
            swipeHorizontal: false,
            onRender: (_pages) {
              setState(() {
                pdfready = true;
              });
            },
            onViewCreated: (PDFViewController vc) {
              pdfready=false;
              pdfviewController = vc;
            },
          ),
          !pdfready? Center(
            child: CircularProgressIndicator(),
          )
              : Offstage()
        ],
      ),
    );
  }
}


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
      body: new ListView(
        children: <Widget>[
          new Text(
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
          ),

        ],

          ),
    );
  }
}