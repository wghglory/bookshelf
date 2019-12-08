import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
//import 'package:xml2json/xml2json.dart';
import 'package:bookshelf/tools.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

//may add further action on bucket in the future
enum ACL { shared, private }
enum ActOnBucket { delete, empty, ACL, userlist }

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
        if (response.data['grants'].length > 1) {
          print("$bucketName is shared");
          return true;
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
      this._sharedlist.clear();
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
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: Text('Create bucket failed!'),
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
            "Create Bucket $newBucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Create bucket failed!'),
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Share failed!'),
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
            "Share Bucket $bucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Share failed!'),
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Lock failed!'),
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
            "Lock Bucket $bucketName Failed and Return code is $returncode");
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Lock failed!'),
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
      debugPrint("Exception: $e happens and Lock Bucket $bucketName Failed");
    } finally {
      _refreshPressed();
    }
  }

  //get the response data of bucket acl
  Future<Map<String, dynamic>> _getBucketAclData(String bucketName) async {
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
        return response.data;
      } else {
        debugPrint("Get Bucket ACL Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Bucket ACL Failed");
      return null;
    }
  }

  //set the share bucket read & write acl to a single user
  Future<void> _userOptionPressed(
      String bucketName, String userName, String userId) async {
    try {
      var currentacl = await _getBucketAclData(bucketName);
      var newgrantwrite = {
        "grantee": {"id": userId, "displayName": userName},
        "permission": "WRITE"
      };
      var newgrantread = {
        "grantee": {"id": userId, "displayName": userName},
        "permission": "READ"
      };
      currentacl['grants'].add(newgrantwrite);
      currentacl['grants'].add(newgrantread);

      RequestOptions rqop = new RequestOptions();
      rqop.queryParameters = new Map.from({
        'acl': '',
      });
      rqop.headers['Content-Type'] = 'application/json';
      String urlBucketName = Uri.encodeComponent(bucketName);
      Response response = await this
          ._dio
          .put('/api/v1/s3/$urlBucketName', options: rqop, data: currentacl);
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
        debugPrint("Share Bucket $bucketName to user $userName Success");
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
            "Share Bucket $bucketName to user $userName and Return code is $returncode");
      }
    } catch (e) {
      print("------------------------------------------");
      await showDialog(
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
          "Exception: $e happens and share Bucket to user $userName $bucketName Failed");
    } finally {
      _refreshPressed();
    }
  }

  //show the user list for sharing
  Future<void> _userListPressed(String bucketName) async {
    if (bucketName.isEmpty) {
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
      String urlBucketName = Uri.encodeComponent(bucketName);
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
                _userOptionPressed(bucketName, m, n);
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

  Widget _buildColumn(int index) {
    // each column is a bucket
    String bucketName = this._bucketlist.elementAt(index);
    bool shared = this._userBuckets.bucketList[bucketName];
    //Whether the bucket is currently shared or locked
    String aclType = 'Share';
    IconData iconType = Icons.share;
    if (shared == true) {
      aclType = 'Lock';
      iconType = Icons.lock;
    }
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/bucket',
          arguments: BucketPageArguments(
              this._usertoken, bucketName, this._tenantUser),
        );
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
                                  Navigator.of(context).pop(ActOnBucket.delete);
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
                                icon: Icon(Icons.hourglass_empty,
                                    size: ScreenUtil().setWidth(80)),
                                color: Color.fromARGB(150, 0, 0, 0),
                                onPressed: () {
                                  Navigator.of(context).pop(ActOnBucket.empty);
                                })),
                        new Text(
                          'Empty',
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
                                icon: Icon(iconType,
                                    size: ScreenUtil().setWidth(80)),
                                color: Color.fromARGB(150, 0, 0, 0),
                                onPressed: () {
                                  Navigator.of(context).pop(ActOnBucket.ACL);
                                })),
                        new Text(
                          aclType,
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
                                icon: Icon(Icons.person,
                                    size: ScreenUtil().setWidth(80)),
                                color: Color.fromARGB(150, 0, 0, 0),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(ActOnBucket.userlist);
                                })),
                        new Text(
                          'Share to',
                          style: Theme.of(context)
                              .textTheme
                              .body1
                              .copyWith(fontSize: ScreenUtil().setSp(30)),
                        )
                      ]),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  ));
            });
        switch (selected) {
          case ActOnBucket.delete:
            {
              await _deleteBucketPressed(bucketName);
              return;
            }
          case ActOnBucket.empty:
            {
              await _clearBucketPressed(bucketName);
              return;
            }
          case ActOnBucket.ACL:
            {
              if (shared == false) {
                await _shareBucketPressed(bucketName);
              } else {
                await _lockBucketPressed(bucketName);
              }
              return;
            }
          case ActOnBucket.userlist:
            {
              await _userListPressed(bucketName);
              return;
            }
        }
      },
      // bottom sheet
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        verticalDirection: VerticalDirection.down,
        children: <Widget>[
          Image.asset(
            'assets/images/bucket_cover.jpg',
            height: ScreenUtil().setHeight(360),
            width: ScreenUtil().setHeight(360),
          ),
          new Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _getSharedIcon(shared),
                  Text(
                    bucketName,
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

/*
  Widget _buildSharedRow(int index) {
    //Each row is a card
    String bucketName = this._sharedlist.elementAt(index);
    //Whether the bucket is currently shared or locked
    //bool Shared = false;
    return Card(
      child: ListTile(
        title: Text(bucketName, style: Theme.of(context).textTheme.body1),
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
  */

  Widget _buildSharedColumn(int index) {
    // each column is a bucket
    String bucketName = this._sharedlist.elementAt(index);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/bucket',
          arguments: BucketPageArguments(
              this._usertoken, bucketName, this._tenantUser),
        );
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
                                icon: Icon(Icons.hourglass_empty,
                                    size: ScreenUtil().setWidth(80)),
                                color: Color.fromARGB(150, 0, 0, 0),
                                onPressed: () {
                                  Navigator.of(context).pop(ActOnBucket.empty);
                                })),
                        new Text(
                          'Empty',
                          style: Theme.of(context)
                              .textTheme
                              .body1
                              .copyWith(fontSize: ScreenUtil().setSp(30)),
                        )
                      ]),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  ));
            });
        switch (selected) {
          case ActOnBucket.empty:
            {
              await _clearBucketPressed(bucketName);
              return;
            }
        }
      },
      // bottom sheet
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        verticalDirection: VerticalDirection.down,
        children: <Widget>[
          Image.asset(
            'assets/images/bucket_cover.jpg',
            height: ScreenUtil().setHeight(360),
            width: ScreenUtil().setHeight(360),
          ),
          new Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    bucketName,
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
                    this._userBuckets = UserBuckets.fromJson(
                        snapshot.data[0], snapshot.data[1]);
                    //if there is no bucket
                    if (this._userBuckets.bucketList.isNotEmpty) {
                      debugPrint(
                          'There are ${this._userBuckets.bucketList.length} buckets');
                      this._userBuckets.bucketList.forEach((String k, bool v) {
                        this._bucketlist.add(k);
                      });
                      /*
                      return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: this._bucketlist.length,
                          itemBuilder: (context, i) {
                            //Only shows the bucket name, further action will be completed soon
                            return _buildColumn(i);
                          });
                      */
                      return GridView.count(
                        primary: false,
                        padding: const EdgeInsets.all(20),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        crossAxisCount: 2,
                        children:
                            List.generate(this._bucketlist.length, (index) {
                          return _buildColumn(index);
                        }),
                      );
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
                    this._sharedBuckets = SharedBuckets.fromJson(snapshot.data);
                    //if their is no bucket
                    if (this._sharedBuckets.bucketList.isNotEmpty) {
                      debugPrint(
                          'There are ${this._sharedBuckets.bucketList.length} shared buckets');
                      this._sharedBuckets.bucketList.forEach(
                          (String k, String v) => this._sharedlist.add(k));
                      return GridView.count(
                        primary: false,
                        padding: const EdgeInsets.all(20),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        crossAxisCount: 2,
                        children:
                            List.generate(this._sharedlist.length, (index) {
                          return _buildSharedColumn(index);
                        }),
                      );
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
          bottom: TabBar(
            labelColor: Colors.black,
            tabs: [
              Tab(
                child: Text('My buckets',
                    style: Theme.of(context).textTheme.body1),
              ),
              Tab(
                child: Text('Shared buckets',
                    style: Theme.of(context).textTheme.body1),
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
      ),
    );
  }
}
