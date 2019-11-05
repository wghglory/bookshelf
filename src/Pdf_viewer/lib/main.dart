import 'dart:io';
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
  String assetfile = "assets/p2.pdf";
  String assetpath = "";

  @override
  void initState() {
    super.initState();
    //get the assetfile and give path to assetpath
    getfileFromAssets(assetfile).then((f) {
      setState(() {
        assetpath = f.path;
      });
    });
  }

  //提供方法获取pdf文档内容
  Future<File> getfileFromAssets(String fileas) async {
    try {
      //获取file中的数据
      var data = await rootBundle.load(fileas);
      //将数据转为byte类型的数据
      var byte = data.buffer.asUint8List();
      //存储数据路径
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/p2.pdf");
      //将数据写入file中
      File assetFile = await file.writeAsBytes(byte);
      return assetFile;
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("pdf reader"),
      ),
      body: Column(
        children: <Widget>[
          RaisedButton(

              onPressed: () {
                if (assetpath != null) {
                  Navigator.push(context,MaterialPageRoute(
                    builder: (context) => PdfPage(path: assetpath),
                  ));
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
  final String path;

  const PdfPage({Key key, this.path}) : super(key: key);

  @override
  _PdfPageState createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  int totalpages = 0;
  bool pdfready = false;
  PDFViewController pdfviewController;
  var _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("my doc"),
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,
            autoSpacing: true,
            enableSwipe: true,
            swipeHorizontal: true,
            onRender: (_pages) {
              setState(() {
                totalpages = _pages;
                pdfready = true;
              });
            },
            onViewCreated: (PDFViewController vc) {
              pdfviewController = vc;
            },
            onPageChanged: (int page, int total) {
              setState(() {
                _currentPage = page;
                totalpages = total;
              });
            },
          ),
          !pdfready? Center(
            child: CircularProgressIndicator(),
          )
              : Offstage()
        ],
      ),
      floatingActionButton: Row(
        children: <Widget>[
          _currentPage > 0? FloatingActionButton.extended(
            onPressed: () {
              _currentPage -= 1;
              pdfviewController.setPage(_currentPage);
            },
            label: Text("Go to ${_currentPage - 1}"),
            backgroundColor: Colors.red,
          )
              : Offstage(),
          _currentPage < totalpages - 1
              ? FloatingActionButton.extended(
            onPressed: () {
              _currentPage += 1;
              pdfviewController.setPage(_currentPage);
            },
            label: Text("Go to ${_currentPage + 1}"),
            backgroundColor: Colors.green,
          )
              : Offstage(),
        ],
      ),
    );
  }
}

