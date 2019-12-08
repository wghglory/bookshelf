import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:bookshelf/tools.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

enum ActOnObject { delete }

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  DownloadPageArguments _args;
  String _usertoken = "";
  Map<String, Stream<double>> _downloadList;

  Future<Directory> _directoryExplorer() async {
    final Directory directory = await getExternalStorageDirectory();
    return directory;
  }

  Image assertImage(String type) {
    switch (type) {
      case 'pdf':
        return Image.asset(
          'assets/images/pdf_cover.png',
          height: 40,
          width: 40,
        );
      case 'txt':
        return Image.asset(
          'assets/images/txt_cover.png',
          height: 40,
          width: 40,
        );
      default:
        return Image.asset(
          'assets/images/book-icon.jpg',
          height: 40,
          width: 40,
        );
    }
  }

  Future<List> _getDownloads() async {
    Directory dir = await _directoryExplorer();
    Stream<FileSystemEntity> entityList =
        dir.list(recursive: false, followLinks: false);
    List<Widget> _list = new List();
    await for (FileSystemEntity entity in entityList) {
      String fileName = (entity as File)
          .path
          .substring((entity as File).path.lastIndexOf('/') + 1);
      _list.add(new Card(
        child: ListTile(
          leading:
              assertImage(fileName.substring(fileName.lastIndexOf('.') + 1)),
          title: new Text(fileName, style: Theme.of(context).textTheme.body1),
          onTap: () {
            //print((entity as File).path);
            if (fileName.substring(fileName.lastIndexOf('.') + 1)=='pdf') {
              Navigator.pushNamed(
              context,
              '/pdfViewer',
              arguments: PdfPageArguments('', '', fileName, dir.path),
            ).catchError(() {
              print("error in opening pdf!");
            });
            } else {
              Navigator.pushNamed(
              context,
              '/txtViewer',
              arguments: TxtPageArguments(this._usertoken, '',
                  fileName, dir.path),
            );
            }
            
          },
          onLongPress: () async {
            var selected = await showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                      height: ScreenUtil().setHeight(200),
                      child: Row(
                        children: <Widget>[
                          new Column(children: <Widget>[
                            new Padding(
                                padding: EdgeInsets.fromLTRB(
                                    0.0,
                                    ScreenUtil().setHeight(2),
                                    0.0,
                                    ScreenUtil().setHeight(2)),
                                child: IconButton(
                                    icon: Icon(Icons.delete,
                                        size: ScreenUtil().setWidth(80)),
                                    color: Color.fromARGB(150, 0, 0, 0),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(ActOnObject.delete);
                                    })),
                            new Text(
                              'Delete',
                              style: Theme.of(context)
                                  .textTheme
                                  .title
                                  .copyWith(fontSize: ScreenUtil().setSp(30)),
                            )
                          ]),
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      ));
                });
            switch (selected) {
              case ActOnObject.delete:
                {
                  await _deleteFilePressed((entity as File));
                  return;
                }
            }
          },
        ),
      ));
    }
    return _list;
  }

  Future<void> _deleteFilePressed(File file) async {
    await file.delete();
    setState(() {
      print('delete success!');
    });
  }

  Widget _buildDownloading(BuildContext context) {
    List<Widget> _list = new List();
    if (this._downloadList.isEmpty) {
      return Center(
        child: Text(""),
      );
      
    }
    this._downloadList.forEach((fileName, downloadProgress) {
      _list.add(StreamBuilder(
          stream: downloadProgress,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("error in downloading");
            }
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return Text("no downloadings");
              case ConnectionState.waiting:
                return Text("getting downloadings");
              case ConnectionState.active:
                return new Card(
                    child: ListTile(
                        leading: assertImage(
                            fileName.substring(fileName.lastIndexOf('.') + 1)),
                        title: new Text(fileName,
                            style: Theme.of(context).textTheme.body1),
                        onTap: () {
                          //print((entity as File).path);
                        },
                        onLongPress: () async {},
                        trailing: CircularPercentIndicator(
                          radius: 30.0,
                          lineWidth: 5.0,
                          percent: snapshot.data / 100,
                          center: new Icon(
                            Icons.check_circle_outline,
                            size: 20.0,
                            color: Color.fromARGB(255, 170, 202, 255),
                          ),
                          backgroundColor: Colors.grey,
                          progressColor: Color.fromARGB(255, 170, 202, 255),
                        )));
              case ConnectionState.done:
                return Container();
            }
          }));
    });
    return new ListView(
      children: _list,
    );
  }

  Widget _buildComplete(BuildContext context) {
    return Container(
      child: FutureBuilder(
        future: _getDownloads(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(
                child: CircularProgressIndicator(),
              );
            case ConnectionState.done:
              if (snapshot.hasError)
                return SnackBar(
                  content: Text('Exception happens and Get Downloads Failed!'),
                  duration: Duration(seconds: 1),
                );
              else {
                List downloadList = snapshot.data;
                if (downloadList.isEmpty) {
                  return Center(
                    child: Text("No Downloads",
                        style: Theme.of(context).textTheme.body1),
                  );
                } else {
                  return ListView(
                    children: downloadList,
                  );
                }
              }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    this._args = ModalRoute.of(context).settings.arguments;
    this._usertoken = this._args.userToken;
    this._downloadList = this._args.downloadList;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Download", style: Theme.of(context).textTheme.title),
          actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.refresh),
              color: Color.fromARGB(150, 0, 0, 0),
              onPressed: (){
                setState(() {
                });
              },
            )
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                child: Text("Downloading",
                    style: Theme.of(context).textTheme.body1),
              ),
              Tab(
                child:
                    Text("Complete", style: Theme.of(context).textTheme.body1),
              )
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildDownloading(context),
            _buildComplete(context)
          ],
        ),
      ),
    );
  }
}
