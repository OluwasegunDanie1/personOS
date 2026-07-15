import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/app/splash_screen.dart';
import 'package:relvio/app/widgets/brand_mark.dart';

void main() {
  testWidgets('the mark and "Relvio" wordmark sit close together as one lockup (Product Task 090A)', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text('Relvio'), findsOneWidget);

    final column = tester.widget<Column>(find.byType(Column));
    final gapIndex = column.children.indexWhere((child) => child is SizedBox && child.height != null);
    final gap = (column.children[gapIndex] as SizedBox).height!;

    // Previously 20 — tight enough now to read as one connected lockup,
    // not two separately-floating elements.
    expect(gap, lessThanOrEqualTo(8));
  });
}
