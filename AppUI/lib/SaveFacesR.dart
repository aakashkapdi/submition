import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'TextToSpeech.dart';
import 'cameraHome.dart';
import 'dart:async';
import 'Size_Config.dart';
import 'homeR.dart';
import 'package:image/image.dart' as imglib;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io' as io;
import 'util.dart';
import 'dart:convert';

bool debugShowCheckedModeBanner = true;

class SaveFaces extends StatefulWidget {
  io.File jsonFileFace;
  io.File jsonFileSos;
  SaveFaces({this.jsonFileFace, this.jsonFileSos});

  @override
  _SaveFacesState createState() =>
      _SaveFacesState(this.jsonFileFace, this.jsonFileSos);
}

class _SaveFacesState extends State<SaveFaces> {
  io.File jsonFileFace;
  io.File jsonFileSos;
  _SaveFacesState(this.jsonFileFace, this.jsonFileSos);
  TextToSpeech tts = new TextToSpeech();
  TextEditingController _textController = TextEditingController();
  var interpreter;
  Image imgToShow, img;
  imglib.Image convertedImage;
  dynamic data = {};
  dynamic data1 = {};
  io.Directory tempDir;
  bool isLoaded = false;
  int current_showing = -1;

  final timeout = const Duration(seconds: 3);

