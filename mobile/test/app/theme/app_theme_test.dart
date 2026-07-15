import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/app/theme/app_colors.dart';
import 'package:relvio/app/theme/app_theme.dart';

ShapeBorder _renderedShape(WidgetTester tester) {
  final material = tester.widget<Material>(
    find.descendant(of: find.byType(OutlinedButton), matching: find.byType(Material)).first,
  );
  return material.shape!;
}

void main() {
  testWidgets('a plain OutlinedButton renders the brand-blue border, not the Material default gray outline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: OutlinedButton(onPressed: () {}, child: const Text('Retry'))),
      ),
    );

    final shape = _renderedShape(tester) as OutlinedBorder;
    expect(shape.side.color, AppColors.brandPrimary);
  });

  testWidgets('a per-instance style override (e.g. custom shape) still keeps the themed blue border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Cancel'),
          ),
        ),
      ),
    );

    final shape = _renderedShape(tester) as OutlinedBorder;
    expect(shape.side.color, AppColors.brandPrimary);
  });
}
