import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered icon-circle (or supplied illustration) + headline + subtitle
/// composition, matching design/ui-reference's empty-state screens (e.g.
/// People's "No people yet."). Used here for scope stubs too, so the copy
/// states unavailability honestly rather than implying a populated-but-empty
/// data set.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.icon, this.imageAsset, required this.title, required this.message, this.action})
    : assert(icon != null || imageAsset != null, 'EmptyState requires either an icon or an imageAsset');

  /// Rendered inside a brand-tinted circle. Ignored when [imageAsset] is set.
  final IconData? icon;

  /// A real, approved illustration asset (Product Task 076/077) shown in
  /// place of the icon-circle when supplied — e.g. People's "No people yet."
  /// uses assets/brand/No people.png rather than a generic Material icon.
  final String? imageAsset;

  final String title;
  final String message;

  /// Optional full-width action (e.g. a [PrimaryButton]) rendered below the
  /// message. Omitted by existing callers, so their layout is unchanged.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: imageAsset != null
                    ? Image.asset(imageAsset!, width: 160, height: 160)
                    : Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(color: Color(0xFFEFF3FF), shape: BoxShape.circle),
                        child: Icon(icon, size: 40, color: AppColors.brandPrimary),
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}
