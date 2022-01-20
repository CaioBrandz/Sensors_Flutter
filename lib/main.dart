import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:sensors_plus/sensors_plus.dart';

import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:light/light.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Sensors',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<double>? _accelerometerValues;
  List<double>? _userAccelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;

  final _streamSubscriptions = <dynamic>[];

  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = 'stopped', _steps = '0';


  bool _isNear = false;
  late StreamSubscription<dynamic> _streamSubscription;


  String _luxString = '0';
  late Light _light;
  late StreamSubscription _subscriptionLight;


  void onData(int luxValue) async {
    print("Lux value: $luxValue");
    setState(() {
      _luxString = "$luxValue";
    });
  }

  void stopListening() {
    _subscriptionLight.cancel();
  }

  void startListening() {
    _light = new Light();
    try {
      _subscriptionLight = _light.lightSensorStream.listen(onData);
    } on LightException catch (exception) {
      print(exception);
    }
  }

  Future<void> initLight() async {
    startListening();
  }

  @override
  Widget build(BuildContext context) {
    final accelerometer =
    _accelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    final gyroscope =
    _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();
    final userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    final magnetometer =
    _magnetometerValues?.map((double v) => v.toStringAsFixed(1)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Sensors"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /*Icon(
              Icons.location_on,
              size: 46.0,
              color: Colors.blue,
            ),*/
            SizedBox(
              height: 10.0,
            ),
            Text(
              "Sensores",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 20.0,
            ),

            Text('Sensor de proximidade detectando algo?'),
            Text(
                _isNear ? 'Simm! :D\n': 'Nãoo :(\n',
                style: _isNear == true
                  ? TextStyle(fontSize: 24, color:Colors.green,fontWeight: FontWeight.bold)
                  : TextStyle(fontSize: 24, color: Colors.red,fontWeight: FontWeight.bold),
            ),
            Text('Valor captado no sensor de luz:'),
            Text(_luxString+ '\n',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),

            Text('Passos dados:'),
            Text(
                _steps,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black45)),
            Text('Status:',),
            Icon(
              _status == 'walking'
                  ? Icons.directions_walk
                  : _status == 'stopped'
                  ? Icons.accessibility_new
                  : Icons.error,
              size: 36,
            ),
            Center(
              child: Text(
                _status == 'walking' ?
                "andando"
                : "parado",
                style: _status == 'walking'
                    ? TextStyle(fontSize: 24, color:Colors.green,fontWeight: FontWeight.bold)
                    : TextStyle(fontSize: 24, color: Colors.red,fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
            (UserAccelerometerEvent event) {
          setState(() {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );

    listenSensor();
    initLight();
  }

  Future<void> listenSensor() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (foundation.kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
    _streamSubscription = ProximitySensor.events.listen((int event) {
      setState(() {
        _isNear = (event > 0) ? true : false;
      });
    });
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }
}
