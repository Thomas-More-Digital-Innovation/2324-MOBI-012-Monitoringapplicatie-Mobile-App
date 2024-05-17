import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future openLogin(BuildContext context) async {
  String email = '';
  String password = '';

  Future<void> updateLastLoggedIn(String userId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('sd-dummy-users')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'lastSignedIn': Timestamp.now(),
        });
      } else {
        print('Document niet gevonden voor userId: $userId');
      }
    } catch (e) {
      print("Fout bij bijwerken laatste keer aangemeld: $e");
    }
  }

  Future<void> updateIsSignedIn(String userId, bool value) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('sd-dummy-users')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'isSignedIn': value,
        });
      } else {
        print('Document niet gevonden voor userId: $userId');
      }
    } catch (e) {
      print("Fout bij bijwerken isSignedIn: $e");
    }
  }

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
                  height: 60, // Increase the height
                  child: TextField(
                    onChanged: (value) {
                      password = value;
                    },
                    obscureText: true,
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
                        try {
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                          User? user = FirebaseAuth.instance.currentUser;

                          if (user != null) {
                            await updateLastLoggedIn(user.uid);
                            await updateIsSignedIn(user.uid, true);
                          }

                          // Close the current dialog
                          Navigator.pop(context);

                          debugPrint(
                              "Aanmelding succesvol, voer hier verdere acties uit indien nodig");
                        } catch (e) {
                          // Er is een fout opgetreden bij de aanmelding, verwerk de fout hier
                          debugPrint("Fout bij aanmelden: $e");
                        }
                        //submit();
                      },
                      child: const Text('Login')),
                ),
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
