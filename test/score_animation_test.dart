import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/ui/widgets/score_animation.dart';

void main() {
  Widget buildWidget({
    int points = 2,
    bool isPlayer = true,
    VoidCallback? onAnimationComplete,
    Color? color,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ScoreAnimationWidget(
          points: points,
          isPlayer: isPlayer,
          onAnimationComplete: onAnimationComplete ?? () {},
          color: color,
        ),
      ),
    );
  }

  testWidgets('displays correct point label', (tester) async {
    await tester.pumpWidget(buildWidget(points: 5));
    expect(find.text('+5'), findsOneWidget);
  });

  testWidgets('displays point label for opponent', (tester) async {
    await tester.pumpWidget(buildWidget(points: 3, isPlayer: false));
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('calls onAnimationComplete after animation finishes',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(
      buildWidget(
        points: 2,
        onAnimationComplete: () => completed = true,
      ),
    );

    // Advance past the 2500ms animation duration
    await tester.pump(const Duration(milliseconds: 2600));

    expect(completed, isTrue);
  });

  testWidgets('accepts custom color without error', (tester) async {
    await tester.pumpWidget(
      buildWidget(points: 4, color: Colors.purple),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without error when isPlayer is false', (tester) async {
    await tester.pumpWidget(buildWidget(isPlayer: false));
    expect(tester.takeException(), isNull);
  });
}
