import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/account.dart';
import 'package:monitoringapplicatie/pages/demo.dart';

void main() => runApp(MaterialApp(
      initialRoute: '/demo',
      routes: {
        '/': (context) => const Account(),
        '/demo': (context) => const Demo(),
      },
    ));

