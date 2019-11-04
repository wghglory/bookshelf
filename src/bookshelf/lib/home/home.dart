import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:bookshelf/tools.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: new IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
              onPressed: () {
                return new Placeholder();
              }),
          title: Text("My Bookshelf"),
        ),
        body: new Container(),
    );
  }
}