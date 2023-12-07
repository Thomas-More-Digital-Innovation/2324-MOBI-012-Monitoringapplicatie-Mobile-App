import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/openLogin.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String gebruikersnaam = '';
  String email = '';
  DateTime laatstedata = DateTime.now();
  bool menuIsOpen = false;

  void fillData() {
    setState(() {
      gebruikersnaam = "Seppe Stroobants";
      email = "r0955288@student.thomasmore.be";
    });
  }

  void clearData() {
    setState(() {
      gebruikersnaam = "";
      email = "";
    });
  }

  void submit() {
    Navigator.of(context).pop();
  }

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
            Navigator.pushNamed(context, _routes[i]['route']);
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
          Visibility(visible: menuIsOpen, child: Column(children: _menuItems()))
        ]),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profiel',
                style: TextStyle(
                  color: Colors.black87,
                  letterSpacing: 1.0,
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                )),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Divider(
                color: Colors.black,
                height: 40,
              ),
            ),
            const Text(
              "Gebruikersnaam",
              style: TextStyle(
                color: Colors.black87,
                letterSpacing: 1.0,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5)),
            Text(gebruikersnaam),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Text(
                "E-mailadres",
                style: TextStyle(
                  color: Colors.black87,
                  letterSpacing: 1.0,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5)),
            Text(email),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Text(
                "Laatste data uitgezonden",
                style: TextStyle(
                  color: Colors.black87,
                  letterSpacing: 1.0,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5)),
            Text(laatstedata.toString()), //Just an example
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Divider(
                color: Colors.black,
                height: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 40,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            gebruikersnaam.isEmpty ? Colors.blue : Colors.red,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      onPressed: () {
                        gebruikersnaam.isEmpty
                            ? openLogin(context)
                            : clearData();
                      },
                      child: Text(
                        '${gebruikersnaam.isEmpty ? 'In' : 'Uit'}loggen',
                        style:
                            const TextStyle(fontSize: 20, color: Colors.black),
                      )),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