  var go = [false]; //0:saveface

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
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      cancelTouch();
      timer.cancel();
    });
  }

  void pick_image() async {
    try {
      final FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
      final _imagepicker = ImagePicker();
      var temp_img = await _imagepicker.getImage(source: ImageSource.gallery);
      var file = io.File(temp_img.path).readAsBytesSync();
      img = Image.memory(file); //to display on widget
      convertedImage =
          imglib.decodeImage(file); //converted picked Image to Image class
      FirebaseVisionImage image = FirebaseVisionImage.fromFilePath(
          temp_img.path); //Created firebase image
      List<Face> result = await faceDetector.processImage(image);
      Face _face;
      if (result.isEmpty) {
        print("No Face");
      } else {
        for (_face in result) {
          double x, y, w, h;
          x = (_face.boundingBox.left - 10);
          y = (_face.boundingBox.top - 10);
          w = (_face.boundingBox.width + 10);
          h = (_face.boundingBox.height + 10);
          print("y:" +
              _face.headEulerAngleY.toString() +
              " z:" +
              _face.headEulerAngleZ.toString());
          imglib.Image croppedImage = imglib.copyCrop(
              convertedImage, x.round(), y.round(), w.round(), h.round());
          print("1:  " +
              croppedImage.width.toString() +
              " " +
              croppedImage.height.toString());
          croppedImage = imglib.copyResizeCropSquare(croppedImage, 112);
          print("2:  " +
              croppedImage.width.toString() +
              " " +
              croppedImage.height.toString());
          var op = preProcess(croppedImage);
          if (jsonFileFace.existsSync())
            data = json.decode(jsonFileFace.readAsStringSync());
          data[_textController.text] = List.from(op);
          jsonFileFace.writeAsStringSync(json.encode(data));
          if (jsonFileFace.existsSync())
            data1 = json.decode(jsonFileFace.readAsStringSync());
        }
      }

      setState(() {
        isLoaded = true;
        imgToShow = img;
      });
    } catch (e) {
      print("error while picking Image" + e.toString());
    }
  }

  void saveFacesMethod() async {
    try {
      final gpuDelegateV2 = tfl.GpuDelegateV2(
          options: tfl.GpuDelegateOptionsV2(
        false,
        tfl.TfLiteGpuInferenceUsage.fastSingleAnswer,
        tfl.TfLiteGpuInferencePriority.minLatency,
        tfl.TfLiteGpuInferencePriority.auto,
        tfl.TfLiteGpuInferencePriority.auto,
      ));

      var interpreterOptions = tfl.InterpreterOptions()
        ..addDelegate(gpuDelegateV2);
      interpreter = await tfl.Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);
    } catch (e) {
      print("error while loading model" + e.toString());
    }
    pick_image();
  }

  List<dynamic> preProcess(imglib.Image img) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    List output = List(1 * 192).reshape([1, 192]);
    interpreter.run(input, output);
    output = output.reshape([192]);
    return output;
  }

  Widget showFace() {
    if (jsonFileFace.existsSync()) {
      Map<String, dynamic> data1 = json.decode(jsonFileFace.readAsStringSync());
      if (data1.isEmpty) {
        tts.tell(
            "You Dont Have Any faces saved to perform face recognition. You are on Save Faces Screen.");
        return Container(
          child: Text(
            "No faces Saved",
            style: TextStyle(
                fontSize: 25.0,
                color: const Color(0xFF000000),
                fontWeight: FontWeight.w600,
                fontFamily: "Roboto"),
          ),
        );
      } else {
        List names = [];
        int count = data1.length;
        data1.forEach((key, value) {
          names.add(key);
        });
        print(names);
        return ListView.builder(
            itemCount: count,
            itemBuilder: (BuildContext context, int index) {
              return new Column(
                children: <Widget>[
                  Container(
                    height: SizeConfig.safeBlockVertical * 9,
                    width: SizeConfig.safeBlockHorizontal * 100,
                    child: RaisedButton(
                      key: null,
                      onPressed: () {
                        // tts.tellPress("SAVE CONTACTS");
                      },
                      color: const Color(0xFF266EC0),
                      child: Center(
                          child: Text(
                        names[index],
                        style: new TextStyle(
                            fontSize: 25.0,
                            color: const Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w400,
                            fontFamily: "Roboto"),
                      )),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(40.0))),
                    ),
                  ),
                  new Divider(
                    height: 5.0,
                  ),
                ],
              );
            });
      }
    } else {
      tts.tell(
          "You Dont Have Any faces saved to perform face recognition. You are on Save Faces Screen.");
    }
    return Container(
        child: Center(
      child: Text(
        "No faces Saved",
        style: TextStyle(
            fontSize: 25.0,
            color: const Color(0xFF000000),
            fontWeight: FontWeight.w600,
            fontFamily: "Roboto"),
      ),
    ));
  }

  // void clearFile() {
  //   var data = {};
  //   jsonFileFace.writeAsStringSync(json.encode(data));
  //   tts.tell("File Cleared");
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    tts.tellCurrentScreen("Save Faces");
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) =>
              Home(jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos),
          '/camera': (context) =>
              cameraHome(jsonFileFace: jsonFileFace, jsonFileSos: jsonFileSos)
        },
        title: 'SaveFaces_trial',
        home: Builder(
            builder: (context) => Scaffold(
                resizeToAvoidBottomPadding: false,
                backgroundColor: Color(0xFF00B1D2),
                appBar: new AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                  ),
                  title: new Text('Save Faces '),
                  backgroundColor: Color(0xFF1C3BC8),
                ),
                body: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      if (details.primaryDelta < -20) {
                        tts.tellDateTime();
                      }
                      if (details.primaryDelta > 20)
                        tts.tellCurrentScreen("Save Faces");
                    },
                    child: Column(children: <Widget>[
                      SizedBox(
                        height: SizeConfig.safeBlockVertical * 2,
                        width: SizeConfig.safeBlockHorizontal * 100,
                      ),
                      Container(height: 300, child: showFace()),
                      GestureDetector(
                        onDoubleTap: () {
                          if (_textController.text.isNotEmpty)
                            tts.promptInput(_textController.text);
                        },
                        // child: new TextField(
                        //   controller: _textController,
                        //   style: new TextStyle(
                        //       fontSize: 25.0,
                        //       color: const Color(0xFF000000),
                        //       fontWeight: FontWeight.w600,
                        //       fontFamily: "Roboto"),
                        //   keyboardType: TextInputType.name,
                        //   onTap: () {
                        //     if (_textController.text.isEmpty)
                        //       tts.promptInput("Enter Name");
                        //   },
                        //   onChanged: (value) {
                        //     tts.inputPlayback(value);
                        //   },
                        // ),
                      ),
                      SizedBox(
                        height: SizeConfig.safeBlockVertical * 2,
                        width: SizeConfig.safeBlockHorizontal * 100,
                      ),
                      Container(
                          height: SizeConfig.safeBlockVertical * 18 - 12.58,
                          width: SizeConfig.safeBlockHorizontal * 100,
                          child: RaisedButton(
                            key: null,
                            onPressed: () {
                              tts.tellPress("Choose a face");
                              _startTimer();
                              if (goOrNot(0)) {
                                if (_textController.text.isEmpty) {
                                  tts.promptInput("Name cant Be empty");
                                  return;
                                } else {
                                  saveFacesMethod();
                                }
                              }
                            },
                            color: const Color(0xFF266EC0),
                            child: new Text(
                              "CHOOSE FACES",
                              textAlign: TextAlign.center,
                              style: new TextStyle(
                                  fontSize: 35.0,
                                  color: const Color(0xFFFFFFFF),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "Roboto"),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(40.0))),
                          )),
                      SizedBox(
                        height: SizeConfig.safeBlockVertical * 2,
                        width: SizeConfig.safeBlockHorizontal * 100,
                      )
                    ])))));
  }
}
