import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:xml2json/xml2json.dart';
import 'dart:convert';
import 'package:bookshelf/tools.dart';

//enum ActOnBucket { delete }

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _usertoken = '';
  final Set<String> _bucketlist = <String>{};
  final TextEditingController _bucketInput = new TextEditingController();
  HomePageArguments _arg;
  TenantUser _tenantUser;
  UserBuckets _userBuckets;
  Dio _dio;
  //returns result of Get request in json format

  Future<String> _getBuckets() async {
    try {
      this._dio.options.queryParameters = new Map.from({
        'offset': '0',
        'order': 'lastModified DESC',
        'filter': '',
      });
      Response response = await this._dio.get('/api/v1/s3');
      this._dio.options.queryParameters.clear();
      int returncode = response.statusCode;
      //return code 200 is success
      if (returncode == 200) {
        debugPrint("Get Buckets Success");
        final Xml2Json parser = Xml2Json();
        parser.parse(response.data);
        String json = parser.toParker();
        debugPrint(json);
        return json;
      } else {
        debugPrint("Get Buckets Failed and return code is $returncode");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Get Buckets Failed");
      return null;
    }
  }

  void _refreshPressed() {
    setState(() {
      this._bucketlist.clear();
    });
  }

  //send add request and refresh
  Future<void> _addBucketPressed(String newbucket) async {
    if (newbucket == '') {
      return;
    }
    try {
      Response response = await this._dio.put('/api/v1/s3/$newbucket');
      int returncode = response.statusCode;
      if (returncode == 200) {
        print("Create Bucket$newbucket Success");
      } else {
        print("Create Bucket$newbucket Failed and Return code is $returncode");
      }
    } catch (e) {
      print("Exception: $e happens and Create Bucket Failed");
    } finally {
      _refreshPressed();
    }
  }

  //each row is a card representing a bucket
  Widget _buildRow(int index) {
    //Each row is a card
    String bucketName = this._bucketlist.elementAt(index);
    return Card(
      child: ListTile(
        title: Text(bucketName),
        onTap: () {},
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
                    Map<String, dynamic> jsondata = jsonDecode(snapshot.data);
                    this._userBuckets = UserBuckets.fromJson(jsondata);
                    //if their is no bucket
                    if (this._userBuckets.bucketList.isNotEmpty) {
                      debugPrint(
                          'There are ${this._userBuckets.bucketList.length} buckets');
                      this._userBuckets.bucketList.forEach(
                          (String k, String v) => this._bucketlist.add(k));
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
    this._usertoken = this._arg.userToken;
    this._tenantUser=this._arg.tenantUser;
    var option = this._arg.options;
    option.headers['x-vcloud-authorization'] = this._usertoken;
    this._dio = Dio(option);

    return Scaffold(
      appBar: AppBar(
        title: Text("My Bookshelf"),
        actions: <Widget>[
          //Add Bucket Button
          new IconButton(
              icon: const Icon(Icons.add_box),
              tooltip: 'Add Bucket',
              onPressed: () async {
                String newbucket = '';
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
                          child: new Text('OK'),
                          onPressed: () {
                            newbucket = this._bucketInput.text.isEmpty
                                ? ''
                                : this._bucketInput.text;
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  },
                );
                await _addBucketPressed(newbucket);
              }),
          //Update Bucket List Button
          new IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh List',
              onPressed: () {
                _refreshPressed();
              }),
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
                            color: Colors.white,
                            height: 4,
                            fontSize: 18,
                            fontStyle:FontStyle.normal),
                      ),
                    ]),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('Profile'),
                    onTap: () {
                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text('Setting'),
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
