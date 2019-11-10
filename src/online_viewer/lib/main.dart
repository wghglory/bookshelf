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
        String token = "token=yiwei@jiaotong:jiaotong";
        String method = "&response-content-disposition=inline";
        String filename = "test.txt";
        String uri_filename = Uri.encodeComponent(filename);
        final url = "http://yhzzzz.natapp1.cc/api/v1/s3/test2/" + uri_filename +
            "?" + token + method;
        var request = await HttpClient().getUrl(Uri.parse(url));
        var response = await request.close();
        var bytes = await consolidateHttpClientResponseBytes(response);
        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = new File('$dir/$filename');
        type = filename.substring(filename.lastIndexOf(".") + 1);

        //pdf 写入
        if (type == "pdf") {
          StreamSubscription subscription = controller.stream.listen((value) {
            file.writeAsBytes(bytes);
          });
          controller.sink.add(bytes);
          controller.close();
          assetpath = file.path;
          //return file;
        }

        //txt 写入
        else if(type=="txt"){
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
              if(assetpath==""){
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(allText),
                  ),),
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