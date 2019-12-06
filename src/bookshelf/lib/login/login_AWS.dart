import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:bookshelf/tools.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';


enum RegionOptions { HongKong, America_East, America_West, Singapore}

class AWSPage extends StatefulWidget {
  @override
  _AWSPageState createState() => _AWSPageState();
}

class _AWSPageState extends State<AWSPage> {
  TextEditingController _accessKeyFilter;
  TextEditingController _secretKeyFilter;
  String _accessKey = '';
  String _secretKey = '';
  int _returncode = 0;
  bool isKeyboard = false;
  FocusNode _accessNode = FocusNode();
  FocusNode _secretNode = FocusNode();
  String _selectedFilePath = '';
  String _selectedFileName = '';
  FileType _selectedFileType = FileType.CUSTOM;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  var _region = RegionOptions.America_East;
  

  Future<void> _openFileExplorer() async {
    print("Running openFile");
    //use filepicker package to filter pdf file
    if (this._selectedFileType == FileType.CUSTOM) {
      try {
        this._selectedFilePath = await FilePicker.getFilePath(type: FileType.ANY);
      } on PlatformException catch (e) {
        print("Unsupported operation when selecting file" + e.toString());
      }
      if (!mounted) return;
      this._selectedFileName = this._selectedFilePath != null
          ? this._selectedFilePath.split('/').last
          : '...';
    }
  }


  // to be implemented
  Future<bool> _readLocalFile() async {
    bool ifsuccess = false;
    try{
      if (this._selectedFileName == '...'){
        print(ifsuccess);
        return ifsuccess;
      }
      File file = File(this._selectedFilePath);
    }catch (e) {
      debugPrint("Exception: $e happens and Upload File Failed");
    }
    return ifsuccess;
  }



  void _accessKeyListen() {
    this._accessKey = this._accessKeyFilter.text;
  }

  void _secretKeyListen() {
    this._secretKey = this._secretKeyFilter.text;
  }

  _AWSPageState() {
    _accessKeyFilter = TextEditingController();
    _secretKeyFilter = TextEditingController();
    this._accessKeyFilter.addListener(_accessKeyListen);
    this._secretKeyFilter.addListener(_secretKeyListen);
    KeyboardVisibilityNotification().addNewListener(onChange: (bool visible) {
      setState(() {
        isKeyboard = visible;
      });
    });
  }

  Widget _buildTextfield(BuildContext context) {
    return new Container(
      width: ScreenUtil().setWidth(700),
      height: ScreenUtil().setHeight(500),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          new TextField(
            controller: this._accessKeyFilter,
            focusNode: this._accessNode,
            decoration: InputDecoration(
              icon: Icon(Icons.supervisor_account),
              hintText: '',
              hintStyle: Theme.of(context).textTheme.body2,
              labelText: 'Access Key',
              labelStyle: Theme.of(context).textTheme.body1,
            ),
            style: Theme.of(context)
                .textTheme
                .body2
                .copyWith(fontSize: ScreenUtil().setSp(48)),
            cursorColor: Color.fromARGB(255, 170, 202, 255),
            //autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(this._secretNode);
            },
          ),
          new TextField(
            controller: this._secretKeyFilter,
            focusNode: this._secretNode,
            decoration: InputDecoration(
              icon: Icon(Icons.lock_outline),
              hintText: '',
              hintStyle: Theme.of(context).textTheme.body2,
              labelText: 'Secret Key',
              labelStyle: Theme.of(context).textTheme.body1,
            ),
            style: Theme.of(context)
                .textTheme
                .body2
                .copyWith(fontSize: ScreenUtil().setSp(48)),
            obscureText: false,
            cursorColor: Color.fromARGB(255, 170, 202, 255),
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

  Widget _buildReadingFile(BuildContext context) {
    return Visibility(
      visible: !isKeyboard,
      maintainSize: false,
      child: Container(
        padding: new EdgeInsets.fromLTRB(0, ScreenUtil().setSp(300), 0, ScreenUtil().setSp(10)),
        child: OutlineButton(
          onPressed: () async {
            await _openFileExplorer();
          },
          child: new Text(
            "login from local file",
            style: Theme.of(context)
                .textTheme
                .button
                .copyWith(fontSize: ScreenUtil().setSp(36)),
          ),
          highlightedBorderColor: Color.fromARGB(255, 197, 207, 255),
          //padding: new EdgeInsets.fromLTRB(0, 0, 0, 0),
        ),
      ),
    );
  }

  Widget _buildSourceSelection(BuildContext context) {
      return Container(
        padding: new EdgeInsets.fromLTRB(
            0, ScreenUtil().setSp(20), 0, ScreenUtil().setSp(10)),
        child: DropdownButton<RegionOptions>(
          value: this._region,
          onChanged: (newRegion) {
            setState(() {
              this._region = newRegion;
            });
          },
          items: buildDropDownItems(context),
        ),
      );
  }

  List<DropdownMenuItem> buildDropDownItems(BuildContext context) {
    return [
      DropdownMenuItem(
        child: Text(
          "us-east-1",
          style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontSize: ScreenUtil().setSp(36)),
        ),
        value: RegionOptions.America_East,
      ),
      DropdownMenuItem(
        child: Text(
          "ap-east-1",
          style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontSize: ScreenUtil().setSp(36)),
        ),
        value: RegionOptions.HongKong,
      ),
      DropdownMenuItem(
        child: Text(
          "us-west-1",
          style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontSize: ScreenUtil().setSp(36)),
        ),
        value: RegionOptions.America_West,
      ),
      DropdownMenuItem(
        child: Text(
          "ap-southeast-1",
          style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontSize: ScreenUtil().setSp(36)),
        ),
        value: RegionOptions.Singapore,
      ),
    ].toList();
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

  Future<void> _loginPressed() async {
    
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil(width: 1080, height: 1920)..init(context);
    return Scaffold(
      key: this._scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'AWS Login',
          style: Theme.of(context)
              .textTheme
              .title
              .copyWith(fontSize: ScreenUtil().setSp(60)),
        ),
      ),
      body: new Column(children: <Widget>[
        Center(child: _buildTextfield(context)),
        Center(child:_buildSourceSelection(context)),
        Center(child: _buildButton(context),),
        Center(
          child: _buildReadingFile(context),
        ),
      ]),
    );
  }
}
