import 'package:flutter/material.dart';
import 'package:bookshelf/tools.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
//import 'package:flutter_pdfview/flutter_pdfview.dart';
//import 'package:flutter_pdf_viewer/flutter_pdf_viewer.dart';
//import 'package:flutter_full_pdf_viewer/flutter_full_pdf_viewer.dart';
//import 'package:flutter_full_pdf_viewer/full_pdf_viewer_plugin.dart';
//import 'package:flutter_full_pdf_viewer/full_pdf_viewer_scaffold.dart';


class PdfPage extends StatefulWidget {
  @override
  _PdfPageState createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  bool pdfready = false;
  //PDFViewController pdfviewController;
  PdfPageArguments _arg;
  String _usertoken = '';
  String _bucketName = '';
  String _objectName = '';
  String _pathName = '';
  String _filePath = '';
  
  

  @override
  Widget build(BuildContext context) {
    this._arg = ModalRoute.of(context).settings.arguments;
    this._usertoken = this._arg.userToken;
    this._bucketName = this._arg.bucketName;
    this._objectName = this._arg.objectName;
    this._pathName = this._arg.pathName;
    this._filePath = this._pathName + '/' + this._objectName;
    
    print(this._filePath);
    //return PDFViewerScaffold(
    return Scaffold(
        appBar: AppBar(
          title: Text("Document"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {},
            ),
          ],
        ),
        body: new Container());
  }
}
