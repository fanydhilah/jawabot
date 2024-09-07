import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:intl/intl.dart';
import 'package:trytest/ChatApp2.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tts/tts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jawa Bot',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.teal[800],
      ),
      home: WelcomeHome(),
    );
  }
}

class WelcomeHome extends StatefulWidget {
  WelcomeHome({Key key, this.st}) : super(key: key);
  final int st;

  @override
  _WelcomeHomeState createState() {
    var welcomeHomeState = _WelcomeHomeState(st);
    return welcomeHomeState;
  }
}

final GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();
GoToSecondPage(BuildContext context, String text1) async {
  final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => HomePageDialogflow(
                data: text1,
              )));
  _scaffold.currentState.showSnackBar(SnackBar(content: Text("$result")));
}

class _WelcomeHomeState extends State<WelcomeHome> {
  int st;
  final Firestore firestore = Firestore.instance;
  String date = DateFormat("Hm").format(DateTime.now());
  var gif;
  var fig;
  int i;
  final List<ChatMessage> _messages = <ChatMessage>[];
  // speech to text
  stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "";

  _WelcomeHomeState(this.st);

  @override
  // ini buat nge inisialisasi nilai awal
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    gif = Image.asset('assets/images/gif4.gif');
    i = 0;
    st = 0;
  }

  List<Map> messsages = List();

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg.jpg"),
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.15), BlendMode.dstATop),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: <Widget>[
            Flexible(
              flex: 1,
              child: Align(
                alignment: Alignment(0.9, 1.75),
                child: new FloatingActionButton(
                    heroTag: null,
                    backgroundColor: Colors.teal[400],
                    foregroundColor: Colors.black,
                    child: Icon(Icons.chat),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            //return ChatAppp();
                            return HomePageDialogflow();
                          },
                        ),
                      );
                    }),
              ),
            ),
            Flexible(flex: 3, child: Center(child: gif)),
            Flexible(
              flex: 1,
              child: FloatingActionButton(
                backgroundColor: Colors.teal[400],
                foregroundColor: Colors.black,
                child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: () async {
                  setState(() {
                    // ini buat ganti gif nya
                    i++;
                    if (i % 2 == 1) {
                      // modulus 2 karena cuma ada 2 state (misal ganjil genap)
                      gif = Image.asset("assets/images/gif5.gif");
                    } else if (i % 2 != 1) {
                      gif = Image.asset("assets/images/gif4.gif");
                    }
                  });
                  print(gif);
                  _listen();

                  if (_text == "") {
                    print("empty message");
                  } else {
                    ChatMessage message = new ChatMessage(
                      text: _text,
                      name: "Promise",
                      type: true,
                    );
                    setState(() {
                      _messages.insert(0, message);
                    });
                    Response(_text);
                    CollectionReference users = firestore.collection('users');
                    DocumentReference result =
                        await users.add(<String, dynamic>{
                      'message': _text,
                      'date': date,
                    });
                    print(_text);
                    _text = "";
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void Response(query) async {
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

    giftts(response.getMessage() ??
        new CardDialogflow(response.getListMessage()[0]).title);
    speaktts(
        response.getMessage() ??
            new CardDialogflow(response.getListMessage()[0]).title,
        context);
    setState(() {
      _messages.insert(0, message);
    });
  }

  void giftts(
    var query,
  ) {
    // int i = 0;
    if (query != "") {
      setState(() {
        gif = Image.asset("assets/images/gif6.gif");
      });
    }
    print(gif);
  }

  void speaktts(String query, BuildContext context) async {
    Tts.setLanguage('jv-ID');
    Tts.speak(query);
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
}
