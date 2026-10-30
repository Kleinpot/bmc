import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('shows the six requested items as free', (tester) async {
    await tester.pumpWidget(const CampusGearApp());
    await tester.pump();

    for (final title in [
      'Basketball',
      'Camera',
      'Projector',
      'Walis / Broom',
      'Arnis Sticks',
      'Master Key',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('FREE'), findsNWidgets(12));
    expect(find.text('\$0.00'), findsNWidgets(6));
  });

  testWidgets('borrow customizer and return action work', (tester) async {
    await tester.pumpWidget(const CampusGearApp());
    await tester.pump();

    await tester.tap(find.text('Basketball'));
    await tester.pumpAndSettle();
    expect(find.text('100% free to borrow'), findsOneWidget);
    expect(find.text('Add to borrowed items'), findsOneWidget);

    await tester.tap(find.text('Add to borrowed items'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Borrowed items'));
    await tester.pumpAndSettle();
    expect(find.text('Borrowing for 3 days'), findsOneWidget);
    expect(find.text('FREE · \$0.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Return item'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nothing borrowed yet. Find something useful to borrow.'),
      findsOneWidget,
    );
  });

  testWidgets('share dialog adds a free item to the catalog', (tester) async {
    await tester.pumpWidget(const CampusGearApp());
    await tester.pump();

    await tester.tap(find.text('Share an item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Soccer ball');
    await tester.tap(find.text('Share item').last);
    await tester.pumpAndSettle();

    expect(find.text('Soccer ball'), findsOneWidget);
    expect(find.text('\$0.00'), findsNWidgets(7));
  });
}
