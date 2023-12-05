import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/firebase_options.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(const MyApp());
// }

class Demo extends StatelessWidget {
  const Demo({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'RevAPP'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('samples.flutter.dev/battery');

  // Get battery level.
  String _batteryLevel = 'Unknown battery level.';
  String _movellaStatus = 'Unknown';
  String _movellaMeasurementStatus = 'Unknown';
  List<dynamic> _devicesList = [];

  @override
  void initState() {
    super.initState();
    _initMovella();
  }

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final result = await platform.invokeMethod<int>('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  Future<void> _initMovella() async {
    String movellaStatus;
    try {
      final result = await platform.invokeMethod<String>('movella_init');
      movellaStatus = result!;
    } on PlatformException catch (e) {
      movellaStatus = "Failed to get movella status: '${e.message}'.";
    }

    setState(() {
      _movellaStatus = movellaStatus;
    });
  }

  Future<void> _startMovellaBLEscan() async {
    String movellaStatus;
    try {
      final result =
          await platform.invokeMethod<String>('movella_startBLEscan');
      movellaStatus = "Scanning? $result";
    } on PlatformException catch (e) {
      movellaStatus = "Failed to get movella status: '${e.message}'.";
    }

    setState(() {
      _movellaStatus = movellaStatus;
    });
  }

  Future<void> _stopMovellaBLEscan() async {
    String movellaStatusStopped;
    List<dynamic> devicesList = [];
    try {
      final String? result =
          await platform.invokeMethod<String>('movella_stopBLEscan');

      final Map<String, dynamic> resultMap = jsonDecode(result!);
      devicesList = jsonDecode(resultMap['devices']);

      movellaStatusStopped = 'Scan completed. Discovered devices: $devicesList';
    } on PlatformException catch (e) {
      movellaStatusStopped =
          "Failed to get movella status stopped: '${e.message}'.";
    }

    setState(() {
      _movellaStatus = movellaStatusStopped;
      _devicesList = devicesList;
    });
  }

  Future<void> _startMeasurement() async {
    String movellaMeasurementStatus;
    try {
      final result =
          await platform.invokeMethod<String>('movella_measurementStart');
      movellaMeasurementStatus = 'Measurement? $result';
    } on PlatformException catch (e) {
      movellaMeasurementStatus =
          "Failed to get movella measurement status stopped: '${e.message}'.";
    }

    setState(() {
      _movellaMeasurementStatus = movellaMeasurementStatus;
    });
  }

  Future<void> _stopMeasurement() async {
    String movellaMeasurementStatus;
    try {
      final result =
          await platform.invokeMethod<String>('movella_measurementStop');
      movellaMeasurementStatus = 'Measurement? $result';
    } on PlatformException catch (e) {
      movellaMeasurementStatus =
          "Failed to get movella measurement status stopped: '${e.message}'.";
    }

    setState(() {
      _movellaMeasurementStatus = movellaMeasurementStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _getBatteryLevel,
              child: const Text('Get Battery Level'),
            ),
            Text(_batteryLevel),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: _startMovellaBLEscan,
                    child: const Text('Start searching'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: _stopMovellaBLEscan,
                    child: const Text('Stop searching'),
                  ),
                ),
              ],
            ),
            Text(_movellaStatus),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: _startMeasurement,
                    child: const Text('Start measurement'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: _stopMeasurement,
                    child: const Text('Stop measurement'),
                  ),
                ),
              ],
            ),
            Text(_movellaMeasurementStatus),
            Expanded(
              child: SizedBox(
                child: ListView.builder(
                  itemCount: _devicesList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 0.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text(_devicesList[index]['device']),
                              subtitle: Text(
                                'Connection State: ${_devicesList[index]['connectionState']}',
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _stopMeasurement,
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
