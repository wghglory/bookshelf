import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:bookshelf/tools.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextEditingController _tokenFilter = new TextEditingController();
  final PageArguments _args = new PageArguments();
  String _logintoken = '';
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

  void _tokenListen() {
    if (this._tokenFilter.text.isEmpty) {
      this._logintoken = "";
    } else {
      this._logintoken = this._tokenFilter.text;
    }
  }

  _LoginPageState() {
    this._tokenFilter.addListener(_tokenListen);
  }

  Widget _buildTextfield() {
    return new Container(
        child: new TextField(
      controller: this._tokenFilter,
      decoration: const InputDecoration(
        icon: Icon(Icons.account_box),
        hintText: 'username@jiaotong:password',
        labelText: 'Account ',
      ),
    ));
  }

  Future<void> _loginPressed() async {
    debugPrint(this._logintoken);
    this._tokenFilter.clearComposing();
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
      } else {
        debugPrint("Login Failed");
      }
    } catch (e) {
      debugPrint("Exception: $e happens and Login Failed");
      return;
    }
  }

  Widget _buildButton(BuildContext context) {
    return new Container(
      child: new RaisedButton(
          child: new Text("Login"),
          onPressed: () async {
            assert(this._logintoken.isEmpty != true);
            await _loginPressed();
            setState(() {
              if (this._returncode == 200) {
                //route to home page
                Navigator.pushNamed(
                  context,
                  '/home',
                  arguments: HomePageArguments(this._logintoken),
                ).then((value){
                  this._tokenFilter.clear(); // clear textfield after routing
                  this._returncode = 0;
                  this._logintoken='';
                });
              } else {
                //show failure snackbar
                this._scaffoldKey.currentState.showSnackBar(failBar);
              }
            });
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint(this._logintoken);
    return Scaffold(
      key: this._scaffoldKey,
      appBar: AppBar(
        title: Text('Bookshelf Login'),
      ),
      body: new Column(
        children: <Widget>[
          _buildTextfield(),
          _buildButton(context),
        ],
      ),
    );
  }
}
