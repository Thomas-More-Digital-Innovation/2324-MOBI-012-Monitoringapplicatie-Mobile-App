import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/pages/openLogin.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.userChanges().listen((User? user) {
      setState(() {
        this.user = user;
      });
    });
  }

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

            // If user is null, show nothing, else show username
            Text(user != null && user!.displayName != null
                ? user!.displayName!
                : 'Geen gebruikersnaam ingesteld'),
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
            // If user is null, show nothing, else show email
            Text(user != null ? user!.email! : ''),
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
            const Text("N.v.t"), //Just an example
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Divider(
                color: Colors.black,
                height: 40,
              ),
            ),
            Center(
              child: SizedBox(
                width: 300,
                height: 40,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      textStyle:
                          const TextStyle(fontSize: 20, color: Colors.white),
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
                    child: const Text(
                      'Uitloggen',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    )),
              ),
            )
          ],
        ));
  }
}
