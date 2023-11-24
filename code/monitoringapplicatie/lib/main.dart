import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/account.dart';
import 'package:flutter/services.dart';
import 'package:monitoringapplicatie/pages/firestore_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => const firestore_test(),
    },
  ));

}

//void main() => runApp(MaterialApp(
//      initialRoute: '/',
//      routes: {
//        '/': (context) => const Account(),
//      },
//    ));
