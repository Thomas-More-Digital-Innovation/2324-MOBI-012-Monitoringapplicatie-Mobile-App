import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future openLogin(BuildContext context) async {
  String email = '';
  String password = '';

  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Aanmelden',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          verticalDirection: VerticalDirection.down,
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: Text(
                    'E-mailadres',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 400,
                  height: 60, // Increase the height
                  child: TextField(
                    onChanged: (value) {
                      email = value;
                    },
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 193, 190, 190),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: Text(
                    'Wachtwoord',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 400,
                  height: 60,
                  child: TextField(
                    onChanged: (value) {
                      password = value;
                    },
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 193, 190, 190),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(16, 16, 16, 16), // Adjust padding as needed
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (email.isNotEmpty && password.isNotEmpty) {
                          try {
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            // Close the current dialog
                            Navigator.pop(context);

                            debugPrint(
                                "Aanmelding succesvol, voer hier verdere acties uit indien nodig");
                          } catch (e) {
                            // Er is een fout opgetreden bij de aanmelding, verwerk de fout hier
                            debugPrint("Fout bij aanmelden: $e");
                          }
                        } else {
                          debugPrint("Email en wachtwoord zijn verplicht.");
                        }
                      },
                      child: const Text('Login'),
                    )),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: Text(
                  "Heb je nog geen login? Vraag dit dan aan bij je contactpersoon.",
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              )
            ],
          ),
        )
      ],
    ),
  );
}
