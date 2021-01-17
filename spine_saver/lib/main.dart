import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'bt-controller.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

void main() => runApp(SpineSaver());

class SpineSaver extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return new DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => new ThemeData(
          primarySwatch: Colors.blueGrey,
          brightness: brightness,
        ),
        themedWidgetBuilder: (context, theme) {
          return new MaterialApp(
            title: 'Spine Saver',
            home: MainPage(title: 'Spine Saver'),
            debugShowCheckedModeBanner: false,
            theme: theme,
          );
        }
    );
  }
}

class MainPage extends StatefulWidget {

  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  static const bool TESTING = false;

  // Sending
  static const String CALIBRATE = 'C';
  static const String HIGH_TOL = 'H';
  static const String MED_TOL = 'M';
  static const String LOW_TOL = 'L';
  static const String END = 'E';
  static const String START = 'S';

  // Receiving
  static const String DONE_CALIBRATE = 'C';
  static const String GOOD_POSTURE = 'G';
  static const String BAD_POSTURE = 'B';

  String arduinoData = "";
  String message = "";
  String tolerance = 'M';

  PostureState postureState = PostureState.INIT;
  bool enabled = true;

  Color btnUnselected = Colors.grey;

  @override
  initState() {
    super.initState();
    BTController.init(onData);
    scanDevices();
  }

  @override
  Widget build(BuildContext context) {

    switch(postureState) {
      case PostureState.INIT:
        message = "Welcome! Hit the Calibrate button to start!";
        break;
      case PostureState.CALIBRATING:
        message = "Calibrating... Sit with your best posture.";
        break;
      case PostureState.UNSET:
        message = "Reading data...";
        break;
      case PostureState.BAD:
        message = "Uh oh! Looks like you should fix your posture!";
        break;
      case PostureState.GOOD:
        message = "Your posture is excellent!";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.title,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: actions(),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: LoadingOverlay(
        isLoading: postureState == PostureState.CALIBRATING,
        child: Container(
          color: Theme.of(context).primaryColorLight,
          child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: columnChildren(),
              ),
          ),
        ),
      ),
    );
  }

  // Sends signal to calibrate
  void calibrate() {
    setState(() {
      postureState = PostureState.CALIBRATING;
    });
    changeColor(Colors.blueGrey);
    BTController.transmit(CALIBRATE);
  }

  // Handles incoming data
  void onData(dynamic str) {
    setState(() {
      arduinoData = str;

      switch(arduinoData) {
        case GOOD_POSTURE:
          postureState = PostureState.GOOD;
          changeColor(Colors.green);
          break;
        case BAD_POSTURE:
          postureState = PostureState.BAD;
          changeColor(Colors.red);
          break;
        default:
          postureState = PostureState.UNSET;
          changeColor(Colors.blueGrey);
      }
    });
  }

  List<Widget> actions() {
    return TESTING ? <Widget>[
      IconButton(
        icon: Icon(Icons.backspace, color: Colors.black,),
        onPressed: () {
          onData(DONE_CALIBRATE);
        },
      ),
      IconButton(
        icon: Icon(Icons.mood_bad, color: Colors.black),
        onPressed: () {
          onData(BAD_POSTURE);
        },
      ),
      IconButton(
        icon: Icon(Icons.mood, color: Colors.black),
        onPressed: () {
          onData(GOOD_POSTURE);
        },
      )
    ] : null;
  }

  List<Widget> columnChildren() {
    List<Widget> list = [];

    list.add(Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Switch(
          value: enabled,
          onChanged: (state) {
            setState(() {
              enabled = state;

              if(enabled)
                BTController.transmit(START);
              else
                BTController.transmit(END);
            });
          },
        ),
        Text(
          'Enabled',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ],
    ));

    if(enabled)
      list.addAll(<Widget>[
        SizedBox(
          height: 50,
        ),
        ButtonBar(
          alignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              elevation: 5,
              color: Theme.of(context).primaryColorDark,
              onPressed: () {
                calibrate();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    'Calibrate',
                    style: TextStyle(
                      fontSize: 30,
                    )
                ),
              ),
            ),
          ],
        ),
        Spacer(),
        Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
            ),
          ),
        ),
        Spacer(),
      ]);
    else
      list.add(
        Spacer()
      );

    list.addAll(<Widget>[
      Text(
        'Tolerance:',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 30,
        ),
      ),
      ButtonBar(
        alignment: MainAxisAlignment.center,
        children: <Widget>[
          RaisedButton(
            color: tolerance == 'L' ? Theme.of(context).primaryColor : btnUnselected,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Low',
                style: TextStyle(
                    fontSize: 20
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                enabled = true;
                tolerance = 'L';
              });
              BTController.transmit(LOW_TOL);
            },
          ),
          RaisedButton(
            color: tolerance == 'M' ? Theme.of(context).primaryColor : btnUnselected,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Medium',
                style: TextStyle(
                    fontSize: 20
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                enabled = true;
                tolerance = 'M';
              });
              BTController.transmit(MED_TOL);
            },
          ),
          RaisedButton(
            color: tolerance == 'H' ? Theme.of(context).primaryColor : btnUnselected,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'High',
                style: TextStyle(
                    fontSize: 20
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                enabled = true;
                tolerance = 'H';
              });
              BTController.transmit(HIGH_TOL);
            },
          ),
        ],
      ),
      SizedBox(height: 50),
    ]);

    return list;
  }

  void changeColor(MaterialColor newColor) {
    if( Theme.of(context).primaryColor != newColor) {
      DynamicTheme.of(context).setThemeData(new ThemeData(
        primarySwatch: newColor,
      ));
    }
  }

  Future<void> scanDevices() async {

    BTController.enumerateDevices()
        .then((devices) { onGetDevices(devices); });
  }

  void onGetDevices(List<dynamic> devices) {

    Iterable<SimpleDialogOption> options = devices.map((device) {

      return SimpleDialogOption(
        child: Text(device.keys.first),
        onPressed: () { selectDevice(device.values.first); },
      );
    });

    // set up the SimpleDialog
    SimpleDialog dialog = SimpleDialog(
      title: const Text('Choose a device'),
      children: options.toList(),
    );

    // show the dialog
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) { return dialog; }
    );
  }

  selectDevice(String deviceAddress) {

    Navigator.of(context, rootNavigator: true).pop('dialog');
    BTController.connect(deviceAddress);
  }

}

enum PostureState {
  INIT,
  CALIBRATING,
  UNSET,
  GOOD,
  BAD
}