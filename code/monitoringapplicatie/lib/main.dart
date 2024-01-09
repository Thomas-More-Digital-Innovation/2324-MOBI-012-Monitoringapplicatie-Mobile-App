import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/account.dart';
import 'package:monitoringapplicatie/pages/demo.dart';
import 'package:monitoringapplicatie/pages/demo_real.dart';
import 'package:monitoringapplicatie/pages/firestore_test.dart';
import 'package:monitoringapplicatie/pages/Navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    initialRoute: '/demo_real',
    routes: {
      '/': (context) => const NavBar(child: Account()),
      '/demo': (context) => const NavBar(child: Demo()),
      '/demo_real': (context) => const NavBar(child: DemoReal()),
      '/firestore_test': (context) => const NavBar(child: firestore_test()),
      '/account': (context) => const NavBar(child: Account()),
    },
  ));
}
