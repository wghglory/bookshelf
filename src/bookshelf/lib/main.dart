import 'package:flutter/material.dart';
import 'package:bookshelf/login/login.dart';
import 'package:bookshelf/home/home.dart';

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
        //'/bucket':(context) => BucketPage(),
      },
      
    );
  }
}