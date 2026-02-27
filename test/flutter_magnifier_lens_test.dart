import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_magnifier_lens/flutter_magnifier_lens.dart';

void main() {
  group('MagnifierLens Widget Tests', () {
    testWidgets('renders child widget correctly', (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: MagnifierLens(
                contentKey: key,
                child: const Text('Magnifier Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Magnifier Content'), findsOneWidget);
      expect(find.byType(MagnifierLens), findsOneWidget);
    });

    testWidgets('when activated is false, renders only child', (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: MagnifierLens(
                contentKey: key,
                activated: false,
                child: const Text('Inactive Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Inactive Content'), findsOneWidget);
      // It still renders MagnifierLens, but not the stack inside since it early returns
      // Note: we're checking for Stack because MagnifierLens uses a Stack usually.
      expect(find.byType(Stack), findsNothing);
    });

    testWidgets('has default parameters', (WidgetTester tester) async {
      final key = GlobalKey();
      final lens = MagnifierLens(
        contentKey: key,
        child: const SizedBox(),
      );

      expect(lens.lensPosition, const Offset(200, 200));
      expect(lens.lensRadius, 100.0);
      expect(lens.distortion, 0.5);
      expect(lens.magnification, 1.5);
      expect(lens.aberration, 0.05);
      expect(lens.showBorder, true);
      expect(lens.borderColor, Colors.white);
      expect(lens.borderWidth, 3.0);
    });
  });
}
