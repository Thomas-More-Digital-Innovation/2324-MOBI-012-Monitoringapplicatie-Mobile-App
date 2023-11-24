import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/account.dart';
import 'package:flutter/services.dart';

void main() => runApp(MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const Account(),
      },
    ));