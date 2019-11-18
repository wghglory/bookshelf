import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
//import 'package:xml2json/xml2json.dart';
import 'package:bookshelf/tools.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

//may add further action on bucket in the future
enum ACL { shared, private }
enum ActOnBucket { delete, empty, ACL }

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _usertoken = '';
  final Set<String> _bucketlist = <String>{};
  final Set<String> _sharedlist = <String>{};
  final TextEditingController _bucketInput = new TextEditingController();
  HomePageArguments _arg;
  TenantUser _tenantUser;
  UserBuckets _userBuckets;
  SharedBuckets _sharedBuckets;
  Dio _dio;
  //returns result of Get request in json format

  Future<bool> _getBucketAcl(String bucketName) async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['Accept'] = 'application/json';
      Response response =
          await this._dio.get('/api/v1/s3/$bucketName', options: rqop);
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Bucket ACL Success");
        if (response.data['grants'].length > 1) {
          debugPrint("$bucketName is shared");
          return true;
        } else {
          debugPrint("$bucketName is private");
        }
        return false;
      } else {
        debugPrint("Get Bucket ACL Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Bucket ACL Failed");
      return null;
    }
  }

  Future<List<dynamic>> _getBuckets() async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'offset': '0',
        'order': 'lastModified DESC',
        'filter': '',
      });
      rqop.headers['Accept'] = 'application/json';
      Response response = await this._dio.get('/api/v1/s3', options: rqop);
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Buckets Success");
        var buckets = response.data['buckets'];
        Map<String, bool> bucketList = buckets == null
            ? new Map<String, bool>()
            : new Map.fromIterable(
                buckets,
                key: (item) => item['name'],
                value: (item) => true,
              );
        print("bucketList is ${bucketList.isNotEmpty}");
        if (bucketList.isNotEmpty) {
          for (var key in bucketList.keys) {
            bool shared = await _getBucketAcl(key);
            bucketList[key] = shared;
          }
        }

        List<dynamic> result = new List();
        result.add(response.data);
        result.add(bucketList);
        return result;
      } else {
        debugPrint("Get Buckets Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Buckets Failed");
      return null;
    }
  }

  Future<Map<String, dynamic>> _getSharedBuckets() async {
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'offset': '0',
        'order': 'lastModified DESC',
        'filter': '',
        'shared': true,
      });
      rqop.headers['Accept'] = 'application/json';
      Response response = await this._dio.get('/api/v1/s3', options: rqop);
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Shared Buckets Success");
        //print(response.data);
        return response.data;
      } else {
        debugPrint("Get Shared Buckets Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Shared Buckets Failed");
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
      Response response = await this._dio.put('/api/v1/s3/$urlBucketName');
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Create Bucket $newBucketName Success");
      } else {
        debugPrint(
            "Create Bucket $newBucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Create Bucket Failed");
    } finally {
      _refreshPressed();
    }
  }

  Future<void> _deleteBucketPressed(String bucketName) async {
    if (bucketName.isEmpty) {
      return;
    }
    try {
      String urlBucketName = Uri.encodeComponent(bucketName);
      Response response = await this._dio.delete('/api/v1/s3/$urlBucketName');
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

  //change the permission of bucket into private
  Future<void> _lockBucketPressed(String bucketName) async {
    if (bucketName.isEmpty) {
      return;
    }
    try {
      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['x-amz-acl'] = 'private';
      String urlBucketName = Uri.encodeComponent(bucketName);
      Response response =
          await this._dio.put('/api/v1/s3/$urlBucketName', options: rqop);
      int returncode = response.statusCode;
      if (returncode == 200) {
        debugPrint("Lock Bucket $bucketName Success");
      } else {
        debugPrint(
            "Lock Bucket $bucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Lock Bucket $bucketName Failed");
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
            Text(bucketName),
            _getSharedIcon(shared),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/bucket',
            arguments: BucketPageArguments(
                this._usertoken, bucketName, this._tenantUser),
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
                case ActOnBucket.ACL:
                  {
                    if (shared) {
                      _lockBucketPressed(bucketName);
                    } else {
                      _shareBucketPressed(bucketName);
                    }
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
            PopupMenuItem<ActOnBucket>(
              value: ActOnBucket.ACL,
              child: shared ? Text("Make Private") : Text("Make Public"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedRow(int index) {
    //Each row is a card
    String bucketName = this._sharedlist.elementAt(index);
    //Whether the bucket is currently shared or locked
    //bool Shared = false;
    return Card(
      child: ListTile(
        title: Text(bucketName),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/bucket',
            arguments: BucketPageArguments(
                this._usertoken, bucketName, this._tenantUser),
          );
        },
        trailing: PopupMenuButton<ActOnBucket>(
          // choose actions in pop menu buttom
          onSelected: (ActOnBucket result) {
            setState(() {
              switch (result) {
                case ActOnBucket.empty:
                  {
                    _clearBucketPressed(bucketName);
                    return;
                  }
                default:
                  {
                    return;
                  }
              }
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<ActOnBucket>>[
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
                    return SnackBar(
                      content:
                          Text('Exception happens and Get Buckets Failed!'),
                      duration: Duration(seconds: 1),
                    );
                  else {
                    this._userBuckets = UserBuckets.fromJson(
                        snapshot.data[0], snapshot.data[1]);
                    //if their is no bucket
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

  Widget _buildSharedList() {
    debugPrint("Running _buildSharedList");
    return Center(
        //user FutureBuilder to handle future func in Widgets
        child: FutureBuilder(
            future: _getSharedBuckets(),
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
                      content:
                          Text('Exception happens and Get Buckets Failed!'),
                      duration: Duration(seconds: 1),
                    );
                  else {
                    this._sharedBuckets = SharedBuckets.fromJson(snapshot.data);
                    //if their is no bucket
                    if (this._sharedBuckets.bucketList.isNotEmpty) {
                      debugPrint(
                          'There are ${this._sharedBuckets.bucketList.length} shared buckets');
                      this._sharedBuckets.bucketList.forEach(
                          (String k, String v) => this._sharedlist.add(k));
                      return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: this._sharedlist.length,
                          itemBuilder: (context, i) {
                            //Only shows the bucket name, further action will be completed soon
                            return _buildSharedRow(i);
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
    this._usertoken = this._arg.userToken;
    this._tenantUser = this._arg.tenantUser;
    var option = this._arg.options;
    option.headers['x-vcloud-authorization'] = this._usertoken;
    this._dio = Dio(option);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            new IconButton(
              icon: const Icon(Icons.file_download),
              color: Color.fromARGB(150, 0, 0, 0),
              tooltip: 'Download List',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/download',
                  arguments: DownloadPageArguments(),
                );
              },
            )
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text('My buckets'),
              ),
              Tab(
                child: Text('Shared buckets'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildList(),
            _buildSharedList(),
          ],
        ),
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
      ),
    );
  }
}
