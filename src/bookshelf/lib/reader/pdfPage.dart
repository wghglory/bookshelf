import 'package:flutter/material.dart';
import 'package:bookshelf/tools.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';


class PdfPage extends StatefulWidget {
  @override
  _PdfPageState createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  PdfPageArguments _arg;
  String _usertoken = '';
  String _bucketName = '';
  String _objectName = '';
  String _pathName = '';
  String _filePath = '';
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int pages = 0;
  bool isReady = false;

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
        title: Text("${this._objectName}"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: this._filePath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: false,
            nightMode: false,
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              print(error.toString());
            },
            onPageError: (page, error) {
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
            },
            onPageChanged: (int page, int total) {
              print('page change: $page/$total');
            },
          ),
          !isReady
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Container()
        ],
      ),
      floatingActionButton: FutureBuilder<PDFViewController>(
        future: _controller.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton.extended(
              label: Text("Go to ${pages ~/ 2}"),
              onPressed: () async {
                await snapshot.data.setPage(pages ~/ 2);
              },
            );
          }

          return Container();
        },
      ),
    );
  }
}
