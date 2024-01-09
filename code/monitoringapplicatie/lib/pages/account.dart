import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/openLogin.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String gebruikersnaam = '';

  DateTime laatstedata = DateTime.now();
  bool menuIsOpen = false;

  User? user = FirebaseAuth.instance.currentUser;
  // Use the list of widgets to create a drawer

  @override
  Widget build(BuildContext context) {
    //DateTimeFormat
    return Padding(
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
            Text(user!.email!),
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
            const Text(""), //Just an example
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
                        // Log out
                        FirebaseAuth.instance.signOut();
                        // Go to homepage
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Uitloggen',
                        style:
                            const TextStyle(fontSize: 20, color: Colors.black),
                      )),
                ),
              ),
            )
          ],
        ));
  }
}
