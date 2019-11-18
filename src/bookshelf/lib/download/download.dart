import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:bookshelf/tools.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  Future<Directory> _directoryExplorer() async {
    final Directory directory = await getExternalStorageDirectory();
    return directory;
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
      _list.add(
        new Card(
          child: ListTile(
            title: new Text(fileName, style: Theme.of(context).textTheme.body1),
            onTap: (){},
          ),
        )
        
      );
    }
    return _list;
  }

  Widget _buildDownloading(BuildContext context) {
    return new Text("tbd");
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
              else{
                List downloadList = snapshot.data;
                if(downloadList.isEmpty){
                  return Center(
                    child: Text("No Downloads", style: Theme.of(context).textTheme.body1),
                  );
                }
                else{
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

  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Download", style: Theme.of(context).textTheme.title),
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
