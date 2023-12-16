import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/firebase_options.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String _movellaScanStatus = 'Start Scanning';
  String _movellaMeasurementStatus = 'Unknown';
  bool _isScanning = false;

  List<dynamic> _devicesList = [];

  @override
  void initState() {
    super.initState();
    _initMovella();
    _continuousScanning();
  }

  //Function to get the scanned devices continously when button is pressed
  void _continuousScanning() async {
    while (true) {
      await Future.delayed(
          const Duration(seconds: 1)); // Adjust the delay as needed
      if (_isScanning) {
        await _getScannedDevices();
      }
    }
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

  Future<void> _startStopMovellaBLEscan() async {
    String movellaStatus;
    String movellaScanStatus;
    bool isScanning = false;
    try {
      //result[0] = returns "true" if it is scanning
      //result[1] = return the status
      final result = await platform
          .invokeMethod<List<Object?>>('movella_start_stop_BLEscan');

      //If scanning -> text on button = "Stop Scanning"
      if (result![0] == "true") {
        movellaScanStatus = "Stop Scanning";
        isScanning = true;
      } else {
        isScanning = false;
        movellaScanStatus = "Start Scanning";
      }
      movellaStatus = result[1].toString();
    } on PlatformException catch (e) {
      movellaStatus = "Failed to BLE scan: '${e.message}'.";
      movellaScanStatus = "Failed";
    }

    setState(() {
      _movellaStatus = movellaStatus;
      _movellaScanStatus = movellaScanStatus;
      _isScanning = isScanning;
    });
  }

  Future<void> _getScannedDevices() async {
    String movellaStatus;
    List<dynamic> devicesList = [];

    try {
      while (_isScanning) {
        final String? result =
            await platform.invokeMethod<String>('movella_getScannedDevices');

        final Map<String, dynamic> resultMap = jsonDecode(result!);
        devicesList = jsonDecode(resultMap['devices']);

        setState(() {
          _devicesList = devicesList;
        });

        await Future.delayed(
            const Duration(seconds: 1)); // Adjust the delay as needed
      }
    } on PlatformException catch (e) {
      movellaStatus = "Failed to get scanned devices: '${e.message}'.";
      setState(() {
        _movellaStatus = movellaStatus;
      });
    }
  }

  Future<void> _refreshData() async {
    List<dynamic> devicesList = [];

    final String? result =
        await platform.invokeMethod<String>('movella_getScannedDevices');

    final Map<String, dynamic> resultMap = jsonDecode(result!);
    devicesList = jsonDecode(resultMap['devices']);

    debugPrint(devicesList.toString());

    setState(() {
      _devicesList = devicesList;
    });
  }

  //While he is connecting we are going to get the sensor data like connectionstate so we can check if it is connected/disconnected
  Future<void> _getConnectionState(
      String macAddress, int connectionState) async {
    String movellaStatus;
    List<dynamic> devicesList = [];
    bool isChangingConnectionState = true;

    try {
      while (isChangingConnectionState) {
        final String? result =
            await platform.invokeMethod<String>('movella_getScannedDevices');

        final Map<String, dynamic> resultMap = jsonDecode(result!);
        devicesList = jsonDecode(resultMap['devices']);

        dynamic targetDevice = devicesList.firstWhere((device) {
          return device['device'] == macAddress;
        }, orElse: () => null);

        setState(() {
          _devicesList = devicesList;
        });

        //if it is stopped with "connecting" we are going to stop getting the sensor data ('1' means connecting)
        if (targetDevice["connectionState"] != 1) {
          Future.delayed(const Duration(seconds: 3)).then((_) =>
              isChangingConnectionState =
                  false); // Wait 3 seconds before stop getting the data of the sensors because we are also getting data like battery percentage which takes some time
        }
      }
    } on PlatformException catch (e) {
      movellaStatus = "Failed to get scanned devices: '${e.message}'.";
      setState(() {
        _movellaStatus = movellaStatus;
      });
    }
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
          await platform.invokeMethod<List<Object?>>('movella_measurementStop');
      movellaMeasurementStatus = 'Measurement?${result![0]}';

      final Map<String, dynamic> resultMap = jsonDecode(result[1].toString());

      _storeData(resultMap);
    } on PlatformException catch (e) {
      movellaMeasurementStatus =
          "Failed to get movella measurement status stopped: '${e.message}'.";
    }

    setState(() {
      _movellaMeasurementStatus = movellaMeasurementStatus;
    });
  }

  Future<void> _storeData(Map<String, dynamic> devicesData) async {
    String movellaMeasurementStatus = "";
    var db = FirebaseFirestore.instance;

    //key = mac-address
    //value = list of all json's with data
    //example of a value ->
    //  [
    //    {"acc":"[3.7674449580987375, -0.8093296429695891, 8.47535722566326]","gyr":"[-1.266379589180661, -5.190715509872905, -1.8257325817304606]","dq":"[0.9999996627997021, -1.8418742439110986E-4, -7.549588833226886E-4, -2.6554201025415604E-4]","dv":"[0.06268050157134615, -0.013479457756640946, 0.14130578603789057]","mag":"[-0.67626953125, 0.309326171875, -1.299072265625]","quat":"[0.9629901, -0.07156744, -0.20010701, -0.16578718]","sampleTimeFine":"26316767","packetCounter":"2"},
    //    {"acc":"[4.03347615246122, -0.6100883697264956, 8.285631377517362]","gyr":"[-1.3527645969724924, -4.333649936073944, 0.3888939120004087]","dq":"[0.9999997804032954, -1.967516207778638E-4, -6.303037873068852E-4, 5.656232257110158E-5]","dv":"[0.0671381167869458, -0.01013716436824352, 0.13813818841240144]","mag":"[-0.677734375, 0.310302734375, -1.299072265625]","quat":"[0.96328723, -0.073414296, -0.1981214, -0.1656382]","sampleTimeFine":"26333434","packetCounter":"3"}
    //  ]
    devicesData.forEach((key, value) async {
      final now = DateTime.now();
      List<dynamic> data = jsonDecode(value);
      var lastSessionNumber = 0;
      debugPrint(key);

      // Create a new batch for each iteration because error: "Error during batch set: Bad state: This batch has already been committed and can no longer be changed."
      var batch = db.batch();

      await db
          .collection("sd-dummy-users")
          .doc("NNOc3lVy9cVuyhF60YctkMXPJw23")
          .collection("sensors")
          .doc(key)
          .get()
          .then((documentSnapshot) {
        //If already data in DB
        if (documentSnapshot.exists) {
          Map<String, dynamic> docData =
              documentSnapshot.data() as Map<String, dynamic>;
          lastSessionNumber = docData["lastSessionNumber"];
        }

        for (var entry in data) {
          try {
            batch.set(
              db
                  .collection("sd-dummy-users")
                  .doc("NNOc3lVy9cVuyhF60YctkMXPJw23")
                  .collection("sensors")
                  .doc(key),
              {"lastSessionNumber": lastSessionNumber + 1},
            );
            batch.set(
              db
                  .collection("sd-dummy-users")
                  .doc("NNOc3lVy9cVuyhF60YctkMXPJw23")
                  .collection("sensors")
                  .doc(key)
                  .collection("session${lastSessionNumber + 1}")
                  .doc(),
              entry,
            );
            lastSessionNumber += 1;
          } catch (e) {
            debugPrint("Error during batch set: $e");
          }
        }
        print('${documentSnapshot.id} => ${lastSessionNumber.toString()}');
      });
      await batch.commit().then((_) {
        movellaMeasurementStatus = "Database commit successful";
      }).catchError((error) {
        movellaMeasurementStatus = "Error during database commit: $error";
      });
    });

    setState(() {
      _movellaMeasurementStatus = movellaMeasurementStatus;
    });
  }

  String _getTranslatedConnectionState(int connectionState) {
    switch (connectionState) {
      case 0:
        return "Disconnected";
      case 1:
        return "Connecting";
      case 2:
        return "Connected";
      case 3 | 4 | 5:
        return "Reconnecting";
      default:
        return "null";
    }
  }

  ElevatedButton _getConnectionButton(int connectionState, int index) {
    switch (connectionState) {
      case 0:
        return ElevatedButton(
          onPressed: () => {
            platform.invokeMethod(
                'connectSensor', {'MacAddress': _devicesList[index]['device']}),
            _getConnectionState(_devicesList[index]['device'],
                _devicesList[index]['connectionState'])
          },
          child: const Text("Connect"),
        );
      case 2:
        return ElevatedButton(
          onPressed: () => {
            platform.invokeMethod('disconnectSensor',
                {'MacAddress': _devicesList[index]['device']}),
            _getConnectionState(_devicesList[index]['device'],
                _devicesList[index]['connectionState'])
          },
          child: const Text("Disconnect"),
        );
      default:
        return ElevatedButton(
          onPressed: null,
          child: Text(_getTranslatedConnectionState(connectionState)),
        );
    }
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
                    onPressed: _startStopMovellaBLEscan,
                    child: Text(_movellaScanStatus),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text("refresh"),
                  ),
                ),
              ],
            ),
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connection State: ${_getTranslatedConnectionState(_devicesList[index]['connectionState'])}',
                                  ),
                                  if (_devicesList[index]
                                          ['batteryPercentage'] !=
                                      -1)
                                    Text(
                                      'Battery Percentage: ${_devicesList[index]['batteryPercentage']}%',
                                    ),
                                ],
                              ),
                            ),
                          ),
                          _getConnectionButton(
                              _devicesList[index]['connectionState'], index)
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
