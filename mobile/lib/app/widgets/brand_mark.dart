import 'package:flutter/material.dart';

/// The approved Relvio icon mark (design/ui-reference/Relvo Logo.png),
/// copied to assets/brand/relvio_mark.png for runtime use.
///
/// The source PNG carries substantial baked-in padding around the visible
/// ring: measured, the actual ink only occupies ~63% of the 1254x1254
/// canvas (Product Task 090A). Rendered at face value, the mark always
/// looks smaller/weaker than its bounding box suggests, at any size —
/// which is why simply increasing [size] (Task 088/090) never fixed the
/// "weak logo" report. [_contentZoom] scales the asset up and clips it to
/// the requested box, cropping away that dead margin so the real mark
/// fills its box the way the frozen UI shows it — the same real, approved
/// asset, never a replacement.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96});

  final double size;

  static const double _contentZoom = 1.5;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: size,
        height: size,
        child: Transform.scale(
          scale: _contentZoom,
          child: Image.asset('assets/brand/relvio_mark.png', width: size, height: size, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
