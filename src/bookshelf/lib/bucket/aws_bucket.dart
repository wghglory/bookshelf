import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:bookshelf/tools.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml2json/xml2json.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:load/load.dart';
import 'package:circle_wave_progress/circle_wave_progress.dart';

enum ActOnObject { delete, download}

class AWSBucketPage extends StatefulWidget {
  @override
  _AWSBucketPageState createState() => _AWSBucketPageState();
}

class _AWSBucketPageState extends State<AWSBucketPage> {
  final Set<String> _objectlist = <String>{};
  String _usertoken = '';
  String _accessKey = '';
  String _secretKey = '';
  String _bucketName = '';
  String _region = '';
  String _uploadFilePath = '';
  String _uploadFileName = '';
  String _downloadPath = '';
  FileType _uploadFileType = FileType.CUSTOM;
  Dio _dio;
  AWSBucketPageArguments _arg;
  TenantUser _tenantUser;
  AWSBucket _bucket;
  Map<String, Stream<double>> _downloadProgress =
      new Map<String, Stream<double>>();

  RequestOptions _getSignature(
      RequestOptions rqop, String method, String path) {
    var kSecret = utf8.encode("AWS4" + '${this._secretKey}');
    var hmacSha256 = new Hmac(sha256, kSecret);
    String time = DateTime.now()
        .toUtc()
        .toString()
        .replaceAll(RegExp(r'\.\d*Z$'), 'Z')
        .replaceAll(RegExp(r'[:-]|\.\d{3}'), '')
        .split(' ')
        .join('T');
    String date = time.substring(0, 8);
    print('Time is $time');
    String credentialScope =
        date + '/' + this._region + '/' + 's3' + '/' + 'aws4_request';
    String canonicalUri = path;
    String canonicalQueryString = '';
    if (rqop.queryParameters != null) {
      rqop.queryParameters.forEach((k, v) {
        canonicalQueryString = canonicalQueryString +
            Uri.encodeComponent("$k") +
            "=" +
            Uri.encodeComponent("$v") +
            "&";
      });
      canonicalQueryString =
          canonicalQueryString.substring(0, canonicalQueryString.length - 1);
    }
    print("canonicalQueryString is $canonicalQueryString");
    String canonicalHeaders = 'host:' +
        's3.${this._region}.amazonaws.com' +
        '\n' +
        'x-amz-date:' +
        time +
        '\n';
    String signedHeaders = 'host;x-amz-date';
    String payloadHash = hex.encode(sha256.convert(utf8.encode('')).bytes);
    String canonicalRequest = method +
        '\n' +
        canonicalUri +
        '\n' +
        canonicalQueryString +
        '\n' +
        canonicalHeaders +
        '\n' +
        signedHeaders +
        '\n' +
        payloadHash;
    String stringToSign = 'AWS4-HMAC-SHA256' +
        '\n' +
        time +
        '\n' +
        credentialScope +
        '\n' +
        hex.encode(sha256.convert(utf8.encode(canonicalRequest)).bytes);
    print('String to sign is $stringToSign');
    var kDate = hmacSha256.convert(utf8.encode('$date')).bytes;
    var kRegion =
        Hmac(sha256, kDate).convert(utf8.encode('${this._region}')).bytes;
    var kService = Hmac(sha256, kRegion).convert(utf8.encode('s3')).bytes;
    var kSigning =
        Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
    var signature = hex.encode(
        Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).bytes);
    //print(time);
    String authorizationHeader = 'AWS4-HMAC-SHA256' +
        ' ' +
        'Credential=' +
        '${this._accessKey}' +
        '/' +
        credentialScope +
        ', ' +
        'SignedHeaders=' +
        signedHeaders +
        ', ' +
        'Signature=' +
        signature;
    rqop.headers['X-Amz-Date'] = time;
    rqop.headers['Authorization'] = authorizationHeader;
    rqop.headers['X-Amz-Content-Sha256'] = payloadHash;
    return rqop;
  }

  Future<Map<String, dynamic>> _getObjects() async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'delimiter': '/',
        'filter': '',
        'offset': '0',
        'order': 'lastModified DESC',
      });
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      String path = '/$urlBucketName';
      rqop = this._getSignature(rqop, 'GET', path);
      Response response = await this._dio.get('$path', options: rqop);
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Objects Success");
        final Xml2Json myTransformer = Xml2Json();
        myTransformer.parse(response.data);
        String js = myTransformer.toParker();
        Map<String, dynamic> jsdata = json.decode(js);
        print(jsdata['ListBucketResult']);
        return jsdata['ListBucketResult'];
      } else {
        debugPrint("Get Objects Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Objects Failed");
      if (e.response != null) {
        print(e.response.headers);
        final Xml2Json myTransformer = Xml2Json();
        myTransformer.parse(e.response.data);
        String js = myTransformer.toParker();
        Map<String, dynamic> data = json.decode(js);
        data['Error'].forEach((k, v) {
          print('$k:${data['Error']['$k']}');
        });
        print(e.response.request.headers);
      }
      return null;
    }
  }

  void _refreshPressed() {
    setState(() {
      this._objectlist.clear();
    });
  }

  Future<void> _deleteObjectPressed(String objectName) async {
    if (objectName.isEmpty) {
      return;
    }
    try {
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      String urlObjectName = Uri.encodeComponent(objectName);
      Response response =
          await this._dio.delete('/api/v1/s3/$urlBucketName/$urlObjectName');
      int returncode = response.statusCode;
      //return code 204 is success
      if (returncode == 204) {
        print("Delete Bucket $objectName Success");
      } else {
        print(
            "Delete Bucket $objectName Failed and Return code is $returncode");
      }
    } catch (e) {
      print("Exception: $e happens and Delete Bucket $objectName Failed");
    } finally {
      _refreshPressed();
    }
  }

  Future<void> _openFileExplorer() async {
    print("Running openFile");
    //use filepicker package to filter pdf file
    if (this._uploadFileType == FileType.CUSTOM) {
      try {
        this._uploadFilePath = await FilePicker.getFilePath(type: FileType.ANY);
      } on PlatformException catch (e) {
        print("Unsupported operation when selecting file" + e.toString());
      }
      if (!mounted) return;
      this._uploadFileName = this._uploadFilePath != null
          ? this._uploadFilePath.split('/').last
          : '...';
    }
  }

  Future<void> _uploading() async {
    await _openFileExplorer();
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Center(
            child: FutureBuilder(
                future: _uploadObjectPressed(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.active:
                      return Container();
                    case ConnectionState.waiting:
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            child: CircleWaveProgress(
                              size: ScreenUtil().setWidth(300),
                              borderWidth: ScreenUtil().setWidth(10),
                              borderColor: Colors.white,
                              waveColor: Color.fromARGB(255, 170, 202, 255),
                              backgroundColor: Colors.white,
                              progress: 50,
                            ),
                          )
                        ],
                      );
                    case ConnectionState.done:
                      String information;
                      bool kkk = snapshot.data;
                      print("--------------$kkk---------------");
                      if (!snapshot.hasData) {
                        return SimpleDialog(
                          title: Text("No file selected!"),
                          children: <Widget>[
                            SimpleDialogOption(
                              child: Text(
                                "OK",
                                style: Theme.of(context).textTheme.button,
                                textAlign: TextAlign.right,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      }
                      if (snapshot.data == false) {
                        information = "failed";
                      } else {
                        information = "success";
                      }
                      return SimpleDialog(
                        title: Text("upload $information!"),
                        children: <Widget>[
                          SimpleDialogOption(
                            child: Text(
                              "OK",
                              style: Theme.of(context).textTheme.button,
                              textAlign: TextAlign.right,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    //Navigator.of(context).pop();
                  }
                  //Navigator.pop(context);
                  return Container();
                }),
          );
        });
  }

  Future<bool> _uploadObjectPressed() async {
    bool ifsuccess = false;
    try {
      if (this._uploadFileName == '...') {
        print(ifsuccess);
        return ifsuccess;
      }
      File file = File(this._uploadFilePath);

      var bytes = await file.readAsBytes();
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      String urlObjectName = Uri.encodeComponent(this._uploadFileName);
      String url = this._dio.options.baseUrl +
          '/api/v1/s3/$urlBucketName/$urlObjectName?overwrite=true';
      //it seems that dio does not support binary request body, use http instead

      http.Response response = await http.put(
        url,
        headers: {
          'Host': 'yhzzzz.natapp1.cc',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Encoding': 'gzip, deflate',
          'Content-Type': 'application/pdf',
          'x-vcloud-authorization': this._usertoken,
        },
        body: bytes,
      );
      //hideLoadingDialog();
      var returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Upload File ${this._uploadFileName} Success");
        ifsuccess = true;
      } else {
        debugPrint(
            "Upload File ${this._uploadFileName} Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Upload File Failed");
    } finally {
      _refreshPressed();
    }
    return ifsuccess;
  }

  Future<String> _directoryExplorer() async {
    final Directory directory = await getExternalStorageDirectory();
    return directory.path;
  }
  /*
  Widget _previewObject(String objectName) {
    return Center(
      child: FutureBuilder(
          future: _previewObjectPressed(objectName),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.active:
              case ConnectionState.waiting:
                return Center(
                  child: CircularProgressIndicator(),
                );
              case ConnectionState.done:
                return Container();
            }
            return Container();
          }),
    );
  }*/

  Future<void> _previewObjectPressed(String objectName) async {
    this._downloadPath = await _directoryExplorer();
    String type = objectName.substring(objectName.lastIndexOf(".") + 1);
    try {
      String downloadFile = this._downloadPath + '/' + objectName;
      debugPrint(downloadFile);
      File file = new File(downloadFile);
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      String urlObjectName = Uri.encodeComponent(objectName);
      RequestOptions rqop = new RequestOptions();
      rqop.responseType = ResponseType.stream;
      rqop.queryParameters = new Map.from({
        'response-content-disposition': 'inline',
      });
      Response response = await this
          ._dio
          .get('/api/v1/s3/$urlBucketName/$urlObjectName', options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Preview File $objectName Success");
        var contentLength = int.parse(response.headers.value('Content-Length'));
        print(contentLength);
        //var sink = file.openWrite();
        int count = 0;
        int index = 0;
        Uint8List contents = new Uint8List(contentLength);
        response.data.stream.listen((data) {
          count = count + data.length;
          print("DataReceived: " +
              (count / contentLength * 100).toStringAsFixed(2) +
              '%');
          //add stream to content
          if (data.isNotEmpty) {
            contents.setAll(index, data);
            index = index + data.length;
          }
        }, onDone: () async {
          await file.writeAsBytes(contents);
          if (type == 'pdf') {
            Navigator.pushNamed(
              context,
              '/pdfViewer',
              arguments: PdfPageArguments(this._usertoken, this._bucketName,
                  objectName, this._downloadPath),
            );
          } else {
            Navigator.pushNamed(
              context,
              '/txtViewer',
              arguments: TxtPageArguments(this._usertoken, this._bucketName,
                  objectName, this._downloadPath),
            );
          }
        });
      } else {
        debugPrint(
            "Preview File $objectName Failed and Return code is $returncode");
      }
    } on DioError catch (e) {
      debugPrint("Exception: $e happens and Preview File Failed");
    }
  }

  Future<void> _downloadObjectPressed(String objectName) async {
    this._downloadPath = await _directoryExplorer();
    try {
      String downloadFile = this._downloadPath + '/' + objectName;
      debugPrint(downloadFile);
      File file = new File(downloadFile);
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      String urlObjectName = Uri.encodeComponent(objectName);
      RequestOptions rqop = new RequestOptions();
      rqop.responseType = ResponseType.stream;
      rqop.queryParameters = new Map.from({
        'response-content-disposition': 'inline',
      });
      Response response = await this
          ._dio
          .get('/api/v1/s3/$urlBucketName/$urlObjectName', options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Download File $objectName Success");
        var contentLength = int.parse(response.headers.value('Content-Length'));
        print(contentLength);
        //this._downloadProgress[objectName] = controller.stream;
        int count1 = 0;
        int count2 = 0;
        int index = 0;
        Uint8List contents = new Uint8List(contentLength);
        Stream<Uint8List> multistream =
            response.data.stream.asBroadcastStream();
        Stream<double> pgstream = multistream.transform(
            StreamTransformer.fromHandlers(handleData: (event, output) {
          count2 = count2 + event.length;
          double progress = count2 / contentLength * 100;
          print("add $progress");
          output.add(progress);
        }));
        this._downloadProgress[objectName] = pgstream;
        print("Here");
        multistream.listen((data) {
          count1 = count1 + data.length;
          double progress = count1 / contentLength * 100;
          print("DataReceived: " + progress.toStringAsFixed(2) + '%');
          //add stream to content
          if (data.isNotEmpty) {
            contents.setAll(index, data);
            index = index + data.length;
          }
        }, onDone: () async {
          await file.writeAsBytes(contents);
          this._downloadProgress.remove(objectName);
        });
      } else {
        debugPrint(
            "Download File $objectName Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Download File Failed");
    } finally {
      /*
      var stream = this._downloadProgress[objectName];
      stream.listen((data) {
          print("Listen $data");
        }, onDone: () {
          print("Complete");
        });*/

    }
  }



  Widget _getSharedIcon(bool shared) {
    if (shared) {
      return Icon(
        Icons.cloud_circle,
        size: 15,
        color: Colors.greenAccent,
      );
    } else {
      return Icon(
        Icons.person,
        size: 15,
        color: Colors.blueAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    this._arg = ModalRoute.of(context).settings.arguments;
    this._accessKey = this._arg.accessKey;
    this._secretKey = this._arg.secretKey;
    this._bucketName = this._arg.bucketName;
    this._region = 'us-east-1';
    //this._tenantUser = this._arg.tenantUser;
    var option = this._arg.options;
    this._dio = Dio(option);

    Widget _buildGridCell(int index) {
      String objectName = this._objectlist.elementAt(index);
      String type = objectName.substring(objectName.lastIndexOf(".") + 1);
      String displayName = objectName;
      if (objectName.lastIndexOf(".") > 15) {
        displayName = objectName.substring(0, 15) + '...' + type;
      }
      //Whether the object is currently shared or locked
      bool shared = this._bucket.objectList[objectName].shared;
      return GestureDetector(
        onTap: () async {
          //_previewObject(objectName);
          await _previewObjectPressed(objectName);
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
                                  Navigator.of(context).pop(ActOnObject.delete);
                                })),
                        new Text(
                          'Delete',
                          style: Theme.of(context)
                              .textTheme
                              .body1
                              .copyWith(fontSize: ScreenUtil().setSp(30)),
                        )
                      ]),
                      new Column(children: <Widget>[
                        new Padding(
                            padding: EdgeInsets.fromLTRB(
                                0.0,
                                ScreenUtil().setHeight(2),
                                0.0,
                                ScreenUtil().setHeight(2)),
                            child: IconButton(
                                icon: Icon(Icons.cloud_download,
                                    size: ScreenUtil().setWidth(80)),
                                color: Color.fromARGB(150, 0, 0, 0),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(ActOnObject.download);
                                })),
                        new Text(
                          'Download',
                          style: Theme.of(context)
                              .textTheme
                              .body1
                              .copyWith(fontSize: ScreenUtil().setSp(30)),
                        )
                      ]),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  ),
                );
              });
          switch (selected) {
            case ActOnObject.delete:
              {
                await _deleteObjectPressed(objectName);
                return;
              }
            case ActOnObject.download:
              {
                await _downloadObjectPressed(objectName);
                return;
              }
          }
        },
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          verticalDirection: VerticalDirection.down,
          children: <Widget>[
            type == 'pdf'
                ? Image.asset(
                    'assets/images/pdf_cover.png',
                    height: 100,
                    width: 100,
                  )
                : type == 'txt'
                    ? Image.asset(
                        'assets/images/txt_cover.png',
                        height: 100,
                        width: 100,
                      )
                    : Image.asset(
                        'assets/images/unknown.png',
                        height: 108,
                        width: 110,
                      ),
            new Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _getSharedIcon(shared),
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.body1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    }

    Widget _buildGrid() {
      print("Running buildGrid");
      return Center(
        //user FutureBuilder to handle future func in Widgets
        child: FutureBuilder(
          future: _getObjects(),
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
                    content: Text('Exception happens and Get Buckets Failed!'),
                    duration: Duration(seconds: 1),
                  );
                else {
                  this._bucket = AWSBucket.fromJson(snapshot.data);
                  if (this._bucket.objectList.isNotEmpty) {
                    debugPrint(
                        'There are ${this._bucket.objectList.length} Objects');
                    this._bucket.objectList.forEach(
                        (String k, Object v) => this._objectlist.add(k));
                    return GridView.count(
                      primary: false,
                      padding: const EdgeInsets.all(20),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      crossAxisCount: 2,
                      children: List.generate(this._objectlist.length, (index) {
                        return _buildGridCell(index);
                      }),
                    );
                  } else {
                    return new Container(); //if no buckets
                  }
                }
            }
            return null;
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${this._bucketName}",
            style: Theme.of(context).textTheme.title),
        actions: <Widget>[
          new IconButton(
              icon: const Icon(Icons.cloud_upload),
              color: Color.fromARGB(150, 0, 0, 0),
              tooltip: 'Update Book',
              onPressed: () async {
                await _uploading();
              }),
          new IconButton(
            icon: const Icon(Icons.update),
            color: Color.fromARGB(150, 0, 0, 0),
            tooltip: 'Refresh List',
            onPressed: () {
              _refreshPressed();
            },
          ),
          new IconButton(
            icon: const Icon(Icons.file_download),
            color: Color.fromARGB(150, 0, 0, 0),
            tooltip: 'Download List',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/download',
                arguments: DownloadPageArguments(
                    this._usertoken, this._downloadProgress),
              );
            },
          )
        ],
      ),
      body: _buildGrid(),
      drawer: Drawer(
        // Add a Colmun containing a Listview and a button at the bottom to the drawer.
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                // Remove any padding from the ListView
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    child: new Column(children: <Widget>[
                      Icon(Icons.account_circle, size: 32),
                      Text(
                        'Wenhao',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.title,
                      ),
                    ]),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 170, 202, 255),
                    ),
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(
                      'Profile',
                      style: Theme.of(context)
                          .textTheme
                          .body1
                          .copyWith(fontSize: ScreenUtil().setSp(36)),
                    ),
                    onTap: () {
                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(
                      'Setting',
                      style: Theme.of(context)
                          .textTheme
                          .body1
                          .copyWith(fontSize: ScreenUtil().setSp(36)),
                    ),
                    onTap: () {
                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Container(
              child: new Align(
                alignment: Alignment.bottomCenter,
                child: new ListTile(
                  leading: const Icon(Icons.keyboard_return),
                  title: Text('Logout'),
                  onTap: () {
                    //Return to login Page
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
