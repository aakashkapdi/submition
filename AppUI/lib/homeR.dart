import 'dart:convert';
import 'package:sms/sms.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'utilitiesR.dart';
import 'Size_Config.dart';
import 'TextToSpeech.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'initialisationR.dart';
import 'muteR.dart';
import 'dart:async';
import 'dart:io' as io;
import 'package:connectivity/connectivity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

bool debugShowCheckedModeBanner = true;

class Home extends StatefulWidget {
  io.File jsonFileFace;
  io.File jsonFileSos;
  Home({this.jsonFileFace, this.jsonFileSos});
  @override
  _HomeState createState() => _HomeState(this.jsonFileFace, this.jsonFileSos);
}

class _HomeState extends State<Home> {
  io.File jsonFileFace;
  io.File jsonFileSos;
  io.File jsonFileMute;
  Map<String, dynamic> empty_for_SOS = {};
  Map<String, dynamic> empty_for_Mute = {};
  _HomeState(this.jsonFileFace, this.jsonFileSos);

  //Integration code start

  String data;

  //integration code end

  var internet = false;
  void getdata() async {
    try {
      var url = 'http://192.168.43.116/';

      Timer.periodic(Duration(seconds: 1), (timer) async {
        var response = await http.get(url);
        if (response.statusCode == 200) {
          data = response.body;
          print(data);
          // print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" + data);
          // sensor = data.split(",");
          // sensor1 = int.parse(sensor[0]);
          // sensor2 = int.parse(sensor[1]);
          // sensor3 = int.parse(sensor[2]);
          // print("sensor1:" + sensor1.toString());
          // print("sensor2:" + sensor2.toString());
          // print("sensor3:" + sensor3.toString());
        } else {
          data = 'Request failed with status: ${response.statusCode}.';
          print('Request failed with status: ${response.statusCode}.');
        }
        // setState(() {});
      });
    } catch (e) {
      print("Exception found:" + e.toString());
    }
  }

  final TextToSpeech tts = new TextToSpeech();
  final SpeechToText speech = SpeechToText();

  final timeout = const Duration(seconds: 3);

  var go = [
    false,
    false,
    false,
    false
  ]; //0:sos,1:mute,2:initialisation,3:navigation

  bool goOrNot(int touch) {
    if (go[touch]) {
      go[touch] = false;
      return true;
    } else {
      for (int i = 0; i < 4; i++) {
        if (i == touch)
          go[touch] = true;
        else
          go[i] = false;
      }
    }
    return false;
  }

  void cancelTouch() {
    for (int i = 0; i < 4; i++) go[i] = false;
  }

