import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:bookshelf/tools.dart';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController _tokenFilter1;
  TextEditingController _tokenFilter2;
  final PageArguments _args = new PageArguments();
  TenantUser _tenantUser;
  String _logintoken = '';
  String _usertokenname = '';
  String _passwordtoken = '';
  int _returncode = 0;
  /*
  final successBar = SnackBar(
    content: Text('Login Success!'),
    duration: Duration(seconds: 1),
  );*/
  final failBar = SnackBar(
    content: Text('Login Failed!'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () {
        // some action can be added to undo the change.
      },
    ),
  );
  
  void _tokenListen1() {
      this._usertokenname = this._tokenFilter1.text;
      debugPrint(this._usertokenname);
  }

  void _tokenListen2() {
      this._passwordtoken = this._tokenFilter2.text;
  }

  _LoginPageState() {
    _tokenFilter1 = TextEditingController();
    _tokenFilter2 = TextEditingController();
    this._tokenFilter1.addListener(_tokenListen1);
    this._tokenFilter2.addListener(_tokenListen2);
  }

  Widget _buildTextfield(BuildContext context) {
    return new Container(
      width: ScreenUtil().setWidth(700),
      height: ScreenUtil().setHeight(600),
      child:new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          new TextField(
            controller: this._tokenFilter1,
            decoration: InputDecoration(
              icon: Icon(Icons.supervisor_account),
              hintText: 'e.g. boning',
              hintStyle: Theme.of(context).textTheme.body1,
              labelText: "Account",
              labelStyle: Theme.of(context).textTheme.body1,
            ),
            style: Theme.of(context).textTheme.body1.copyWith(fontSize: ScreenUtil().setSp(48)),
            cursorColor: Color.fromARGB(255, 197, 207, 255),
            //autofocus: true,
          ),
          new TextField(
            controller: this._tokenFilter2,
            decoration: InputDecoration(
              icon: Icon(Icons.lock_outline),
              hintText: 'e.g. 123vbg',
              hintStyle: Theme.of(context).textTheme.body1,
              labelText: 'Password ',
              labelStyle: Theme.of(context).textTheme.body1,
            ),
            style: Theme.of(context).textTheme.body1.copyWith(fontSize: ScreenUtil().setSp(48)),
            obscureText: true,
            cursorColor: Color.fromARGB(255, 197, 207, 255),
            //autofocus: true,
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loginPressed() async {
    this._tokenFilter1.clearComposing();
    this._tokenFilter2.clearComposing();
    this._logintoken = this._usertokenname+'@jiaotong:'+this._passwordtoken;
    debugPrint(this._usertokenname);
    debugPrint(this._logintoken);
    
    //use dio package to pull and get http request
    var option = this._args.options;
    //add vcloud authorization header
    option.headers['x-vcloud-authorization'] = this._logintoken;
    var dio = new Dio(option);
    try {
      Response response = await dio.get('/api/v1/admin/current-user');
      this._returncode = response.statusCode;
      //return code 200 is success
      if (this._returncode == 200) {
        debugPrint('Response code is $_returncode');
        debugPrint("Login Success");
        print(response.data);
        return response.data;
      } else {
        debugPrint("Login Failed");
        return null;
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Login Failed");
      return null;
    }
  }

  Widget _buildButton(BuildContext context) {
    return new Container(
      width: ScreenUtil().setWidth(600),
      child: new RaisedButton(
          child: new Text(
            "Login",
            style: Theme.of(context).textTheme.button.copyWith(fontSize: ScreenUtil().setSp(48)),
          ),
          onPressed: () async {
            var jsondata = await _loginPressed();
            assert(this._logintoken.isEmpty != true);
            setState(() {
              if (this._returncode == 200) {
                assert(json != null);
                //parse TenantUser info
                this._tenantUser = TenantUser.fromJson(jsondata);
                //route to home page
                Navigator.pushNamed(
                  context,
                  '/home',
                  arguments: HomePageArguments(this._logintoken, this._tenantUser),
                ).then((value) {
                  this._tokenFilter1.clear(); // clear textfield after routing
                  this._tokenFilter2.clear();
                  this._returncode = 0;
                  this._logintoken = '';
                });
              } else {
                //show failure snackbar
                this._scaffoldKey.currentState.showSnackBar(failBar);
              }
            });
          }),
    );
  }

  void _tobedone(){
    debugPrint('tbd');
  }

  Widget _buildPasswordBut(BuildContext context) {
    return Container(
      padding: new EdgeInsets.fromLTRB(0, 0, 0, ScreenUtil().setSp(10)),
      
      child: OutlineButton(
        onPressed: _tobedone,
        child: Text(
          'Forget your password?',
          style: Theme.of(context).textTheme.body1.copyWith(fontSize: ScreenUtil().setSp(36)),
        ),
        highlightedBorderColor: Color.fromARGB(255, 197, 207, 255),
        //padding: new EdgeInsets.fromLTRB(0, 0, 0, 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint(this._logintoken);
    ScreenUtil.instance = ScreenUtil(width: 1080, height: 1920)..init(context);
    return Scaffold(
      key: this._scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Bookshelf',
          style: Theme.of(context).textTheme.title.copyWith(fontSize: ScreenUtil().setSp(60)),
        ),
      ),
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(children: <Widget>[
            Center(child: _buildTextfield(context)),
            Center(child: _buildButton(context)),
          ]
          ),
          Center(child: _buildPasswordBut(context))
        ]
      ),

    );
  }
}