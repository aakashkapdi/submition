import 'package:flutter_tts_improved/flutter_tts_improved.dart';

class TextToSpeech {
  final FlutterTtsImproved tts = FlutterTtsImproved();

  void setTts() async {
    await tts.setLanguage('en-IN');
    await tts.setVolume(1.0);
    await tts.setSpeechRate(1.0);
  }

  void tellCurrentScreen(String screen) async {
    await tts.stop();
    setTts();
    await tts.speak("You are on " + screen + "Screen");
  }

  void tellPress(String button) async {
    await tts.stop();
    setTts();
    await tts.speak(button);
  }

  void promptInput(String string) async {
    await tts.stop();
    setTts();
    await tts.speak(string);
  }

  void inputPlayback(String string) async {
    var processed = string.split("");
    processed.forEach((element) async {
      await tts.stop();
      await tts.speak(element);
    });
  }

  String _getDate() {
    String year, day, month;
    day = DateTime.now().day.toString();
    year = DateTime.now().year.toString();
    switch (DateTime.now().month) {
      case 1:
        {
          month = "January";
          break;
        }
      case 2:
        {
          month = "Feburary";
          break;
        }
      case 3:
        {
          month = "March";
          break;
        }
      case 4:
        {
          month = "April";
          break;
        }
      case 5:
        {
          month = "May";
          break;
        }
      case 6:
        {
          month = "June";
          break;
        }
      case 7:
        {
          month = "July";
          break;
        }
      case 8:
        {
          month = "August";
          break;
        }
      case 9:
        {
          month = "September";
          break;
        }
      case 10:
        {
          month = "October";
          break;
        }
      case 11:
        {
          month = "November";
          break;
        }
      case 12:
        {
          month = "December";
          break;
        }
    }
    return day + " " + month + " " + year;
  }

  String _getTime() {
    int hour, minutes;
    String k;
    if (DateTime.now().hour > 12) {
      hour = DateTime.now().hour % 12;
      k = "PM";
    } else {
      if (DateTime.now().hour == 12) {
        hour = DateTime.now().hour;
        k = "PM";
      } else {
        if (DateTime.now().hour < 12) {
          hour = DateTime.now().hour;
          k = "AM";
        }
      }
    }
    minutes = DateTime.now().minute;
    return hour.toString() + "  " + minutes.toString() + k;
  }

  String _getCombined() {
    return "The Date is" + _getDate() + "and the time is" + _getTime();
  }

  void tellDateTime() async {
    await tts.stop();
    setTts();
    await tts.speak(_getCombined());
  }

  void tell(String content) async {
    await tts.stop();
    setTts();
    await tts.speak(content);
  }

  void cancel() async {
    tts.stop();
  }
}
