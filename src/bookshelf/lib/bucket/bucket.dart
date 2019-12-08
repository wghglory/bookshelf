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
import 'package:load/load.dart';
import 'package:circle_wave_progress/circle_wave_progress.dart';

enum ActOnObject { delete, download, acl, userlist }

class BucketPage extends StatefulWidget {
  @override
  _BucketPageState createState() => _BucketPageState();
}

class _BucketPageState extends State<BucketPage> {
  final Set<String> _objectlist = <String>{};
  String _usertoken = '';
  String _bucketName = '';
  String _uploadFilePath = '';
  String _uploadFileName = '';
  String _downloadPath = '';
  FileType _uploadFileType = FileType.CUSTOM;
  Dio _dio;
  BucketPageArguments _arg;
  TenantUser _tenantUser;
  Bucket _bucket;
  Map<String, Stream<double>> _downloadProgress =
      new Map<String, Stream<double>>();

  Future<bool> _getObjectAcl(String objectName) async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['Accept'] = 'application/json';
      Response response = await this
          ._dio
          .get('/api/v1/s3/${this._bucketName}/$objectName', options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        if (response.data['grants'].length > 1) {
          //debugPrint("$objectName is shared");
          return true;
        } else {
          //debugPrint("$objectName is private");
        }
        return false;
      } else {
        debugPrint("Get Object ACL Failed and return code is $returncode");
        return false;
      }
    } on DioError catch (e) {
      debugPrint("Exception: $e happens and Get Object ACL Failed");
      int returncode = e.response.statusCode;
      if (returncode == 403) {
        RequestOptions rqop = new RequestOptions();
        rqop.queryParameters = new Map.from({
          'meta': '',
        });
        rqop.headers['Accept'] = 'application/json';
        try {
          Response response = await this
              ._dio
              .get('/api/v1/s3/${this._bucketName}/$objectName', options: rqop);
          int returncode = response.statusCode;
          if (returncode == 200) {
            debugPrint("Get $objectName meta success");
            return true;
          }
          return false;
        } on DioError catch (e) {
          debugPrint("Exception: $e happens and Get Object meta Failed");
          return false;
        }
      }
      return false;
    }
  }

  Future<bool> ifSharedBucket(String objectName) async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['Accept'] = 'application/json';
      Response response = await this
          ._dio
          .get('/api/v1/s3/${this._bucketName}/$objectName', options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint(
            "The Object $objectName is in a user's own bucket ${this._bucketName}");
        return false;
      }
      return false;
    } catch (e) {   
      debugPrint("The Object $objectName is in a shared bucket ${this._bucketName}");
      return true;
    }
  }

  Future<List<dynamic>> _getObjects() async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'offset': '0',
        'order': 'lastModified DESC',
        'filter': '',
        'delimiter': '/',
        'fetch-owner': true,
      });
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      Response response =
          await this._dio.get('/api/v1/s3/$urlBucketName', options: rqop);
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Objects Success");
        int objectCnt = response.data['keyCount'];
        print(response.data['keyCount']);
        Map<String, bool> objectList = objectCnt > 0
            ? new Map.fromIterable(
                response.data['objectBrief'],
                key: (item) => item['key'],
                value: (item) => true,
              )
            : Map<String, bool>();
        if (objectList.isNotEmpty) {
          for (var key in objectList.keys) {
            bool shared = await _getObjectAcl(key);
            objectList[key] = shared;
          }
        }
        List<dynamic> result = new List();
        result.add(response.data);
        result.add(objectList);
        return result;
      } else {
        debugPrint("Get Objects Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Objects Failed");
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
                      if (snapshot.hasError) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleDialog(
                                title: Text('Upload failed!'),
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
                            });
                      }
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
  }
  */

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

  // change the permission of object into public read
  Future<void> _shareObjectPressed(String objectName) async {
    if (objectName.isEmpty) {
      return;
    }
    try {
      RequestOptions rqop1 = new RequestOptions();
      rqop1.queryParameters = new Map.from({
        'acl': '',
      });
      rqop1.headers['x-amz-acl'] = 'public-read-write';
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      Response response1 =
          await this._dio.put('/api/v1/s3/$urlBucketName', options: rqop1);
      int returncode1 = response1.statusCode;
      RequestOptions rqop2 = new RequestOptions();
      rqop2.queryParameters = new Map.from({
        'acl': '',
      });
      rqop2.headers['x-amz-acl'] = 'public-read';
      String urlObjectName = Uri.encodeComponent(objectName);
      Response response2 = await this
          ._dio
          .put('/api/v1/s3/$urlBucketName/$urlObjectName', options: rqop2);
      int returncode2 = response2.statusCode;
      if (returncode1 == 200 && returncode2 == 200) {
        debugPrint("Share Bucket $objectName Success");
      } else {
        debugPrint(
            "Share Bucket $objectName Failed and Return code is $returncode1 and $returncode2");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Share Bucket $objectName Failed");
    } finally {
      _refreshPressed();
    }
  }

  //change the permission of object into private
  Future<void> _lockObjectPressed(String objectName) async {
    if (objectName.isEmpty) {
      return;
    }
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['x-amz-acl'] = 'private';
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      String urlObjectName = Uri.encodeComponent(objectName);
      Response response = await this
          ._dio
          .put('/api/v1/s3/$urlBucketName/$urlObjectName', options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Lock Bucket $objectName Success");
      } else {
        debugPrint(
            "Lock Bucket $objectName Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Lock Bucket $objectName Failed");
    } finally {
      _refreshPressed();
    }
  }

  //get the response data of object acl
  Future<Map<String, dynamic>> _getObjectAclData(String objectName) async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['Accept'] = 'application/json';
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      String urlObjectName = Uri.encodeComponent(objectName);
      Response response = await this
          ._dio
          .get('/api/v1/s3/$urlBucketName/$urlObjectName', options: rqop);
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Object ACL Success");
        return response.data;
      } else {
        debugPrint("Get Object ACL Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Object ACL Failed");
      return null;
    }
  }

  // change the permission of bucket into public read & write
  Future<void> _shareBucketPressed(String bucketName) async {
    if (bucketName.isEmpty) {
      return;
    }
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['x-amz-acl'] = 'public-read-write';
      String urlBucketName = Uri.encodeComponent(bucketName);
      Response response =
          await this._dio.put('/api/v1/s3/$urlBucketName', options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Share Bucket $bucketName Success");
      } else {
        debugPrint(
            "Share Bucket $bucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Share Bucket $bucketName Failed");
    } finally {
      _refreshPressed();
    }
  }

  //set the share object read & write acl to a single user
  Future<void> _userOptionPressed(
      String objectName, String userName, String userId) async {
    try {
      _shareBucketPressed(this._bucketName);
      var currentacl = await _getObjectAclData(objectName);
      var newgrantread = {
        "grantee": {"id": userId, "displayName": userName},
        "permission": "READ"
      };
      currentacl['grants'].add(newgrantread);

      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['Content-Type'] = 'application/json';
      String urlBucketName = Uri.encodeComponent(this._bucketName);
      String urlObjectName = Uri.encodeComponent(objectName);
      Response response = await this._dio.put(
          '/api/v1/s3/$urlBucketName/$urlObjectName',
          options: rqop,
          data: currentacl);
      int returncode = response.statusCode;
      if (returncode == 200) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: Text('Successfully shared to $userName'),
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
            });
        debugPrint("Share Object $objectName to user $userName Success");
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Share to failed!'),
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
          });
        debugPrint(
            "Share Object $objectName to user $userName and Return code is $returncode");
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Share to failed!'),
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
          });
      debugPrint(
          "Exception: $e happens and share Object to user $userName $objectName Failed");
    } finally {
      _refreshPressed();
    }
  }

  //show the user list for sharing
  Future<void> _userListPressed(String objectName) async {
    if (objectName.isEmpty) {
      return;
    }
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'offset': '0',
        'limit': '10',
        'order': 'name asc',
        'filter': '',
        'include-usage': 'false',
      });
      Response response = await this._dio.get(
          '/api/v1/admin/tenants/c2d27ee9-b302-4136-9320-503cd6146dd4/users',
          options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Get user list Success");
        int usercount = response.data['items'].length;
        var users = response.data['items'];
        Map<String, bool> userlist = users == null
            ? new Map<String, bool>()
            : new Map.fromIterable(
                users,
                key: (item) => item['name'],
                value: (item) => true,
              );
        Map<String, bool> idlist = users == null
            ? new Map<String, bool>()
            : new Map.fromIterable(
                users,
                key: (item) => item['id'],
                value: (item) => true,
              );
        final List<String> _userlist = [];
        userlist.forEach((String k, bool v) {
          _userlist.add(k);
          debugPrint("$k");
        });
        final List<String> _idlist = [];
        idlist.forEach((String k1, bool v1) {
          _idlist.add(k1);
          debugPrint("$k1");
        });
        debugPrint("There are $usercount users");
        //show the simpledialog which includes all the selection of users
        List<SimpleDialogOption> buildSimpleDialogOptions(
            List<String> _userlist) {
          List<SimpleDialogOption> dialogList = List();
          _userlist.forEach((String m) {
            String n = _idlist[_userlist.indexOf(m)];
            var option = SimpleDialogOption(
              onPressed: () {
                _userOptionPressed(objectName, m, n);
              },
              child: Text(m),
            );
            dialogList.add(option);
          });
          var exitoption = SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Finish Share",
                style: Theme.of(context).textTheme.button,
                textAlign: TextAlign.right,
              ));

          dialogList.add(exitoption);
          return dialogList;
        }

        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: const Text('Select the user you want to share'),
                children: buildSimpleDialogOptions(_userlist),
              );
            });
      } else {
        debugPrint("Get user list Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get user list Failed");
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
    this._usertoken = this._arg.userToken;
    this._bucketName = this._arg.bucketName;
    this._tenantUser = this._arg.tenantUser;
    var option = this._arg.options;
    option.headers['x-vcloud-authorization'] = this._usertoken;
    this._dio = Dio(option);

    Widget _buildGridCell(int index) {
      String objectName = this._objectlist.elementAt(index);
      String type = objectName.substring(objectName.lastIndexOf(".") + 1);
      String displayName = objectName;
      if (objectName.lastIndexOf(".") > 12) {
        displayName = objectName.substring(0, 12) + '...' + type;
      }
      //Whether the object is currently shared or locked
      bool shared = this._bucket.objectList[objectName].shared;
      String aclType = 'Share';
      IconData iconType = Icons.share;
      if (shared == true) {
        aclType = 'Lock';
        iconType = Icons.lock;
      }
      return GestureDetector(
        onTap: () async {
          //_previewObject(objectName);
          await _previewObjectPressed(objectName);
        },
        onLongPress: () async {
          bool issharedbucket = await ifSharedBucket(objectName);
          print(issharedbucket);
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
                      Offstage(
                        offstage: issharedbucket,
                        child: new Column(children: <Widget>[
                          new Padding(
                              padding: EdgeInsets.fromLTRB(
                                  0.0,
                                  ScreenUtil().setHeight(2),
                                  0.0,
                                  ScreenUtil().setHeight(2)),
                              child: IconButton(
                                  icon: Icon(iconType,
                                      size: ScreenUtil().setWidth(80)),
                                  color: Color.fromARGB(150, 0, 0, 0),
                                  onPressed: () {
                                    Navigator.of(context).pop(ActOnObject.acl);
                                  })),
                          new Text(
                            aclType,
                            style: Theme.of(context)
                                .textTheme
                                .body1
                                .copyWith(fontSize: ScreenUtil().setSp(30)),
                          )
                        ]),
                      ),
                      Offstage(
                        offstage: issharedbucket,
                        child: new Column(children: <Widget>[
                          new Padding(
                              padding: EdgeInsets.fromLTRB(
                                  0.0,
                                  ScreenUtil().setHeight(2),
                                  0.0,
                                  ScreenUtil().setHeight(2)),
                              child: IconButton(
                                  icon: Icon(Icons.person,
                                      size: ScreenUtil().setWidth(80)),
                                  color: Color.fromARGB(150, 0, 0, 0),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(ActOnObject.userlist);
                                  })),
                          new Text(
                            'Share to',
                            style: Theme.of(context)
                                .textTheme
                                .body1
                                .copyWith(fontSize: ScreenUtil().setSp(30)),
                          )
                        ]),
                      )
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
                Navigator.pushNamed(
                  context,
                  '/download',
                  arguments: DownloadPageArguments(
                      this._usertoken, this._downloadProgress),
                );
                return;
              }
            case ActOnObject.acl:
              {
                if (shared == false) {
                  await _shareObjectPressed(objectName);
                } else {
                  await _lockObjectPressed(objectName);
                }
                return;
              }
            case ActOnObject.userlist:
              {
                await _userListPressed(objectName);
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
                  if (!snapshot.hasData) {
                    return Container(
                      child: Center(
                        child: new Text(
                          'Network error! Please check your network.',
                          style: Theme.of(context)
                              .textTheme
                              .body1
                              .copyWith(fontSize: ScreenUtil().setSp(48)),
                        ),
                      ),
                    );
                  }
                  this._bucket =
                      Bucket.fromJson(snapshot.data[0], snapshot.data[1]);
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
                try {
                  await _uploading();
                } catch (e) {}
              }),
          new IconButton(
            icon: const Icon(Icons.refresh),
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
                        this._tenantUser.fullName,
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
