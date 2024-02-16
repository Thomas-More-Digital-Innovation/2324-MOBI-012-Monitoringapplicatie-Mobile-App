import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:monitoringapplicatie/pages/openLogin.dart';
import 'package:monitoringapplicatie/pages/sensor_entry.dart'; // For Iconify Widget
import 'package:firebase_core/firebase_core.dart';
import 'package:monitoringapplicatie/firebase_options.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoReal extends StatefulWidget {
  const DemoReal({Key? key}) : super(key: key);

  @override
  _DemoRealState createState() => _DemoRealState();
}

class _DemoRealState extends State<DemoReal> {
  static const platform = MethodChannel('samples.flutter.dev/battery');

  // Get battery level.
  String _batteryLevel = 'Unknown battery level.';
  String _movellaStatus = 'Unknown';
  String _movellaScanStatus = 'Start Scanning';
  String _movellaMeasurementStatus = 'Start Measurement';
  bool _isScanning = false;
  bool _isMeasuring = false;

  List<dynamic> _devicesList = [];

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initMovella();
    _continuousScanning();
    FirebaseAuth.instance.userChanges().listen((User? user) {
      setState(() {
        this.user = user;
      });
    });
  }

  //Function to get the scanned devices continously when button is pressed.
  void _continuousScanning() async {
    while (true) {
      await Future.delayed(
          const Duration(seconds: 1)); // Adjust the delay as needed
      if (_isScanning) {
        await _getScannedDevices();
      }
    }
  }

  //Function to initialize the Movella SDK
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

  //Function to start and stop the bluetooth scanning to the sensors
  Future<void> _startStopMovellaBLEscan() async {
    String movellaStatus;
    String movellaScanStatus = "Start Scanning";
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
    }

    setState(() {
      _movellaStatus = movellaStatus;
      _movellaScanStatus = movellaScanStatus;
      _isScanning = isScanning;
    });
  }

  //This function retrieves the scanned sensors while bluetooth is scanning.
  Future<void> _getScannedDevices() async {
    String movellaStatus;

    try {
      while (_isScanning) {
        _refreshData();
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

  //Function to retrieve the scanned sensors once.
  Future<void> _refreshData() async {
    List<dynamic> devicesList = [];

    final String? result =
        await platform.invokeMethod<String>('movella_getScannedDevices');

    final Map<String, dynamic> resultMap = jsonDecode(result!);
    devicesList = jsonDecode(resultMap['devices']);

    setState(() {
      _devicesList = devicesList;
    });
  }

  //While he is connecting we are going to get the sensor data so we can check if it is connected/disconnected etc.
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
        if (targetDevice != null && targetDevice["connectionState"] != 1) {
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

  //Function to start and stop measuring the sensor data
  Future<void> _startStopMeasurement() async {
    String movellaStatus;
    bool isMeasuring = false;
    try {
      final resultMeasurementStatus =
          await platform.invokeMethod<String>('movella_measurementStatus');

      //resultMeasurementStatus = returns "true" if it is measuring
      //resultMeasurementStatus = return the data measured

      if (resultMeasurementStatus == "true") {
        final result =
            await platform.invokeMethod<Object?>('movella_measurementStop');

        final Map<String, dynamic> resultMap = jsonDecode(result!.toString());

        movellaStatus = "Successful Stopped Measuring";
        isMeasuring = false;

        _storeData(resultMap);
      } else if (resultMeasurementStatus == "false") {
        platform.invokeMethod<List<Object?>>('movella_measurementStart');

        movellaStatus = "Successful Started Measuring";
        isMeasuring = true;
      }
      movellaStatus = "Failed measuring";
    } on PlatformException catch (e) {
      movellaStatus =
          "Failed to get movella measurement status stopped: '${e.message}'.";
    }

    setState(() {
      _movellaStatus = movellaStatus;
      _isMeasuring = isMeasuring;
    });
  }

  //Function to store the data of the sensor to the database
  Future<void> _storeData(Map<String, dynamic> devicesData) async {
    String movellaStatus = "";
    var db = FirebaseFirestore.instance;

    //key = mac-address
    //value = list of all json's with data
    //example of a value ->
    //  [
    //    {"acc":"[3.7674449580987375, -0.8093296429695891, 8.47535722566326]","gyr":"[-1.266379589180661, -5.190715509872905, -1.8257325817304606]","dq":"[0.9999996627997021, -1.8418742439110986E-4, -7.549588833226886E-4, -2.6554201025415604E-4]","dv":"[0.06268050157134615, -0.013479457756640946, 0.14130578603789057]","mag":"[-0.67626953125, 0.309326171875, -1.299072265625]","quat":"[0.9629901, -0.07156744, -0.20010701, -0.16578718]","sampleTimeFine":"26316767","packetCounter":"2"},
    //    {"acc":"[4.03347615246122, -0.6100883697264956, 8.285631377517362]","gyr":"[-1.3527645969724924, -4.333649936073944, 0.3888939120004087]","dq":"[0.9999997804032954, -1.967516207778638E-4, -6.303037873068852E-4, 5.656232257110158E-5]","dv":"[0.0671381167869458, -0.01013716436824352, 0.13813818841240144]","mag":"[-0.677734375, 0.310302734375, -1.299072265625]","quat":"[0.96328723, -0.073414296, -0.1981214, -0.1656382]","sampleTimeFine":"26333434","packetCounter":"3"}
    //  ]
    devicesData.forEach((key, value) async {
      List<dynamic> data = jsonDecode(value);
      var lastSessionNumber = 1;

      // Create a new batch for each iteration because error: "Error during batch set: Bad state: This batch has already been committed and can no longer be changed."
      var batch = db.batch();

      await db
          .collection("sd-dummy-users")
          .doc(user!.uid)
          .collection("sensors")
          .doc(key)
          .get()
          .then((documentSnapshot) {
        //If already data in DB
        if (documentSnapshot.exists) {
          Map<String, dynamic> docData =
              documentSnapshot.data() as Map<String, dynamic>;
          lastSessionNumber = docData["lastSessionNumber"] + 1;
        }

        batch.set(
          db
              .collection("sd-dummy-users")
              .doc(user!.uid)
              .collection("sensors")
              .doc(key),
          {"lastSessionNumber": lastSessionNumber},
        );

        for (var entry in data) {
          // Convert the entry(json) to a Map
          Map<String, dynamic> entryMap = entry;
          // Add a new field to the entry
          entryMap['sessionTime'] = '${DateTime.now()}';
          try {
            batch.set(
              db
                  .collection("sd-dummy-users")
                  .doc(user!.uid)
                  .collection("sensors")
                  .doc(key)
                  .collection("session$lastSessionNumber")
                  .doc(),
              entryMap,
            );
          } catch (e) {
            debugPrint("Error during batch set: $e");
          }
        }
      });

      await batch.commit().then((_) {
        movellaStatus = "Database commit successful";
      }).catchError((error) {
        movellaStatus = "Error during database commit: $error";
      });
    });

    setState(() {
      _movellaStatus = movellaStatus;
    });
  }

  SensorConnectionState _getTranslatedConnectionState(int connectionState) {
    switch (connectionState) {
      case 0:
        return SensorConnectionState.disconnected;
      case 1:
        return SensorConnectionState.connecting;
      case 2:
        return SensorConnectionState.connected;
      case 3 | 4 | 5:
        return SensorConnectionState.reconnecting;
      default:
        return SensorConnectionState.notPaired;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      child: Column(children: [
        Visibility(
            // Visibility is used to hide the widget when the user is not logged in
            visible: user != null ? false : true,
            child: SizedBox(
                height: 170,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                        margin: const EdgeInsets.all(10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Iconify(Mdi.warning,
                                color: Colors.white, size: 50),
                            const SizedBox(width: 20),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Je bent niet ingelogd.",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 25)),
                                  const Spacer(),
                                  const Text(
                                      "Je moet ingelogd zijn om data te versturen naar de server.",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18)),
                                  const Spacer(),
                                  ElevatedButton(
                                      child: const Text("Log in",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22)),
                                      onPressed: () {
                                        openLogin(context);
                                      }),
                                ],
                              ),
                            ),
                          ],
                        ))))),
        const SizedBox(height: 20),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text("Acties",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Colors.black)),
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.black12),
                      top: BorderSide(color: Colors.black12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    children: [
                      ElevatedButton(
                          child: Text(_isScanning ? "Stop scan" : "Start scan",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 22)),
                          onPressed: () {
                            _startStopMovellaBLEscan();
                          }),
                      const Spacer(),
                      if (user != null)
                        ElevatedButton(
                            child: Text(
                                _isMeasuring ? "Stop meten" : "Start meten",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 22)),
                            onPressed: () {
                              _startStopMeasurement();
                            }),
                    ],
                  ),
                ),
              )
            ]),
        const SizedBox(height: 20),
        Flexible(
          child: ListView.builder(
            itemCount: _devicesList.length,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                child: SensorEntry(
                    name: _devicesList[index]['name'],
                    mac: _devicesList[index]['device'],
                    connectionStatus: _getTranslatedConnectionState(
                        _devicesList[index]['connectionState']),
                    buttonConnectOnPressed: () {
                      platform.invokeMethod('connectSensor',
                          {'MacAddress': _devicesList[index]['device']});
                      _getConnectionState(_devicesList[index]['device'],
                          _devicesList[index]['connectionState']);
                    },
                    buttonDisconnectOnPressed: () {
                      platform.invokeMethod('disconnectSensor',
                          {'MacAddress': _devicesList[index]['device']});
                      _getConnectionState(_devicesList[index]['device'],
                          _devicesList[index]['connectionState']);
                    }),
              );
            },
          ),
        ),
      ]),
    );
  }
}
