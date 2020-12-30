import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'Size_Config.dart';
import 'homeR.dart';
import 'package:flutter/services.dart';
import 'TextToSpeech.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart' as tfl;
import 'util.dart';
import 'package:flutter_appavailability/flutter_appavailability.dart';

bool debugShowCheckedModeBanner = true;

var go = [
  false,
]; //0:open lookout

bool goOrNot(int touch) {
  if (go[touch]) {
    go[touch] = false;
    return true;
  } else {
    for (int i = 0; i < 1; i++) {
      if (i == touch)
        go[touch] = true;
      else
        go[i] = false;
    }
  }
  return false;
}

void cancelTouch() {
  for (int i = 0; i < 1; i++) go[i] = false;
}

void _startTimer() {
  Timer _timer;
  _timer = Timer.periodic(Duration(seconds: 10), (timer) {
    cancelTouch();
    timer.cancel();
  });
}

class objectDetection extends StatefulWidget {
  io.File jsonFileFace;
  io.File jsonFileSos;
  objectDetection({this.jsonFileFace, this.jsonFileSos});
  @override
  _objectDetectionState createState() =>
      _objectDetectionState(this.jsonFileFace, this.jsonFileSos);
}

class _objectDetectionState extends State<objectDetection> {
  io.File jsonFileFace;
  io.File jsonFileSos;
  _objectDetectionState(this.jsonFileFace, this.jsonFileSos);
  TextToSpeech tts = new TextToSpeech();
  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.back;
  CameraController _camera;
  List<String> objects = [];

  void giveOutput(String s) {
    if (objects.contains(s))
      ;
    else {
      objects.insert(objects.length, s);
      print("inserted at " + objects.length.toString());
      tts.tell(s);
      Future.delayed(Duration(seconds: 5), () {
        objects = [];
      });
    }
  }

  loadTfModel() async {
    await tfl.Tflite.loadModel(
      model: "assets/ssd_mobilenet.tflite",
      labels: "assets/labels.txt",
    );
  }

  void _initializeCamera() async {
    CameraDescription description = await getCamera(_direction);

    _camera =
        CameraController(description, ResolutionPreset.low, enableAudio: false);
    await _camera.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {});
    Future.delayed(Duration(seconds: 2));
    _camera.startImageStream((image) {
      if (!_isDetecting) {
        _isDetecting = true;
        tfl.Tflite.detectObjectOnFrame(
          bytesList: image.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          model: "SSDMobileNet",
          imageHeight: image.height,
          imageWidth: image.width,
          imageMean: 127.5,
          imageStd: 127.5,
          numResultsPerClass: 3,
          threshold: 0.7,
        ).then((recognitions) {
          recognitions.forEach((element) {
            giveOutput(element['detectedClass']);
          });
          _isDetecting = false;
        });
      }
    });
  }

  Widget _showCamera() {
    if (_camera == null)
      return Center(
          child: Container(
              height: 200, width: 200, child: CircularProgressIndicator()));
    else
      return CameraPreview(_camera);
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _initializeCamera();
    loadTfModel();
  }

  @override
  void dispose() {
    try {
      _camera?.dispose();
    } catch (err) {
      print(err);
    }
    super.dispose();
  }

  void getapps() async {
    List<Map<String, String>> apps = await AppAvailability.getInstalledApps();
    print(apps);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) =>
              Home(jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos)
        },
        home: Builder(
            builder: (context) => Scaffold(
                resizeToAvoidBottomPadding: false,
                backgroundColor: Color(0xFF00B1D2),
                appBar: new AppBar(
                  leading: IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () {
                        _camera.dispose();
                        Navigator.pushNamed(context, '/home');
                      }),
                  title: new Text('Object Detection'),
                  backgroundColor: Color(0xFF1C3BC8),
                ),
                body: Column(
                  children: <Widget>[
                    Container(
                      height: SizeConfig.safeBlockVertical * 59,
                      width: SizeConfig.safeBlockHorizontal * 100,
                      child: _showCamera(),
                    ),
                    SizedBox(
                      height: SizeConfig.safeBlockVertical * 3,
                      width: SizeConfig.safeBlockHorizontal * 100,
                    ),
                    Container(
                      height: SizeConfig.safeBlockVertical * 15,
                      width: SizeConfig.safeBlockHorizontal * 100,
                      child: RaisedButton(
                        key: null,
                        onPressed: () {
                          tts.tellPress("Open Google Lookout");
                          if (goOrNot(0)) {
                            try {
                              AppAvailability.launchApp(
                                  'com.google.android.apps.accessibility.reveal');
                              getapps();
                            } catch (e) {
                              tts.tell("error opening Google Lookout app");
                            }
                          }
                        },
                        color: const Color(0xFF266EC0),
                        child: Center(
                          child: Text(
                            "Open Lookout by Google",
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                                fontSize: 35.0,
                                color: const Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w400,
                                fontFamily: "Roboto"),
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(40.0))),
                      ),
                    ),
                  ],
                ))));
  }
}
