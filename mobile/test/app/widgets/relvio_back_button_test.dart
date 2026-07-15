import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/app/widgets/relvio_back_button.dart';

void main() {
  testWidgets('renders a bordered container (not a bare IconButton) around the arrow icon', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RelvioBackButton())));

    expect(find.byType(IconButton), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('tapping with a custom onPressed calls it instead of popping', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RelvioBackButton(onPressed: () => tapped = true))),
    );

    await tester.tap(find.byType(RelvioBackButton));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('with no onPressed, tapping pops the current route', (tester) async {
    final router = Navigator(
      pages: const [
        MaterialPage(child: Scaffold(body: Text('Root'))),
        MaterialPage(child: Scaffold(body: RelvioBackButton())),
      ],
      onDidRemovePage: (page) {},
    );
    await tester.pumpWidget(MaterialApp(home: router));

    expect(find.text('Root'), findsNothing);
    await tester.tap(find.byType(RelvioBackButton));
    await tester.pumpAndSettle();

    expect(find.text('Root'), findsOneWidget);
  });
}
