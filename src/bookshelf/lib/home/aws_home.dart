import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:xml2json/xml2json.dart';
import 'package:bookshelf/tools.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;

//may add further action on bucket in the future
enum ActOnBucket { delete, empty }

class AWSHomePage extends StatefulWidget {
  @override
  _AWSHomePageState createState() => _AWSHomePageState();
}

class _AWSHomePageState extends State<AWSHomePage> {
  String _accessKey = '';
  String _secretKey = '';
  String _region = '';
  String _usertoken = '';
  final Set<String> _bucketlist = <String>{};
  final TextEditingController _bucketInput = new TextEditingController();
  AWSHomePageArguments _arg;
  TenantUser _tenantUser;
  AWSUserBuckets _userBuckets;
  Dio _dio;

  //returns result of Get request in json format
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

  Future<Map<String, dynamic>> _getBuckets() async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.headers['Accept'] = '*/*';
      rqop.queryParameters = new Map.from({
        'filter': '',
        'offset': '0',
        'order': 'lastModified DESC',
      });
      String path = '/';
      rqop = this._getSignature(rqop, "GET", path);
      print(this._dio.options.headers);
      Response response = await this._dio.get('', options: rqop);
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Buckets Success");
        final Xml2Json myTransformer = Xml2Json();
        myTransformer.parse(response.data);
        String js = myTransformer.toParker();
        Map<String, dynamic> jsdata = json.decode(js);
        return jsdata;
      } else {
        print(response.headers);
        final Xml2Json myTransformer = Xml2Json();
        myTransformer.parse(response.data);
        String js = myTransformer.toParker();
        Map<String, dynamic> data = json.decode(js);
        data['Error'].forEach((k, v) {
          print('$k:${data['Error']['$k']}');
        });
        debugPrint("Get Buckets Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Buckets Failed");
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
      this._bucketlist.clear();
    });
  }

  //send add request and refresh
  Future<void> _addBucketPressed(String newBucketName) async {
    if (newBucketName == '') {
      return;
    }
    try {
      String urlBucketName = Uri.encodeComponent(newBucketName);
      RequestOptions rqop = new RequestOptions();
      //rqop.headers['x-amz-acl'] = 'private';
      String path = '/$urlBucketName';
      rqop = this._getSignature(rqop, 'PUT', path);
      Response response = await this._dio.put('$path',options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Create Bucket $newBucketName Success");
      } else {
        debugPrint(
            "Create Bucket $newBucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Create Bucket Failed");
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
    } finally {
      //_refreshPressed();
    }
  }

  Future<void> _deleteBucketPressed(String bucketName) async {
    if (bucketName.isEmpty) {
      return;
    }
    try {
      String urlBucketName = Uri.encodeComponent(bucketName);
      String path = '/$urlBucketName';
      RequestOptions rqop = new RequestOptions();
      rqop = this._getSignature(rqop, 'DELETE', path);
      Response response = await this._dio.delete('$path',options: rqop);
      int returncode = response.statusCode;
      if (returncode == 204) {
        debugPrint("Delete Bucket $bucketName Success");
      } else {
        debugPrint(
            "Delete Bucket $bucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Delete Bucket $bucketName Failed");
    } finally {
      _refreshPressed();
    }
  }

  Future<void> _clearBucketPressed(String bucketName) async {
    if (bucketName.isEmpty) {
      return;
    }
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'delete': '',
      });
      String urlBucketName = Uri.encodeComponent(bucketName);
      Response response = await this._dio.post('/api/v1/s3/$urlBucketName',
          data: {'removeAll': true}, options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Clear Bucket $bucketName Success");
      } else {
        debugPrint(
            "Clear Bucket $bucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Clear Bucket $bucketName Failed");
    } finally {
      _refreshPressed();
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

  //each row is a card representing a bucket
  Widget _buildRow(int index) {
    //Each row is a card
    String bucketName = this._bucketlist.elementAt(index);
    bool shared = this._userBuckets.bucketList[bucketName];
    //Whether the bucket is currently shared or locked
    //bool Shared = false;
    return Card(
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(bucketName, style: Theme.of(context).textTheme.body1),
            _getSharedIcon(shared),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/awsbucket',
            arguments: AWSBucketPageArguments(
                this._accessKey,this._secretKey, bucketName),
          );
        },
        trailing: PopupMenuButton<ActOnBucket>(
          // choose actions in pop menu buttom
          onSelected: (ActOnBucket result) {
            setState(() {
              switch (result) {
                case ActOnBucket.delete:
                  {
                    _deleteBucketPressed(bucketName);
                    return;
                  }
                case ActOnBucket.empty:
                  {
                    _clearBucketPressed(bucketName);
                    return;
                  }
              }
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<ActOnBucket>>[
            const PopupMenuItem<ActOnBucket>(
              value: ActOnBucket.delete,
              child: Text('Delete'),
            ),
            const PopupMenuItem<ActOnBucket>(
              value: ActOnBucket.empty,
              child: Text('Empty'),
            ),
          ],
        ),
      ),
    );
  }

  //build the bucket list
  Widget _buildList() {
    debugPrint("Running _buildList");
    return Center(
        //user FutureBuilder to handle future func in Widgets
        child: FutureBuilder(
            future: _getBuckets(),
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
                    return Container(
                      child: Text('Exception happens and Get Buckets Failed!'),
                    );
                  else {
                    print(snapshot.data);

                    this._userBuckets = AWSUserBuckets.fromJson(snapshot.data);
                    //if there is no bucket
                    if (this._userBuckets.bucketList.isNotEmpty) {
                      debugPrint(
                          'There are ${this._userBuckets.bucketList.length} buckets');
                      this._userBuckets.bucketList.forEach((String k, bool v) {
                        this._bucketlist.add(k);
                      });
                      return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: this._bucketlist.length,
                          itemBuilder: (context, i) {
                            //Only shows the bucket name, further action will be completed soon
                            return _buildRow(i);
                          });
                    } else {
                      return new Container(); //if no buckets
                    }
                  }
              }
              return null;
            }));
  }

  @override
  Widget build(BuildContext context) {
    this._arg = ModalRoute.of(context).settings.arguments;
    this._accessKey = this._arg.accessKey;
    this._secretKey = this._arg.secretKey;
    this._region = 'us-east-1';
    var option = this._arg.options;
    this._dio = Dio(option);
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (BuildContext context) {
          return IconButton(
              icon: Icon(Icons.menu),
              color: Color.fromARGB(150, 0, 0, 0),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              });
        }),
        title: Text("My Bookshelf", style: Theme.of(context).textTheme.title),
        actions: <Widget>[
          //Add Bucket Button
          new IconButton(
              icon: const Icon(Icons.add_box),
              color: Color.fromARGB(150, 0, 0, 0),
              tooltip: 'Add Bucket',
              onPressed: () async {
                String newBucketName = '';
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Enter new Bucket'),
                      content: TextField(
                        controller: this._bucketInput,
                        decoration:
                            InputDecoration(hintText: "New Bucket Name"),
                      ),
                      actions: <Widget>[
                        new FlatButton(
                          child: new Text('OK',
                              style: TextStyle(
                                color: Color.fromARGB(150, 0, 0, 0),
                              )),
                          onPressed: () {
                            newBucketName = this._bucketInput.text.isEmpty
                                ? ''
                                : this._bucketInput.text;
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  },
                );
                await _addBucketPressed(newBucketName);
              }),
          //Update Bucket List Button
          new IconButton(
              icon: const Icon(Icons.refresh),
              color: Color.fromARGB(150, 0, 0, 0),
              tooltip: 'Refresh List',
              onPressed: () {
                _refreshPressed();
              }),
          /*
            new IconButton(
              icon: const Icon(Icons.file_download),
              color: Color.fromARGB(150, 0, 0, 0),
              tooltip: 'Download List',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/download',
                  arguments: DownloadPageArguments(this._usertoken),
                );
              },
            )*/
        ],
      ),
      body: _buildList(),
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
                        'Wenhao Meng',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(150, 0, 0, 0),
                            height: 2.5,
                            fontSize: 30,
                            fontStyle: FontStyle.normal),
                      ),
                    ]),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 197, 207, 255),
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
