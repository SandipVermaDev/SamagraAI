// This is a basic Flutter widget test for SamagraAI chat app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:samagra_app/main.dart';

void main() {
  testWidgets('SamagraAI app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SamagraAIApp());

    // Verify that our chat app loads properly.
    await tester.pumpAndSettle();

    // Check that the app bar title is present
    expect(find.text('SamagraAI'), findsOneWidget);

    // Check that the input bar is present
    expect(find.byType(TextField), findsOneWidget);

    // Verify the send button is present
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
