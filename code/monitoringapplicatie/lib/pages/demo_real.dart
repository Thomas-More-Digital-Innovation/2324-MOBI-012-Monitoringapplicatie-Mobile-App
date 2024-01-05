import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:monitoringapplicatie/pages/sensor_entry.dart'; // For Iconify Widget

class DemoReal extends StatefulWidget {
  const DemoReal({Key? key}) : super(key: key);

  @override
  _DemoRealState createState() => _DemoRealState();
}

// Row entry
Widget Entry(String title, String value) {
  return Row(
    children: [
      Text(title),
      const Spacer(),
      Text(value),
    ],
  );
}

class _DemoRealState extends State<DemoReal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      child: Column(children: [
        Visibility(
            // Visibility is used to hide the widget when the user is not logged in
            visible: true,
            child: SizedBox(
                height: 150,
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
                            SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Je bent niet ingelogd.",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 25)),
                                const Spacer(),
                                const Text("Je moet ingelogd zijn om data",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                                const Text("te versturen naar de server.",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                                const Spacer(),
                                ElevatedButton(
                                    child: const Text("Log in",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22)),
                                    onPressed: () {}),
                              ],
                            ),
                          ],
                        ))))),
        const Column(children: [
          SensorEntry(
            name: "Sensor 1 - Connected",
            mac: "00:00:00:00:00:00",
            connectionStatus: SensorConnectionState.connected,
          ),
          SensorEntry(
            name: "Sensor 2 - Reconnecting",
            mac: "00:00:00:00:00:00",
            connectionStatus: SensorConnectionState.reconnecting,
          ),
          SensorEntry(
            name: "Sensor 3 - Disconnected",
            mac: "00:00:00:00:00:00",
            connectionStatus: SensorConnectionState.disconnected,
          ),
          SensorEntry(
            name: "Sensor 4 - Connecting",
            mac: "00:00:00:00:00:00",
            connectionStatus: SensorConnectionState.connecting,
          ),
          SensorEntry(
              name: "Sensor 5 - Not paired",
              mac: "00:00:00:00:00:00",
              connectionStatus: SensorConnectionState.notPaired),
        ]),
      ]),
    );
  }
}
