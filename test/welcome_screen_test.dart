import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/ui/widgets/welcome_screen.dart';

void main() {
  Widget buildWidget() {
    return const MaterialApp(
      home: Scaffold(body: WelcomeScreen()),
    );
  }

  testWidgets('renders app title', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.text('Cribbage'), findsOneWidget);
  });

  testWidgets('renders subtitle', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.text('Classic Card Game'), findsOneWidget);
  });

  testWidgets('renders welcome heading', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.text('Welcome!'), findsOneWidget);
  });

  testWidgets('renders 121 point goal description', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(
      find.textContaining('121'),
      findsWidgets,
    );
  });

  testWidgets('renders start instruction hint', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.textContaining('Start New Game'), findsOneWidget);
  });
}
