import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/account.dart';

void main() => runApp(MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const Account(),
      },
    ));