  void _startTimer() {
    Timer _timer;
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      cancelTouch();
      timer.cancel();
    });
  }

  void checkFileFace() async {
    io.Directory tempDir = await getApplicationDocumentsDirectory();
    String _facePath = tempDir.path + '/face.json';
    if (await io.File(_facePath).exists()) {
      print("Face file Exists");
      jsonFileFace = io.File(_facePath);
    } else {
      jsonFileFace = new io.File(_facePath);
      print("face file created");
    }
  }

  void checkFileSos() async {
    io.Directory tempDir = await getApplicationDocumentsDirectory();
    String _sosPath = tempDir.path + '/sos.json';
    if (await io.File(_sosPath).exists()) {
      print("SOS File Exists");
      jsonFileSos = io.File(_sosPath);
    } else {
      jsonFileSos = new io.File(_sosPath);
      Map<String, dynamic> count = {"count": "0"};
      Map<String, dynamic> sosMssg = {"sosMssg": ""};
      Map<String, dynamic> userFallMssg = {"userFallMssg": ""};
      empty_for_SOS.addAll(count);
      empty_for_SOS.addAll(sosMssg);
      empty_for_SOS.addAll(userFallMssg);
      jsonFileSos.writeAsStringSync(json.encode(empty_for_SOS));
      print("sos file created");
    }
  }

  void checkFileMute() async {
    io.Directory tempDir = await getApplicationDocumentsDirectory();
    String _mutePath = tempDir.path + '/mute.json';
    if (await io.File(_mutePath).exists()) {
      print("Mute file Exists");
      jsonFileMute = io.File(_mutePath);
    } else {
      jsonFileMute = new io.File(_mutePath);
      Map<String, dynamic> o = {"obstacle": "true"};
      Map<String, dynamic> e = {"elevated": "true"};
      Map<String, dynamic> l = {"lowered": "true"};
      Map<String, dynamic> w = {"wet": "true"};
      empty_for_Mute.addAll(o);
      empty_for_Mute.addAll(e);
      empty_for_Mute.addAll(l);
      empty_for_Mute.addAll(w);
      jsonFileMute.writeAsStringSync(json.encode(empty_for_Mute));
      print("Mute file created");
    }
  }

  checkInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi)
      internet = true;
    else
      internet = false;
  }

  Future<String> prepareMssg() async {
    Map<String, dynamic> data = json.decode(jsonFileSos.readAsStringSync());
    String mssgToSend;
    checkInternet();
    if (internet) {
      Position pos = await GeolocatorPlatform.instance.getCurrentPosition();
      if (data["sosMssg"].isEmpty)
        mssgToSend = 'Emergency! I need help!' +
            'My current location is http://maps.google.com/maps?q=' +
            pos.latitude.toString() +
            ',' +
            pos.longitude.toString();
      else
        mssgToSend = data["sosMssg"] +
            '. My current location is http://maps.google.com/maps?q=' +
            pos.latitude.toString() +
            ',' +
            pos.longitude.toString();
    } else {
      if (data["sosMssg"].isEmpty)
        mssgToSend = 'Emergency! I need help!';
      else
        mssgToSend = data["sosMssg"];
    }
    return mssgToSend;
  }

  void initState() {
    super.initState();
    checkInternet();
    speech.cancel();
    speech.stop();
  }

  void send_SOS() async {
    Map<String, dynamic> data1 = json.decode(jsonFileSos.readAsStringSync());
    var count = data1['count'];
    String mssgToSend = await prepareMssg();
    if (int.parse(count) == 0)
      tts.tell("No Contacts Saved. Exiting S O S");
    else {
      List numbers = [];
      data1.forEach((key, value) {
        if (key.contains("number")) numbers.add(value);
      });
      SmsSender sender = new SmsSender();
      numbers.forEach((element) async {
        String address = "+91" + element.toString();
        SmsMessage result =
            await sender.sendSms(new SmsMessage(address, mssgToSend));
        result.onStateChanged.listen((state) {
          if (state == SmsMessageState.Fail) {
            tts.tell("S O S Message Failed due to no network");
          } else if (state == SmsMessageState.Sending) {
            tts.tell("Sending S O S Message ");
          } else if (state == SmsMessageState.Sent)
            tts.tell("S O S Message Sent");
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    checkFileFace();
    checkFileSos();
    checkFileMute();
    SizeConfig().init(context);
    tts.tellCurrentScreen("Home");
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/mute': (context) =>
              Mute(jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos),
          '/initialisation': (context) => Initialisation(
              jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos),
          '/utilities': (context) =>
              utilities(jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos)
        },
        title: "home_trial",
        home: Builder(
            builder: (context) => Scaffold(
                resizeToAvoidBottomPadding: false,
                appBar: AppBar(
                  title: Text("360 VPA"),
                  backgroundColor: Color(0xFF1C3BC8),
                ),
                body: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    if (details.primaryDelta < -20) {
                      tts.tellDateTime();
                    }
                    if (details.primaryDelta > 20)
                      tts.tellCurrentScreen("Home");
                  },
                  child: Column(children: <Widget>[
                    Container(
                      height: SizeConfig.safeBlockVertical * 49.5 - 28,
                      width: SizeConfig.safeBlockHorizontal * 100,
                      color: Colors.white,
                      child: Row(children: <Widget>[
                        Container(
                            height: SizeConfig.safeBlockVertical * 49.5 - 28,
                            width: SizeConfig.safeBlockHorizontal * 49,
                            color: Colors.purple,
                            child: new RaisedButton(
                                key: null,
                                onPressed: () {
                                  tts.tellPress("SEND  S O S");
                                  _startTimer();
                                  if (goOrNot(0)) {
                                    send_SOS();
                                  }
                                },
                                color: const Color(0xFF266EC0),
                                child: new Text(
                                  "SEND SOS",
                                  style: new TextStyle(
                                      fontSize: 21.0,
                                      color: const Color(0xFFFFFFFF),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "Roboto"),
                                ))),
                        SizedBox(
                          height: SizeConfig.safeBlockVertical * 49.5 - 28,
                          width: SizeConfig.safeBlockHorizontal * 2,
                        ),
                        Container(
                            height: SizeConfig.safeBlockVertical * 49.5 - 28,
                            width: SizeConfig.safeBlockHorizontal * 49,
                            color: Colors.purple,
                            child: RaisedButton(
                                key: null,
                                onPressed: () {
                                  tts.tellPress("Mute Audio");
                                  _startTimer();
                                  if (goOrNot(1)) {
                                    Navigator.pushNamed(context, '/mute');
                                  }
                                },
                                color: const Color(0xFF00B1D2),
                                child: new Text(
                                  "MUTE AUDIO",
                                  style: new TextStyle(
                                      fontSize: 21.0,
                                      color: const Color(0xFFFFFFFF),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "Roboto"),
                                )))
                      ]),
                    ),
                    SizedBox(
                      height: SizeConfig.safeBlockVertical * 1,
                      width: SizeConfig.safeBlockHorizontal * 100,
                    ),
                    Container(
                      height: SizeConfig.safeBlockVertical * 49.5 - 28,
                      width: SizeConfig.safeBlockHorizontal * 100,
                      color: Colors.white,
                      child: Row(children: <Widget>[
                        Container(
                          height: SizeConfig.safeBlockVertical * 49.5 - 28,
                          width: SizeConfig.safeBlockHorizontal * 49,
                          color: Colors.purple,
                          child: RaisedButton(
                              key: null,
                              onPressed: () {
                                tts.tellPress("Utilities");
                                _startTimer();
                                if (goOrNot(3)) {
                                  Navigator.pushNamed(context, '/utilities');
                                  //   checkInternet();
                                  //   if(!internet)
                                  //     {
                                  //       print("No Internet");
                                  //       tts.tell("You dont have an active internet connection");
                                  //     }
                                  //   else{
                                  //     tts.tell("Set your destination after the beep");
                                  //     Future.delayed(Duration(seconds: 4),()async{
                                  //             await initVoiceInput();
                                  //             speech.listen(
                                  //             onResult: (SpeechRecognitionResult result)async {

                                  //                       tts.tell("You entered Your Destination as "+result.recognizedWords+"Say yes to confirm the destination after the beep");
                                  //                       speech.cancel();
                                  //                       speech.initialize();
                                  //                       Future.delayed(Duration(seconds: 7),(){
                                  //                           speech.listen(
                                  //                         onResult:(SpeechRecognitionResult result1){
                                  //                           if(result1.recognizedWords.compareTo("yes")==0)
                                  //                              _launchTurnByTurnNavigationInGoogleMaps(result.recognizedWords);
                                  //                           else
                                  //                              print("cannot confirm");
                                  //                         },
                                  //                       listenFor: Duration(seconds: 10),
                                  //                       pauseFor: Duration(seconds:5),
                                  //                       partialResults: false,
                                  //                       listenMode: ListenMode.confirmation);
                                  //                       });

                                  //                     },
                                  //             listenFor: Duration(seconds: 10),

                                  //             pauseFor: Duration(seconds:5),
                                  //             partialResults: false,
                                  //             listenMode: ListenMode.dictation);
                                  //       });
                                  //   }
                                }
                              },
                              color: const Color(0xFF00B1D2),
                              child: new Text(
                                "UTILITIES",
                                style: new TextStyle(
                                    fontSize: 21.0,
                                    color: const Color(0xFFFFFFFF),
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "Roboto"),
                              )),
                        ),
                        SizedBox(
                          height: SizeConfig.safeBlockVertical * 49.5 - 28,
                          width: SizeConfig.safeBlockHorizontal * 2,
                        ),
                        Container(
                            height: SizeConfig.safeBlockVertical * 49.5 - 28,
                            width: SizeConfig.safeBlockHorizontal * 49,
                            color: Colors.purple,
                            child: RaisedButton(
                                key: null,
                                onPressed: () {
                                  tts.tellPress("Initialisation");
                                  _startTimer();
                                  if (goOrNot(2)) {
                                    Navigator.pushNamed(
                                        context, '/initialisation');
                                  }
                                },
                                color: const Color(0xFF266EC0),
                                child: new Text(
                                  "INITIALISATION",
                                  style: new TextStyle(
                                      fontSize: 20.0,
                                      color: const Color(0xFFFFFFFF),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "Roboto"),
                                )))
                      ]),
                    )
                  ]),
                ))));
  }
}
