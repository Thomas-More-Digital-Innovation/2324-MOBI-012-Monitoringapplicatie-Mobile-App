import 'package:flutter_test/flutter_test.dart';
import 'package:monitoringapplicatie/pages/demo.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Test initial SDK testing page values', (tester) async {
    // Create the widget by telling the tester to build it.

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyHomePage(title: 'Title'),
        ),
      ),
    );

    final textFinder = find.text('Unknown battery level.');
    final measureMentTextFinder = find.text('Unknown');

    expect(textFinder, findsOneWidget);
    expect(measureMentTextFinder, findsExactly(2));
    // final sdkTextFinder = find.text('2023 1.0');
    // expect(sdkTextFinder, findsOneWidget);
  });
}
