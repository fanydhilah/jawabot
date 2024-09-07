import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:intl/intl.dart';
import 'package:tts/tts.dart';
import 'package:trytest/main.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:bubble/bubble.dart';

class HomePageDialogflow extends StatefulWidget {
  HomePageDialogflow({Key key, this.title, this.data, this.message, this.date})
      : super(key: key);

  final String title;
  final String data;
  final String message;
  final String date;

  @override
  _HomePageDialogflow createState() => new _HomePageDialogflow(data);
}

class _HomePageDialogflow extends State<HomePageDialogflow> {
  final Firestore firestore = Firestore.instance;
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = new TextEditingController();
  String date = DateFormat("Hm").format(DateTime.now());
  stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "";
  int st = 0;
  String data;

  _HomePageDialogflow(this.data);
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            color: Color.fromRGBO(220, 220, 220, 1)),
        padding: EdgeInsets.only(left: 15),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                  icon: new Icon(_isListening ? Icons.mic : Icons.mic_none,
                      size: 30, color: Colors.greenAccent),
                  onPressed: () {
                    _listen();
                    if (_text == "") {
                      print("empty message");
                    } else {
                      _handleSubmitSpeech(_text);
                      print(_text);
                      _text = "";
                    }
                  }),
            ),
            new Flexible(
              child: new TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: new InputDecoration(
                  hintText: "Send Your Message",
                  hintStyle: TextStyle(color: Colors.black26),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                  icon:
                      new Icon(Icons.send, size: 30, color: Colors.greenAccent),
                  onPressed: () async {
                    String message = _textController.text;
                    if (_textController.text.isEmpty) {
                      print("empty message");
                    } else {
                      _handleSubmitted(_textController.text);
                      CollectionReference users = firestore.collection('users');
                      DocumentReference result =
                          await users.add(<String, dynamic>{
                        'message': message,
                        'date': date,
                      });
                    }
                  }),
            ),
            SizedBox(
              height: 15.0,
            )
          ],
        ),
      ),
    );
  }

  void _listen() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (!_isListening) {
      if (available) {
        setState(() {
          _isListening = true;
          _speech.listen(
            onResult: (val) => setState(() {
              _text = val.recognizedWords;
            }),
          );
        });
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  void Response(query) async {
    _textController.clear();
    AuthGoogle authGoogle =
        await AuthGoogle(fileJson: "assets/newagent-kalbgl-c0fb323bfb4c.json")
            .build();
    Dialogflow dialogflow =
        Dialogflow(authGoogle: authGoogle, language: Language.indonesian);
    AIResponse response = await dialogflow.detectIntent(query);
    CollectionReference bot = firestore.collection('bot');
    DocumentReference result = await bot.add(<String, dynamic>{
      'message': response.getMessage() ??
          new CardDialogflow(response.getListMessage()[0]).title,
      'date': date,
    });
    ChatMessage message = new ChatMessage(
      text: response.getMessage() ??
          new CardDialogflow(response.getListMessage()[0]).title,
      name: "Bot",
      type: false,
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    ChatMessage message = new ChatMessage(
      text: text,
      name: "Promise",
      type: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
    Response(text);
  }

  void _handleSubmitSpeech(String _text) {
    ChatMessage message = new ChatMessage(
      text: _text,
      name: "Promise",
      type: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
    Response(_text);
  }

  void getMessageUser(String text) async {
    firestore.collection('tasks').orderBy('date').snapshots();
    ChatMessage message = new ChatMessage(
      text: text,
      name: "Promise",
      type: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  void getMessageBot() async {
    await firestore.collection('bot').getDocuments().then((data) {
      data.documents.forEach((doc) {
        print(doc.data);
      });
    });
  }

  void acceptMessage(String data) {
    ChatMessage message = new ChatMessage(
      text: data,
      name: "Promise",
      type: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
    Response(_text);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          centerTitle: true,
          title: new Text("Jawa Bot"),
          backgroundColor: Colors.teal[800],
        ),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
              image: AssetImage("assets/bg.jpg"),
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.15), BlendMode.dstATop),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(children: <Widget>[
            new Center(
              child: Container(
                padding: EdgeInsets.only(top: 15, bottom: 10),
                child: Text(
                  //tanggal
                  "Dinten Niki, ${DateFormat("Hm").format(DateTime.now())}",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
            new Flexible(
                child: new ListView.builder(
              padding: new EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            )),
            new SizedBox(
              height: 20,
            ),
            new Divider(height: 1.0),
            new Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  color: Color.fromRGBO(220, 220, 220, 1)),
              padding: EdgeInsets.only(left: 15),
              child: _buildTextComposer(),
            ),
            new SizedBox(
              height: 15,
            ),
          ]),
        ));
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({
    this.text,
    this.name,
    this.type,
  });

  final String text;
  final Firestore firestore = Firestore.instance;
  final String name;
  final bool type;
  final dbref = Firestore.instance;

  List<Widget> otherMessage(context) {
    return <Widget>[
      new Container(
        margin: const EdgeInsets.only(right: 5.0),
        height: 50,
        width: 50,
        child:
            new CircleAvatar(backgroundImage: AssetImage("assets/robot.jpg")),
      ),
      new Padding(
        padding: EdgeInsets.all(1.0),
        child: Bubble(
            radius: Radius.circular(15.0),
            color: Colors.orangeAccent,
            elevation: 0.0,
            child: Padding(
              padding: EdgeInsets.all(2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 5.0,
                  ),
                  Flexible(
                      child: Container(
                    constraints: BoxConstraints(maxWidth: 200),
                    child: Text(
                      text,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ))
                ],
              ),
            )),
      ),
    ];
  }

  List<Widget> myMessage(context) {
    return <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.end,
        ),
      ),
      new Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Bubble(
            radius: Radius.circular(15.0),
            color: Color.fromRGBO(23, 157, 139, 1),
            elevation: 0.0,
            child: Padding(
              padding: EdgeInsets.all(2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 5.0,
                  ),
                  Flexible(
                      child: Container(
                          constraints: BoxConstraints(maxWidth: 200),
                          child: Text(
                            text,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )))
                ],
              ),
            )),
      ),
      new Container(
        margin: const EdgeInsets.only(left: 1.0),
        height: 50,
        width: 50,
        child:
            new CircleAvatar(backgroundImage: AssetImage("assets/default.jpg")),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: this.type ? myMessage(context) : otherMessage(context),
      ),
    );
  }
}
