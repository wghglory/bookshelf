import 'package:flutter/material.dart';
import 'package:bookshelf/tools.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';




class TxtPage extends StatefulWidget {
  @override
  _TxtPageState createState() => _TxtPageState();
}

class _TxtPageState extends State<TxtPage> {
  TxtPageArguments _arg;
  String _usertoken = '';
  String _bucketName = '';
  String _objectName = '';
  String _pathName = '';
  String _filePath = '';
  final double height=window.physicalSize.height/(window.devicePixelRatio);
  final double width=window.physicalSize.width/(window.devicePixelRatio);
  int page=1;
  //flags
  bool _isReady = false;
  bool _flagNightMode=false;
  bool _isSearch=false;
  bool _isBar=false;
  //stream controller of input stream
  StreamController<String> _controller = StreamController<String>();
  //storage of contents strings
  List<String> contents = [];
  //UI index
  double fontsize = 12;
  Color color_background=Colors.white;
  Color color_word=Colors.black;
  //Search txt controller
  final _textedditing_controller = TextEditingController();
  final ScrollController _scroll_controller = new ScrollController();

  void _sizeconfig() async{
    String directory=_filePath.substring(0,_pathName.lastIndexOf("/"));
    File file = File("${directory}/size.txt");
    if(!await file.exists()) {
      file = await file.create();
      file = await file.writeAsString("12");
      setState(() {fontsize=12;});
      print("no config, create");
    }
    else{
      String size=file.readAsStringSync();
      setState(() {
        fontsize=double.parse(size);
        print("config exists");
        print(fontsize);
      });
    }
  }

  void _modeconfig() async{
    String directory=_filePath.substring(0,_pathName.lastIndexOf("/"));
    File file = File("${directory}/nightmode.txt");
    if(!await file.exists()) {
      //创建文件
      file = await file.create();
      file = await file.writeAsString("false");
      setState(() {_flagNightMode=false;});
      print("no mode config, create");
    }
    else{
      String mode=file.readAsStringSync();
      print("mode is");
      print(mode);

      setState(() {
        if(mode=="false"){
          _flagNightMode=false;
          color_background=Colors.white;
          color_word=Colors.black;
        }
        else{_flagNightMode=true;
        color_background=Colors.black;
        color_word=Colors.grey;}
      });
    }
  }


  void _turnPage_next(){
    _scroll_controller.jumpTo(_scroll_controller.offset+height-85);
  }
  void _turnPage_prev(){
    _scroll_controller.jumpTo(_scroll_controller.offset-height+85);
  }

  void _searchContent(String word){
    for (int i=0;i<contents.length;i++){
      if(contents[i].indexOf(word)!=-1){
        print(contents[i][contents[i].indexOf(word)]);
        break;
      }
    }
    print("Not found");
  }

  void _SearchPressed(){
    setState(() {
      _isSearch=!_isSearch;
    });
  }

  void _BarPressed(){
    setState(() {
      _isBar=!_isBar;
      print(_isBar);
    });
  }

  void _nightmode(){
    if (!_flagNightMode){
      setState(() {
        color_background=Colors.black;
        color_word=Colors.grey;
        _flagNightMode=!_flagNightMode;
        String directory=_filePath.substring(0,_pathName.lastIndexOf("/"));
        File file = File("${directory}/nightmode.txt");
        file.writeAsStringSync("true");
      });
    }
    else{
      setState(() {
        color_background=Colors.white;
        color_word=Colors.black;
        _flagNightMode=!_flagNightMode;
        String directory=_filePath.substring(0,_pathName.lastIndexOf("/"));
        File file = File("${directory}/nightmode.txt");
        file.writeAsStringSync("false");
      });
    }
  }

  void _IncreaseFont(){
    setState(() {
      fontsize+=1;

      String directory=_filePath.substring(0,_pathName.lastIndexOf("/"));
      File file = File("${directory}/size.txt");
      file.writeAsStringSync(fontsize.toString());
    });
  }
  void _DecreaseFont(){
    setState(() {
      fontsize-=1;
      String directory=_filePath.substring(0,_pathName.lastIndexOf("/"));
      File file = File("${directory}/size.txt");
      file.writeAsStringSync(fontsize.toString());
    });
  }

  void _ReadContent(){
    File file=new File('$_filePath');
    Stream<List<int>> inputStream = file.openRead();
    inputStream
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .listen((String line) { // Process results.
      contents.add(line);
    },
        onDone: () {
          //_controller.close(); //_controller.sink.add(content);//print(content);
          //print(_isReady);
          _controller.sink.add("Get full content");
        },
        onError: (e) {
          print(e.toString());
        });
  }
  @override
  void dispose(){
    _textedditing_controller.dispose();
    super.dispose();
  }

