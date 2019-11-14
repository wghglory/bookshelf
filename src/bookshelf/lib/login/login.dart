import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:bookshelf/tools.dart';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';

List<String> CLOUDOPTIONS = [
  'vOSE',
  'AWS',
];

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController _userTokenFilter;
  TextEditingController _pwdTokenFilter;
  final PageArguments _args = new PageArguments();
  FocusNode _userNode = FocusNode();
  FocusNode _pwdNode = FocusNode();
  TenantUser _tenantUser;
  String _logintoken = '';
  String _userNameToken = '';
  String _passwordtoken = '';
  int _returncode = 0;
  bool isKeyboard = false;
  String sourceCloud = CLOUDOPTIONS[0];
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

  void _userTokenListen() {
    this._userNameToken = this._userTokenFilter.text;
  }

  void _pwdTokenListen() {
    this._passwordtoken = this._pwdTokenFilter.text;
  }

  _LoginPageState() {
    _userTokenFilter = TextEditingController();
    _pwdTokenFilter = TextEditingController();
    this._userTokenFilter.addListener(_userTokenListen);
    this._pwdTokenFilter.addListener(_pwdTokenListen);
    KeyboardVisibilityNotification().addNewListener(onChange: (bool visible) {
      setState(() {
        isKeyboard = visible;
      });
    });
  }

  Widget _buildTextfield(BuildContext context) {
    return new Container(
      width: ScreenUtil().setWidth(700),
      height: ScreenUtil().setHeight(600),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          new TextField(
            controller: this._userTokenFilter,
            focusNode: this._userNode,
            decoration: InputDecoration(
              icon: Icon(Icons.supervisor_account),
              hintText: 'e.g. boning',
              hintStyle: Theme.of(context).textTheme.body1,
              labelText: 'Account',
              labelStyle: Theme.of(context).textTheme.body1,
            ),
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(fontSize: ScreenUtil().setSp(48)),
            cursorColor: Color.fromARGB(255, 197, 207, 255),
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(this._pwdNode);
            },
          ),
          new TextField(
            controller: this._pwdTokenFilter,
            focusNode: this._pwdNode,
            decoration: InputDecoration(
              icon: Icon(Icons.lock_outline),
              hintText: 'e.g. 123vbg',
              hintStyle: Theme.of(context).textTheme.body1,
              labelText: 'Password',
              labelStyle: Theme.of(context).textTheme.body1,
            ),
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(fontSize: ScreenUtil().setSp(48)),
            obscureText: true,
            cursorColor: Color.fromARGB(255, 197, 207, 255),
            //keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.send,
            onEditingComplete: () async {
              await _loginPressed();
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getLogin() async {
    this._userTokenFilter.clearComposing();
    this._pwdTokenFilter.clearComposing();
    this._logintoken = this._userNameToken + ':' + this._passwordtoken;
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

  Future<void> _loginPressed() async {
    var jsondata = await _getLogin();
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
          this._userTokenFilter.clear(); // clear textfield after routing
          this._pwdTokenFilter.clear();
          this._returncode = 0;
          this._logintoken = '';
        });
      } else {
        //show failure snackbar
        this._scaffoldKey.currentState.showSnackBar(failBar);
      }
    });
  }

  Widget _buildButton(BuildContext context) {
    return new Container(
      width: ScreenUtil().setWidth(600),
      child: new RaisedButton(
          child: new Text(
            "Login",
            style: Theme.of(context)
                .textTheme
                .button
                .copyWith(fontSize: ScreenUtil().setSp(48)),
          ),
          onPressed: () async {
            await _loginPressed();
          }),
    );
  }

  List<DropdownMenuItem> buildDropDownItems(List<String> choices) {
    final items = <DropdownMenuItem>[];
    for (int i = 0; i < choices.length; i++) {
      items.add(
        DropdownMenuItem(
          child: Text(
            choices[i],
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(fontSize: ScreenUtil().setSp(36)),
          ),
          value: choices[i],
        ),
      );
    }
    return items;
  }

  Widget _buildSourceSelection(BuildContext context) {
    return Visibility(
      visible: !isKeyboard,
      maintainSize: false,
      child: Container(
        padding: new EdgeInsets.fromLTRB(
            0, ScreenUtil().setSp(20), 0, ScreenUtil().setSp(10)),
        child: DropdownButton(
          value: sourceCloud,
          onChanged: (newSource) {
            setState(() {
              sourceCloud = newSource;
            });
          },
          items: buildDropDownItems(CLOUDOPTIONS),
        ),
      ),
    );
  }

  Widget _buildPasswordBut(BuildContext context) {
    return Visibility(
      visible: !isKeyboard,
      maintainSize: false,
      child: Container(
        padding: new EdgeInsets.fromLTRB(0, 0, 0, ScreenUtil().setSp(10)),
        child: OutlineButton(
          onPressed: () {},
          child: Text(
            'Forget your password?',
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(fontSize: ScreenUtil().setSp(36)),
          ),
          highlightedBorderColor: Color.fromARGB(255, 197, 207, 255),
          //padding: new EdgeInsets.fromLTRB(0, 0, 0, 0),
        ),
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
          style: Theme.of(context)
              .textTheme
              .title
              .copyWith(fontSize: ScreenUtil().setSp(60)),
        ),
      ),
      body: new Column(
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(children: <Widget>[
              Center(child: _buildTextfield(context)),
              Center(child: _buildButton(context)),
              Center(
                child: _buildSourceSelection(context),
              )
            ]),
            Expanded(
              child: Center(child: _buildPasswordBut(context)),
            ),
          ]),
    );
  }
}
