import 'package:flutter/material.dart';
import 'package:monitoringapplicatie/login.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String gebruikersnaam = '';
  String email = '';
  DateTime laatstedata = DateTime.now();

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

  Future openLogin() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aanmelden',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: Divider(
                    color: Colors.black,
                    height: 40,
                  ),
                ),
                Text(
                  "E-mailadres",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          content: const SizedBox(
            width: 400,
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromARGB(255, 234, 233, 233),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                          onPressed: () {
                            submit();
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

  void submit() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    //DateTimeFormat
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'RevAPP',
            style: TextStyle(color: Colors.black87),
          ),
          centerTitle: true,
          backgroundColor: Colors.white70,
          elevation: 0,
        ),
        body: Padding(
            padding: EdgeInsets.fromLTRB(30, 40, 30, 0),
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
                            backgroundColor: gebruikersnaam.isEmpty
                                ? Colors.blue
                                : Colors.red,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                          onPressed: () {
                            gebruikersnaam.isEmpty ? openLogin() : clearData();
                          },
                          child: Text(
                            '${gebruikersnaam.isEmpty ? 'In' : 'Uit'}loggen',
                            style: const TextStyle(fontSize: 20),
                          )),
                    ),
                  ),
                )
              ],
            )));
  }
}
