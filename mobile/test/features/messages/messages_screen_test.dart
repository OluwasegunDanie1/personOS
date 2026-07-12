import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/features/messages/messages_screen.dart';

void main() {
  testWidgets('renders a neutral unavailable state with compose disabled and no invented content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MessagesScreen()));

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Stay connected with your people.'), findsOneWidget);
    expect(find.text('Messages is not yet available'), findsOneWidget);
    expect(find.text('This section is coming in a future build.'), findsOneWidget);

    final composeButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.edit_outlined));
    expect(composeButton.onPressed, isNull, reason: 'compose must be disabled while the backend is deferred');

    expect(find.byType(ListView), findsNothing);
    expect(find.byType(ListTile), findsNothing);
  });
}
