import 'package:dio/dio.dart';

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
  HomePageArguments(this._usertoken);
  String get userToken {
    return this._usertoken;
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
