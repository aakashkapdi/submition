import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'homeR.dart';
import 'read.dart';
import 'TextToSpeech.dart';
import 'Size_Config.dart';
import 'dart:async';
import 'dart:io' as io;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:connectivity/connectivity.dart';
import 'package:android_intent/android_intent.dart';
import 'cameraHome.dart';
import 'objectDetection.dart';
import 'package:flutter_appavailability/flutter_appavailability.dart';

bool debugShowCheckedModeBanner = true;

class utilities extends StatefulWidget {
  io.File jsonFileFace;
  io.File jsonFileSos;
  utilities({this.jsonFileFace, this.jsonFileSos});
  @override
  _utilitiesState createState() =>
      _utilitiesState(this.jsonFileFace, this.jsonFileSos);
}

class _utilitiesState extends State<utilities> {
  io.File jsonFileFace;
  io.File jsonFileSos;
  _utilitiesState(this.jsonFileFace, this.jsonFileSos);
  final TextToSpeech tts = new TextToSpeech();
  final SpeechToText speech = SpeechToText();
  bool internet;

  bool goOrNot(int touch) {
    if (go[touch]) {
      go[touch] = false;
      return true;
    } else {
      for (int i = 0; i < 5; i++) {
        if (i == touch)
          go[touch] = true;
        else
          go[i] = false;
      }
    }
    return false;
  }

  void cancelTouch() {
    for (int i = 0; i < 5; i++) go[i] = false;
  }

  Future initVoiceInput() async {
    try {
      bool hasSpeech = await speech.initialize();
      if (hasSpeech) print("initialised");
    } catch (e) {
      print("Error while Initialising speech to text:" + e.toString());
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

  void _startTimer() {
    Timer _timer;
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      cancelTouch();
      timer.cancel();
    });
  }

