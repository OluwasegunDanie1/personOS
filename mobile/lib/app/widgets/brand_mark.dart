import 'package:flutter/material.dart';

/// The approved Relvio icon mark (design/ui-reference/Relvo Logo.png),
/// copied to assets/brand/relvio_mark.png for runtime use.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/brand/relvio_mark.png', width: size, height: size);
  }
}
