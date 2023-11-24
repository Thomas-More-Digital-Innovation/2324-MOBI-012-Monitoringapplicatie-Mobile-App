import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class firestore_test extends StatelessWidget {
  const firestore_test({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Firestore Test')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => FirebaseFirestore.instance
              .collection('testing')
              .add({'timestamp': Timestamp.fromDate(DateTime.now())}),
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('testing').snapshots(),
          builder: (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot> snapshot,
          ) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (BuildContext context, int index) {
                  final docData = snapshot.data?.docs[index];
                  final DateTime =
                      (docData!['timestamp'] as Timestamp).toDate();
                  return ListTile(
                    title: Text(DateTime.toString()),
                  );
                });
          },
        ),
      ),
    );
  }
}
