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
  final Map<String, String> bucketList;

  UserBuckets({this.id, this.username, this.bucketList});

  factory UserBuckets.fromJson(Map<String, dynamic> json) {
    var user = json['ListAllMyBucketsResult']['Owner'];
    var buckets = json['ListAllMyBucketsResult']['Buckets'];
    return UserBuckets(
      id: user['ID'],
      username: user['DisplayName'],
      bucketList: buckets == null // if no bucket
          ? new Map<String, String>()
          : buckets['Bucket'].runtimeType !=
                  List<dynamic>().runtimeType // if only one bucket
              ? new Map.of({
                  buckets['Bucket']['Name']: buckets['Bucket']['CreationDate']
                })
              : new Map.fromIterable(
                  buckets['Bucket'],
                  key: (item) => item['Name'],
                  value: (item) => item['CreationDate'],
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

  BucketPageArguments(this._usertoken, this._bucketname);

  String get userToken {
    return this._usertoken;
  }

  String get bucketName {
    return this._bucketname;
  }
}
