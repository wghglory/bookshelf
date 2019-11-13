import 'package:bookshelf/reader/pdfPage.dart';
import 'package:flutter/material.dart';
import 'package:bookshelf/login/login.dart';
import 'package:bookshelf/home/home.dart';
import 'package:bookshelf/bucket/bucket.dart';
//import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  
  Widget build(BuildContext context) {
    // ScreenUtil.instance = ScreenUtil(width: 1080, height: 1920)..init(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bookshelf',
      theme: new ThemeData(
        accentColor: Color.fromARGB(255, 197, 207, 255),
        primaryColor: Color.fromARGB(255, 197, 207, 255),
        buttonColor: Color.fromARGB(255, 197, 207, 255),
        appBarTheme: new AppBarTheme(
          color: Color.fromARGB(255, 197, 207, 255)
        ),
        textTheme: new TextTheme(
          title: new TextStyle(
            fontFamily: 'AgencyFB',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(150, 0, 0, 0),
            //fontSize: ScreenUtil().setSp(60),
          ),
          body1: new TextStyle(
            fontFamily: 'AgencyFB',
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(150, 0, 0, 0),
            //fontSize: ScreenUtil().setSp(48),
          ),
          body2: new TextStyle(
            fontFamily: 'AgencyFB',
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 197, 207, 255),
            //fontSize: ScreenUtil().setSp(48),
          ),
          button: new TextStyle(
            fontFamily: 'AgencyFB',
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(150, 0, 0, 0),
            //fontSize: ScreenUtil().setSp(48),
          )
        )
      ),
      initialRoute: '/',
      
      routes: {
        // When navigating to the "/" route, build the LoginPage widget.
        '/': (context) => LoginPage(),
        // When navigating to the "/home" route, build the HomePage widget.
        '/home': (context) => HomePage(),
        //'/bucket':(context) => BucketPage(),
        '/bucket': (context) => BucketPage(),
        '/pdfViewer':(context) => PdfPage(),
      },
      
    );
  }
}