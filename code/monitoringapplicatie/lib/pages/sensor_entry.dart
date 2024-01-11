import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/jam.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/mi.dart';
import 'package:iconify_flutter/icons/wpf.dart';

enum SensorConnectionState {
  connected,
  connecting,
  disconnected,
  reconnecting,
  notPaired
}

class SensorEntry extends StatelessWidget {
  final String name;
  final String mac;
  final SensorConnectionState connectionStatus;
  final VoidCallback? buttonConnectOnPressed;
  final VoidCallback? buttonDisconnectOnPressed;

  const SensorEntry({
    Key? key,
    required this.name,
    required this.mac,
    required this.connectionStatus,
    this.buttonConnectOnPressed,
    this.buttonDisconnectOnPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 70,
        child: DecoratedBox(
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 1.0),
                )),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text
                  Flexible(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24)),
                        Text(mac),
                      ])),
                  const SizedBox(width: 10),
                  // Actions
                  if (connectionStatus != SensorConnectionState.disconnected &&
                      connectionStatus != SensorConnectionState.notPaired)
                    Row(children: [
                      IconButton(
                          onPressed: () {},
                          icon: Iconify(
                            Mdi.compass,
                            color: Colors.black.withOpacity(0.2),
                            size: 30,
                          )),
                      SizedBox(
                          height: 30,
                          width: 30,
                          child: SizedBox(
                              height: 30,
                              width: 30,
                              child: Stack(
                                children: [
                                  Visibility(
                                      visible: connectionStatus ==
                                          SensorConnectionState.reconnecting,
                                      child: const Positioned(
                                          child: Iconify(Mdi.warning,
                                              size: 12, color: Colors.red))),
                                  Visibility(
                                      visible: connectionStatus ==
                                          SensorConnectionState.connecting,
                                      child: const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))),
                                  const Iconify(
                                    Jam.signal,
                                    size: 30,
                                  )
                                ],
                              ))),
                      IconButton(
                          onPressed: () {
                            buttonDisconnectOnPressed?.call();
                          },
                          icon: const Iconify(Wpf.disconnected, size: 30)),
                    ]),
                  if (connectionStatus == SensorConnectionState.notPaired ||
                      connectionStatus == SensorConnectionState.disconnected)
                    ElevatedButton(
                        child: const Text("Connect"),
                        onPressed: () {
                          buttonConnectOnPressed?.call();
                        })
                ])));
  }
}
