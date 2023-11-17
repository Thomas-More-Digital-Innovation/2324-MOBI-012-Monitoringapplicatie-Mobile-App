import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/account.dart';
import 'package:monitoringapplicatie/demo.dart';

void main() => runApp(MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => Account(),
      },
    ));
