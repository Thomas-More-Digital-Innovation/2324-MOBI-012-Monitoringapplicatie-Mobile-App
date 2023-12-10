import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/account.dart';
import 'package:monitoringapplicatie/pages/demo.dart';
import 'package:monitoringapplicatie/pages/firestore_test.dart';
import 'package:monitoringapplicatie/pages/wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    initialRoute: '/',
    routes: {'/': (context) => const Wrapper()},
  ));
}