  void _launchTurnByTurnNavigationInGoogleMaps(String location) {
    final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull('google.navigation:q=' + location),
        package: 'com.google.android.apps.maps');
    intent.launch();
  }

  var go = [false, false, false, false, false];

  void initState() {
    super.initState();
    checkInternet();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    tts.tellCurrentScreen("Utilities");
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) =>
              Home(jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos),
          '/camera': (context) =>
              cameraHome(jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos),
          '/objectDetection': (context) => objectDetection(
              jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos),
          '/read': (context) =>
              read(jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos)
        },
        home: Builder(
            builder: (context) => Scaffold(
                backgroundColor: Color(0xFF00B1D2),
                resizeToAvoidBottomPadding: false,
                appBar: AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                  ),
                  title: Text("Utilities"),
                  backgroundColor: Color(0xFF1C3BC8),
                ),
                body: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      if (details.primaryDelta < -20) {
                        tts.tellDateTime();
                      }
                      if (details.primaryDelta > 20)
                        tts.tellCurrentScreen("Utilities");
                    },
                    child: Column(children: <Widget>[
                      SizedBox(
                        height: (SizeConfig.safeBlockVertical * 2),
                        width: SizeConfig.safeBlockHorizontal * 100,
                      ),
                      Container(
                        height: SizeConfig.safeBlockVertical * 18 - 12.58,
                        width: SizeConfig.safeBlockHorizontal * 100,
                        child: RaisedButton(
                          key: null,
                          onPressed: () {
                            tts.tellPress("Navigation");
                            _startTimer();
                            if (goOrNot(0)) {
                              checkInternet();
                              if (!internet) {
                                print("No Internet");
                                tts.tell(
                                    "You dont have an active internet connection.kindly turn on the internet connection");
                              } else {
                                tts.tell("Set your destination after the beep");
                                Future.delayed(Duration(seconds: 4), () async {
                                  await initVoiceInput();
                                  speech.listen(
                                      onResult: (SpeechRecognitionResult
                                          result) async {
                                        tts.tell(
                                            "You entered Your Destination as " +
                                                result.recognizedWords +
                                                "Say yes to confirm the destination after the beep");
                                        speech.cancel();
                                        speech.initialize();
                                        Future.delayed(Duration(seconds: 7),
                                            () {
                                          speech.listen(
                                              onResult: (SpeechRecognitionResult
                                                  result1) {
                                                if (result1.recognizedWords
                                                        .compareTo("yes") ==
                                                    0)
                                                  _launchTurnByTurnNavigationInGoogleMaps(
                                                      result.recognizedWords);
                                                else
                                                  print("cannot confirm");
                                              },
                                              listenFor: Duration(seconds: 10),
                                              pauseFor: Duration(seconds: 5),
                                              partialResults: false,
                                              listenMode:
                                                  ListenMode.confirmation);
                                        });
                                      },
                                      listenFor: Duration(seconds: 10),
                                      pauseFor: Duration(seconds: 5),
                                      partialResults: false,
                                      listenMode: ListenMode.dictation);
                                });
                              }
                            }
                          },
                          color: const Color(0xFF266EC0),
                          child: new Text(
                            "NAVIGATION",
                            style: new TextStyle(
                                fontSize: 36.0,
                                color: const Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w400,
                                fontFamily: "Roboto"),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40.0))),
                        ),
                      ),
                      SizedBox(
                        height: (SizeConfig.safeBlockVertical * 2),
                        width: SizeConfig.safeBlockHorizontal * 100,
                      ),
                      Container(
                        height: SizeConfig.safeBlockVertical * 18 - 12.58,
                        width: SizeConfig.safeBlockHorizontal * 100,
                        child: RaisedButton(
                          key: null,
                          onPressed: () {
                            tts.tellPress("Currency Detection");
                            _startTimer();
                            if (goOrNot(1)) {
                              try {
                                AppAvailability.launchApp('com.rbi.mani');
                              } catch (e) {
                                tts.tell("error opening R B I mani app");
                              }
                            }
                          },
                          color: const Color(0xFF266EC0),
                          child: new Text(
                            "Currency Detection",
                            style: new TextStyle(
                                fontSize: 36.0,
                                color: const Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w400,
                                fontFamily: "Roboto"),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40.0))),
                        ),
                      ),
                      SizedBox(
                        height: (SizeConfig.safeBlockVertical * 2),
                        width: SizeConfig.safeBlockHorizontal * 100,
                      ),
                      Container(
                        height: SizeConfig.safeBlockVertical * 18 - 12.58,
                        width: SizeConfig.safeBlockHorizontal * 100,
                        child: RaisedButton(
                          key: null,
                          onPressed: () {
                            tts.tellPress("Face Detection");
                            _startTimer();
                            if (goOrNot(2)) {
                              Navigator.pushNamed(context, '/camera');
                            }
                          },
                          color: const Color(0xFF266EC0),
                          child: new Text(
                            "FACE DETECTION",
                            style: new TextStyle(
                                fontSize: 36.0,
                                color: const Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w400,
                                fontFamily: "Roboto"),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40.0))),
                        ),
                      ),
                      SizedBox(
                        height: (SizeConfig.safeBlockVertical * 2),
                        width: SizeConfig.safeBlockHorizontal * 100,
                      ),
                      Container(
                        height: SizeConfig.safeBlockVertical * 18 - 12.58,
                        width: SizeConfig.safeBlockHorizontal * 100,
                        child: RaisedButton(
                          key: null,
                          onPressed: () {
                            tts.tellPress("Object Detection");
                            _startTimer();
                            if (goOrNot(3)) {
                              try {
                                Navigator.pushNamed(
                                    context, '/objectDetection');
                              } catch (e) {}
                            }
                          },
                          color: const Color(0xFF266EC0),
                          child: new Text(
                            "OBJECT DETECTION",
                            style: new TextStyle(
                                fontSize: 34.0,
                                color: const Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w400,
                                fontFamily: "Roboto"),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40.0))),
                        ),
                      ),
                      SizedBox(
                        height: (SizeConfig.safeBlockVertical * 2),
                        width: SizeConfig.safeBlockHorizontal * 100,
                      ),
                      Container(
                        height: SizeConfig.safeBlockVertical * 18 - 12.58,
                        width: SizeConfig.safeBlockHorizontal * 100,
                        child: RaisedButton(
                          key: null,
                          onPressed: () {
                            tts.tellPress("Read text");
                            _startTimer();
                            if (goOrNot(4)) {
                              Navigator.pushNamed(context, '/read');
                            }
                          },
                          color: const Color(0xFF266EC0),
                          child: new Text(
                            "READ TEXT",
                            style: new TextStyle(
                                fontSize: 36.0,
                                color: const Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w400,
                                fontFamily: "Roboto"),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40.0))),
                        ),
                      ),
                    ])))));
  }
}
