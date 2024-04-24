import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  const Account({Key? key}) : super(key: key);

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  User? user = FirebaseAuth.instance.currentUser;

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

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!, password: currentPassword);
      await user!.reauthenticateWithCredential(credential);
      await user!.updatePassword(newPassword);
      print("Wachtwoord succesvol gewijzigd!");

      // Toon succesbericht aan gebruiker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wachtwoord succesvol gewijzigd!"),
        ),
      );
    } catch (e) {
      print("Fout bij wachtwoord wijzigen: $e");
      // Toon foutmelding aan gebruiker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fout bij wachtwoord wijzigen. Probeer het opnieuw."),
        ),
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    String? currentPassword =
        await _showPasswordInputDialog(context, "Huidig wachtwoord");
    if (currentPassword != null) {
      try {
        final AuthCredential credential = EmailAuthProvider.credential(
            email: user!.email!, password: currentPassword);
        await user!.reauthenticateWithCredential(credential);

        String? newPassword =
            await _showPasswordInputDialog(context, "Nieuw wachtwoord");
        if (newPassword != null) {
          await changePassword(currentPassword, newPassword);
        }
      } catch (e) {
        print("Fout bij re-authenticatie: $e");
        // Toon foutmelding aan gebruiker
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Fout bij re-authenticatie. Controleer uw wachtwoord."),
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordInputDialog(
      BuildContext context, String title) async {
    TextEditingController _passwordController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(hintText: 'Wachtwoord'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Annuleer
              },
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: () {
                String password = _passwordController.text.trim();
                Navigator.of(context).pop(password); // Geef wachtwoord terug
              },
              child: const Text('Bevestigen'),
            ),
          ],
        );
      },
    );
  }

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profiel',
            style: TextStyle(
              color: Colors.black87,
              letterSpacing: 1.0,
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          const Text("N.v.t"), // Just an example
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: Divider(
              color: Colors.black,
              height: 40,
            ),
          ),
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 300,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      textStyle:
                          const TextStyle(fontSize: 20, color: Colors.white),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    onPressed: () async {
                      await _changePassword(context);
                    },
                    child: const Text(
                      'Wachtwoord wijzigen',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(
                    height: 10), // Add some space between the buttons
                SizedBox(
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
                    onPressed: () async {
                      // Log out
                      await FirebaseAuth.instance.signOut();
                      await updateIsSignedIn(user!.uid, false);
                      // Go to homepage
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Uitloggen',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
