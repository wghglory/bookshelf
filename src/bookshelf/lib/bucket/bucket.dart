import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:bookshelf/tools.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ActOnObject { delete, download }

class BucketPage extends StatefulWidget {
  @override
  _BucketPageState createState() => _BucketPageState();
}

class _BucketPageState extends State<BucketPage> {
  final Set<String> _objectlist = <String>{};
  String _usertoken = '';
  String _bucketName = '';
  Dio _dio;
  BucketPageArguments _arg;
  TenantUser _tenantUser;
  Bucket _bucket;

  Future<Map<String, dynamic>> _getBuckets() async {
    try {
      var dio = new Dio(this._dio.options);
      dio.options.queryParameters = new Map.from({
        'offset': '0',
        'order': 'lastModified DESC',
        'filter': '',
        'delimiter': '/',
        'fetch-owner': true,
      });
      Response response = await dio.get('/api/v1/s3/${this._bucketName}');
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Objects Success");
        return response.data;
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
      var dio = new Dio(this._dio.options);
      Response response =
          await dio.delete('/api/v1/s3/${this._bucketName}/$objectName');
      int returncode = response.statusCode;
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

  @override
  Widget build(BuildContext context) {
    this._arg = ModalRoute.of(context).settings.arguments;
    this._usertoken = this._arg.userToken;
    this._bucketName = this._arg.bucketName;
    this._tenantUser = this._arg.tenantUser;
    var option = this._arg.options;
    option.headers['x-vcloud-authorization'] = this._usertoken;
    this._dio = Dio(option);

    Widget _buildRow(int index) {
      //Each row is a card
      String objectName = _objectlist.elementAt(index);
      return Card(
        child: ListTile(
          title: Text(objectName),
          onTap: () {
            setState(() {});
          },
          trailing: PopupMenuButton<ActOnObject>(
            // choose actions in pop menu buttom
            onSelected: (ActOnObject result) {
              setState(() {
                switch (result) {
                  case ActOnObject.delete:
                    {
                      _deleteObjectPressed(objectName);
                      return;
                    }
                  case ActOnObject.download:
                    {
                      return;
                    }
                }
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<ActOnObject>>[
              const PopupMenuItem<ActOnObject>(
                value: ActOnObject.delete,
                child: Text('Delete'),
              ),
              const PopupMenuItem<ActOnObject>(
                value: ActOnObject.download,
                child: Text('Download'),
              ),
            ],
          ),
        ),
      );
    }

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
                  return SnackBar(
                    content: Text('Exception happens and Get Buckets Failed!'),
                    duration: Duration(seconds: 1),
                  );
                else {
                  this._bucket = Bucket.fromJson(snapshot.data);
                  if (_bucket.objectList.isNotEmpty) {
                    debugPrint(
                        'There are ${_bucket.objectList.length} Objects');
                    _bucket.objectList
                        .forEach((String k, Object v) => _objectlist.add(k));
                    return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: this._objectlist.length,
                        itemBuilder: (context, i) {
                          //Only shows the Object name, further action will be completed soon
                          return _buildRow(i);
                        });
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
        title: Text("${this._bucketName}"),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.update),
            tooltip: 'Refresh List',
            onPressed: () {
              _refreshPressed();
            },
          ),
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
                        this._tenantUser.fullName,
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
                      style: Theme.of(context).textTheme.body1.copyWith(fontSize: ScreenUtil().setSp(36)),
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
                      style: Theme.of(context).textTheme.body1.copyWith(fontSize: ScreenUtil().setSp(36)),
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
