import 'package:flutter/material.dart';

Future openLogin(BuildContext context) async {
  return await showDialog(
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
        height: 60, // Increase the height
        child: TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Color.fromARGB(255, 193, 190, 190),
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
