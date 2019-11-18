import 'package:bookshelf/download/download.dart';
import 'package:dio/dio.dart';

class TenantUser {
  final String id;
  final String name;
  final String fullName;
  final bool active;
  final String tenantId;
  final String tenantName;
  final int usedBytes;
  final int bucketCount;
  final int objectCount;
  final String lastModifiedDate;

  TenantUser(
      {this.id,
      this.name,
      this.fullName,
      this.active,
      this.tenantId,
      this.tenantName,
      this.usedBytes,
      this.bucketCount,
      this.objectCount,
      this.lastModifiedDate});

  factory TenantUser.fromJson(Map<String, dynamic> json) {
    return TenantUser(
      id: json['id'],
      name: json['name'],
      fullName: json['fullName'],
      active: json['active'] == 'true',
      tenantId: json['tenant']['id'],
      tenantName: json['tenant']['name'],
      usedBytes: json['tenant']['usedBytes'],
      bucketCount: json['tenant']['bucketCount'],
      objectCount: json['tenant']['objectCount'],
      lastModifiedDate: json['tenant']['lastModifiedDate'],
    );
  }
}

class UserBuckets {
  final String id;
  final String username;
  final Map<String, bool> bucketList;

  UserBuckets({this.id, this.username, this.bucketList});

  factory UserBuckets.fromJson(
      Map<String, dynamic> json, Map<String, bool> acl) {
    var user = json['owner'];
    var buckets = json['buckets'];
    return UserBuckets(
      id: user['id'],
      username: user['displayName'],
      bucketList: buckets == null // if no bucket
          ? new Map<String, bool>()
          : new Map.fromIterable(
              buckets,
              key: (item) => item['name'],
              value: (item) => acl[item['name']],
            ),
    );
  }
}

class SharedBuckets {
  final String id;
  final String username;
  final Map<String, String> bucketList;

  SharedBuckets({this.id, this.username, this.bucketList});

  factory SharedBuckets.fromJson(Map<String, dynamic> json) {
    var user = json['owner'];
    var buckets = json['buckets'];
    return SharedBuckets(
      id: user['id'],
      username: user['displayName'],
      bucketList: buckets == null // if no bucket
          ? new Map<String, String>()
          : new Map.fromIterable(
              buckets,
              key: (item) => item['name'],
              value: (item) => item['creationDate'],
            ),
    );
  }
}

class Object {
  final bool isFolder;
  final String etag;
  final int size;
  final String lastModified;
  final bool shared;
  final String contentType;
  Object(this.isFolder, this.etag, this.size, this.lastModified, this.shared,
      this.contentType);
}

class Bucket {
  final int keyCount;
  final String name;
  final String path;
  final int usedBytes;
  final String bucketType;
  final String ownerName;
  final String ownerId;
  final Map<String, Object> objectList;

  Bucket({
    this.name,
    this.keyCount,
    this.objectList,
    this.path,
    this.usedBytes,
    this.bucketType,
    this.ownerName,
    this.ownerId,
  });

  factory Bucket.fromJson(Map<String, dynamic> json, Map<String, bool> acl) {
    var count = json['keyCount'];
    var content = json['objectBrief'];
    return Bucket(
      name: json['name'],
      keyCount: count,
      path: json['path'],
      usedBytes: json['usedBytes'],
      bucketType: json['bucketType'],
      ownerName: json['owner']['displayName'],
      ownerId: json['owner']['id'],
      objectList: count == 0 // if no bucket
          ? new Map<String, Object>()
          : new Map<String, Object>.fromIterable(
              content,
              key: (item) => item['key'],
              value: (item) => new Object(
                  item['folder'] == 'true',
                  item['etag'],
                  item['size'],
                  item['lastModified'],
                  acl[item['key']],
                  item['contentType']),
            ),
    );
  }
}

class PageArguments {
  var options = BaseOptions(
      baseUrl: "http://yhzzzz.natapp1.cc",
      connectTimeout: 5000,
      receiveTimeout: 100000,
      headers: {
        'Host': 'yhzzzz.natapp1.cc',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Encoding': 'gzip, deflate',
      }
      // 5s
      );
}

class HomePageArguments extends PageArguments {
  final String _usertoken;
  final TenantUser _tenantUser;
  HomePageArguments(this._usertoken, this._tenantUser);
  String get userToken {
    return this._usertoken;
  }

  TenantUser get tenantUser {
    return this._tenantUser;
  }
}

class BucketPageArguments extends PageArguments {
  final String _usertoken;
  final String _bucketname;
  final TenantUser _tenantUser;

  BucketPageArguments(this._usertoken, this._bucketname, this._tenantUser);

  String get userToken {
    return this._usertoken;
  }

  String get bucketName {
    return this._bucketname;
  }

  TenantUser get tenantUser {
    return this._tenantUser;
  }
}

class PdfPageArguments extends PageArguments {
  final String _usertoken;
  final String _bucketname;
  final String _objectname;
  final String _pathName;

  PdfPageArguments(
      this._usertoken, this._bucketname, this._objectname, this._pathName);

  String get userToken {
    return this._usertoken;
  }

  String get bucketName {
    return this._bucketname;
  }

  String get objectName {
    return this._objectname;
  }

  String get pathName {
    return this._pathName;
  }
}

class TxtPageArguments extends PageArguments {
  final String _usertoken;
  final String _bucketname;
  final String _objectname;
  final String _pathName;

  TxtPageArguments(
      this._usertoken, this._bucketname, this._objectname, this._pathName);

  String get userToken {
    return this._usertoken;
  }

  String get bucketName {
    return this._bucketname;
  }

  String get objectName {
    return this._objectname;
  }

  String get pathName {
    return this._pathName;
  }
}

class DownloadPageArguments extends PageArguments{
  final String _usertoken;
  
  DownloadPageArguments(this._usertoken);
  String get userToken {
    return this._usertoken;
  }
}