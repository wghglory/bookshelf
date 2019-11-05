import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:bookshelf/tools.dart';

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
              setState(() {});
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
                    debugPrint('There are ${_bucket.objectList.length} Objects');
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
            leading: new IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () {
                  return new Placeholder();
                }),
            title: Text("${this._bucketName}"),
            ),
        body: _buildList());
  }
}
