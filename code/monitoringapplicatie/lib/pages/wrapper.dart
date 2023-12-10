import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/account.dart';
import 'package:monitoringapplicatie/pages/demo.dart';
import 'package:monitoringapplicatie/pages/firestore_test.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  String gebruikersnaam = '';
  String email = '';
  DateTime laatstedata = DateTime.now();
  bool menuIsOpen = false;

  int _currentIndex = 0;

  final List<Widget> _children = [
    const Account(),
    const Demo(),
    const firestore_test()
  ];

  String toggleMenu() {
    setState(() {
      menuIsOpen = !menuIsOpen;
    });
    return menuIsOpen ? 'Open' : 'Close';
  }

  // Create a list of routes to navigate to together with a name
  final List<Map<String, dynamic>> _routes = [
    {'name': 'Home', 'route': '/'},
    {'name': 'Demo', 'route': '/demo'},
    {'name': 'Firestore test', 'route': '/firestore_test'},
  ];

  // Create a list of widgets to display in the drawer
  List<Widget> _menuItems() {
    List<Widget> items = [];
    for (var i = 0; i < _routes.length; i++) {
      items.add(
        ListTile(
          title: Text(_routes[i]['name']),
          onTap: () {
            // Navigator.pushNamed(context, _routes[i]['route']);
            _currentIndex = i;
            toggleMenu();
          },
        ),
      );
    }
    return items;
  }

  // Use the list of widgets to create a drawer

  @override
  Widget build(BuildContext context) {
    //DateTimeFormat
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          backgroundColor: Colors.white70,
          elevation: 100,
          toolbarHeight: menuIsOpen ? 230 : 60,
          title: Column(children: [
            Row(children: [
              GestureDetector(
                  // When the child is tapped, show a snackbar.
                  onTap: () {
                    SnackBar snackBar = SnackBar(content: Text(toggleMenu()));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  // The custom button
                  child: const Icon(
                    Icons.menu,
                    color: Colors.black87,
                    size: 40.0,
                  )),
              const Spacer(),
              const Text(
                'RevApp',
                style: TextStyle(
                  color: Colors.black87,
                  letterSpacing: 1.0,
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.account_circle,
                color: Colors.black87,
                size: 40.0,
              )
            ]),
            Visibility(
                visible: menuIsOpen, child: Column(children: _menuItems()))
          ]),
        ),
        body: _children[_currentIndex]);
  }
}
