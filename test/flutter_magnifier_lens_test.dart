
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_magnifier_lens/flutter_magnifier_lens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Tests de rendu de base (Widget Tests)', () {
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
      // MagnifierLens early returns child, so Stack is not built
      final stackFinder = find.descendant(
        of: find.byType(MagnifierLens),
        matching: find.byType(Stack),
      );
      expect(stackFinder, findsNothing);
    });

    testWidgets('when activated is true, Stack is rendered', (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: MagnifierLens(
                contentKey: key,
                activated: true,
                child: const Text('Active Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Active Content'), findsOneWidget);
      // MagnifierLens builds a Stack
      expect(find.byType(Stack), findsWidgets); // Can be multiple Stacks in MaterialApp, but at least one from our widget
      
      final stackFinder = find.descendant(
        of: find.byType(MagnifierLens), 
        matching: find.byType(Stack),
      );
      expect(stackFinder, findsOneWidget);
    });
  });

  group('2. Tests du Cycle de Vie et Fuites de Mémoire', () {
    testWidgets('Timer is cancelled on dispose without setState errors', (WidgetTester tester) async {
      final key = GlobalKey();
      bool showMagnifier = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: showMagnifier
                    ? RepaintBoundary(
                        key: key,
                        child: MagnifierLens(
                          contentKey: key,
                          child: const Text('Content to remove'),
                        ),
                      )
                    : const SizedBox(),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      showMagnifier = false;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Content to remove'), findsOneWidget);

      // We wait to ensure timer ticks at least once.
      await tester.pump(const Duration(milliseconds: 100));

      // Remove the MagnifierLens from the tree to trigger dispose
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Content to remove'), findsNothing);
      expect(find.byType(MagnifierLens), findsNothing);
      
      // Wait to see if timer triggers any pending setState that would crash
      await tester.pump(const Duration(milliseconds: 200));
      
      // Test will fail organically if setState is called after dispose.
      expect(tester.takeException(), isNull);
    });
  });

  group('3. Tests sur le peintre (Painter ShouldRepaint)', () {
    testWidgets('Painter delegates are structurally evaluated', (WidgetTester tester) async {
      // Dart restricts private class access. We verify widget property propagation instead.
      final key = GlobalKey();
      
      Widget buildMagnifier(double radius) {
         return MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: MagnifierLens(
                contentKey: key,
                lensRadius: radius,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildMagnifier(100.0));
      expect(find.byType(MagnifierLens), findsOneWidget);

      // Rebuilding with different radius property
      await tester.pumpWidget(buildMagnifier(150.0));
      
      final MagnifierLens lens = tester.widget(find.byType(MagnifierLens));
      expect(lens.lensRadius, 150.0);
    });
  });

  group('4. Tests aux limites et robustesse', () {
    testWidgets('Zero size RepaintBoundary does not crash', (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 0,
              height: 0,
              child: RepaintBoundary(
                key: key,
                child: MagnifierLens(
                  contentKey: key,
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );

      // Wait for timer capture
      await tester.pump(const Duration(milliseconds: 100));
      // Should not throw exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('Missing content key gracefully handles capture', (WidgetTester tester) async {
      final nonAttachedKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MagnifierLens(
              contentKey: nonAttachedKey, // no RepaintBoundary attached to this key
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // Wait for timer capture attempt
      await tester.pump(const Duration(milliseconds: 100));
      // Should not throw exception
      expect(tester.takeException(), isNull);
    });
  });
}