  Widget _pageNumber(){
    _scroll_controller.addListener((){
      setState(() {
        page=(_scroll_controller.offset/(height-85)).floor()+1;
      });
      //print(page);
    });
    return
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                  padding: const EdgeInsets.all(8),
                  child:
                  Text(
                      "$page",
                      style: new TextStyle(
                          fontSize: 20
                      )
                  )
              )
            ],
          )
        ],
      );
  }

  Widget _buildTxt(int index) {
    return
      Container(
          padding: const EdgeInsets.all(32.0),
          child:
          new Text(
            contents[index],
            textAlign: TextAlign.left,
            //文本对齐方式  居中
            textDirection: TextDirection.ltr,
            //文本方向
            softWrap: true,
            //是否自动换行 false文字不考虑容器大小  单行显示   超出；屏幕部分将默认截断处理
            overflow: TextOverflow.fade,
            textScaleFactor: 2.0,
            //字体显示的赔率

            //maxLines: , //最大行数
            style: new TextStyle(
              decorationColor: Color(0xffffffff),
              //线的颜色
              decoration: TextDecoration.none,
              decorationStyle: TextDecorationStyle.solid,
              //文字装饰的风格  dashed,dotted虚线(简短间隔大小区分)  double三条线  solid两条线
              wordSpacing: 0.0,
              //单词间隙(负值可以让单词更紧凑)
              letterSpacing: 0.0,
              //字母间隙(负值可以让字母更紧凑)
              fontStyle: FontStyle.normal,
              //文字样式，斜体和正常
              fontSize: fontsize,
              //字体大小
              fontWeight: FontWeight.w600,
              //字体粗细  粗体和正常
              color: color_word, //文字颜色
            ),
          )
      );
  }

  Widget _page() {
    _isReady=true;
    return StreamBuilder(
      stream: _controller.stream,
      initialData: " ",
      builder: (BuildContext context, AsyncSnapshot<String> snapshot){
        //return
        //!_isReady? Center(child: CircularProgressIndicator(),):
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return ListView.builder(
              controller: _scroll_controller,
              itemCount: contents.length,
              itemBuilder: (BuildContext context, int index) {
                //print(snapshot.connectionState);
                //print(snapshot.data);
                //_scroll_controller.addListener(()=>print(_scroll_controller.offset));
                return _buildTxt(index);
              },

            );

          case ConnectionState.done:
            if (snapshot.hasError)
              return SnackBar(
                content: Text(
                    'Exception happens and Get Buckets Failed!'),
                duration: Duration(seconds: 1),
              );
        }
        return Container();
      },
    );
  }

  Widget _searchBotton(){
    return IconButton(
      icon: Icon(Icons.search),
      onPressed: (){
        _SearchPressed();
      },
    );
  }

  Widget _searchTextField(){
    return Stack(
        children: <Widget>[
          Center(
            child: TextField(
              controller: _textedditing_controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 20.0),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                suffixIcon:
                new IconButton(
                  icon: new Icon(Icons.cancel),
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _textedditing_controller.clear());
                  },
                ),
                contentPadding: EdgeInsets.all(10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                //border: InputBorder.none,
                hintText: 'Search',
                fillColor: Colors.white,
                filled: true,
              ),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (newValue) {
                _searchContent(newValue);
              },
            ),
          ),
        ]
    );
  }

  Widget build(BuildContext context) {
    this._arg = ModalRoute
        .of(context)
        .settings
        .arguments;
    this._usertoken = this._arg.userToken;
    this._bucketName = this._arg.bucketName;
    this._objectName = this._arg.objectName;
    this._pathName = this._arg.pathName;
    this._filePath = this._pathName + '/' + this._objectName;

    if(!_isReady){
      _ReadContent();
      _sizeconfig();
      _modeconfig();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("$_objectName"),
      ),
      backgroundColor: color_background,
      body:
      Scrollbar(
          child: Stack(
            children: <Widget>[
              _page(),
              _isBar ?  GestureDetector(
                  child: Opacity(
                    opacity: 0.7,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                    ),
                  ),
                  onTap: _BarPressed
              ) :  Container(),
              _isSearch ?  GestureDetector(
                  child: Opacity(
                    opacity: 0.7,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                    ),
                  ),
                  onTap: _SearchPressed
              ) :  Container(),

              _isSearch ? Container(
                  child:
                  Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        width: double.infinity,
                        height: 60.0,
                        decoration: new BoxDecoration(
                          //borderRadius: BorderRadius.circular(15.0), // 边色与边宽度
                          //color: Colors.black, // 底色
                        ),
                        child: _isSearch ? _searchTextField(): Container(),
                      )
                  )
              ) : Container(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                      child: Container(
                        width: 60,
                        height: double.infinity,
                        color: Colors.transparent,
                      ),
                      onTap: _turnPage_prev
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    child:
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          width: width-120,
                          height: 50,
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                      onTap: _BarPressed,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GestureDetector(
                      child: Container(
                        width: 60,
                        height: double.infinity,
                        color: Colors.transparent,
                      ),
                      onTap: _turnPage_next
                  ),
                ],
              ),
              _pageNumber(),
              _isBar ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  BottomAppBar(
                      shape: CircularNotchedRectangle(),
                      child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[

                            new IconButton(
                              icon: new Icon(Icons.zoom_out),
                              onPressed: () {
                                _DecreaseFont();
                              },
                            ),
                            new IconButton(
                              icon: new Icon(Icons.zoom_in),
                              onPressed: () {
                                _IncreaseFont();
                              },
                            ),
                            new IconButton(
                              icon: new Icon(Icons.remove_red_eye),
                              onPressed: () {
                                _nightmode();
                              },
                            ),
                          ]
                      )
                  )
                ],
              ) : Container(),
            ],
          )
      ),
    );
  }

}