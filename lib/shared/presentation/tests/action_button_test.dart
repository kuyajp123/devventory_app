// Colocated tests are dev-only and are never imported by the application.
// ignore_for_file: depend_on_referenced_packages
import 'package:devventory_app/app/app_theme.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> showButton(
  WidgetTester tester, {
  required VoidCallback? onPressed,
  bool busy = false,
  bool reduceMotion = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: companionTheme(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 280,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ActionButton(
                label: 'Continue',
                busy: busy,
                onPressed: onPressed,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a quick touch starts feedback before the native tap timeout', (
    tester,
  ) async {
    var activations = 0;
    await showButton(tester, onPressed: () => activations++);
    final label = find.text('Continue');
    final resting = tester.getTopLeft(label).dy;
    final gesture = await tester.startGesture(tester.getCenter(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(label).dy, greaterThan(resting));
    expect(activations, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(activations, 1);
  });
  testWidgets('face depresses without resizing or activating until release', (
    tester,
  ) async {
    var activations = 0;
    await showButton(tester, onPressed: () => activations++);
    final label = find.text('Continue');
    final top = tester.getTopLeft(label);
    final size = tester.getSize(find.byType(ActionButton));
    final gesture = await tester.startGesture(tester.getCenter(label));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(label).dy, top.dy + 6);
    final face = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where(
          (widget) =>
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  companionTheme().colorScheme.secondary,
        )
        .single;
    expect((face.decoration as BoxDecoration).boxShadow, isEmpty);
    expect(tester.getSize(find.byType(ActionButton)), size);
    expect(activations, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(activations, 1);
    expect(tester.getTopLeft(label), top);
  });

  testWidgets('dragging off cancels activation and restores the face', (
    tester,
  ) async {
    var activations = 0;
    await showButton(tester, onPressed: () => activations++);
    final label = find.text('Continue');
    final top = tester.getTopLeft(label);
    final gesture = await tester.startGesture(tester.getCenter(label));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 180));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(activations, 0);
    expect(tester.getTopLeft(label), top);
  });

  testWidgets('pointer cancellation restores the face without an action', (
    tester,
  ) async {
    var activations = 0;
    await showButton(tester, onPressed: () => activations++);
    final label = find.text('Continue');
    final resting = tester.getTopLeft(label);
    final gesture = await tester.startGesture(tester.getCenter(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(activations, 0);
    expect(tester.getTopLeft(label), resting);
  });

  testWidgets('disabled and busy buttons block actions and expose progress', (
    tester,
  ) async {
    var activations = 0;
    await showButton(tester, onPressed: null);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await showButton(tester, onPressed: () => activations++, busy: true);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(activations, 0);
    expect(find.bySemanticsLabel(RegExp('In progress')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard focus and activation retain native button semantics', (
    tester,
  ) async {
    var activations = 0;
    await showButton(tester, onPressed: () => activations++);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(ink.statesController!.value, contains(WidgetState.focused));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(activations, 2);
    expect(
      tester.getSemantics(find.byType(FilledButton)),
      matchesSemantics(
        label: 'Continue',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        isFocused: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets(
    'reduced motion keeps the face stationary while still actionable',
    (tester) async {
      var activations = 0;
      await showButton(
        tester,
        onPressed: () => activations++,
        reduceMotion: true,
      );
      final label = find.text('Continue');
      final top = tester.getTopLeft(label);
      final gesture = await tester.startGesture(tester.getCenter(label));
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(label), top);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(activations, 1);
    },
  );
}
