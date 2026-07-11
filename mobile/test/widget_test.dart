import 'package:flutter_test/flutter_test.dart';

import 'package:relvio/main.dart';

void main() {
  testWidgets('Relvio bootstrap screen displays the Relvio identifier', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RelvioApp());

    expect(find.text('Relvio'), findsOneWidget);
  });
}
