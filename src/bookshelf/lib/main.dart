import 'package:flutter/material.dart';
import 'package:bookshelf/login/login.dart';
import 'package:bookshelf/home/home.dart';
import 'package:bookshelf/bucket/bucket.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bookshelf',
      theme: new ThemeData.light(),
      initialRoute: '/',
      
      routes: {
        // When navigating to the "/" route, build the LoginPage widget.
        '/': (context) => LoginPage(),
        // When navigating to the "/home" route, build the HomePage widget.
        '/home': (context) => HomePage(),
        // When navigating to the "/Bucket" route, build the BucketPage widget.
        '/bucket':(context) => BucketPage(),
      },
      
    );
  }
}