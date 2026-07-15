import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/app/widgets/brand_mark.dart';

void main() {
  testWidgets('renders the real relvio_mark.png asset, scaled up and clipped to compensate for its baked-in padding', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BrandMark(size: 96))));

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/brand/relvio_mark.png');

    // The mark must be genuinely magnified (not merely rendered at face
    // value) to correct for the ~37% dead margin baked into the source PNG
    // (Product Task 090A) — a real crop/zoom, not just a bigger box.
    final transform = tester.widget<Transform>(
      find.descendant(of: find.byType(BrandMark), matching: find.byType(Transform)),
    );
    expect(transform.transform.getMaxScaleOnAxis(), greaterThan(1.0));

    // Clipped to exactly the requested box — the widget's public contract
    // (its rendered footprint) is unchanged even though the image itself is
    // rendered larger internally.
    expect(
      find.descendant(of: find.byType(BrandMark), matching: find.byType(ClipRect)),
      findsOneWidget,
    );
    final box = tester.getSize(find.byType(BrandMark));
    expect(box, const Size(96, 96));
  });

  testWidgets('respects a custom size', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BrandMark(size: 48))));

    final box = tester.getSize(find.byType(BrandMark));
    expect(box, const Size(48, 48));
  });
}
