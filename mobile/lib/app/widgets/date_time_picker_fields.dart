import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatPickedDate(DateTime date) => '${_monthAbbreviations[date.month - 1]} ${date.day}, ${date.year}';

String formatPickedTime(TimeOfDay time) {
  final period = time.period == DayPeriod.pm ? 'PM' : 'AM';
  final hour12Raw = time.hourOfPeriod;
  final hour12 = hour12Raw == 0 ? 12 : hour12Raw;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

/// A standalone calendar-date-only picker field (no time component). Used
/// where Date and Time are two visually and semantically separate frozen
/// controls (Create/Edit Event's Schedule section) rather than
/// CreateFollowUpScreen's combined due-instant field.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select date',
    this.fieldKey,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String hintText;
  final Key? fieldKey;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        InkWell(
          key: fieldKey,
          borderRadius: borderRadius,
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
              border: OutlineInputBorder(borderRadius: borderRadius, borderSide: const BorderSide(color: AppColors.borderSubtle)),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Text(
              value != null ? formatPickedDate(value!) : hintText,
              style: TextStyle(fontSize: 14, color: value != null ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

/// A standalone wall-clock-time-only picker field (no date component).
/// [optional] controls whether a clear (x) affordance is shown once a value
/// is picked — Start Time is required (no clear), End Time is optional
/// (clearable back to null, never defaulted).
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select time',
    this.optional = false,
    this.fieldKey,
    this.clearKey,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String hintText;
  final bool optional;
  final Key? fieldKey;
  final Key? clearKey;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: value ?? TimeOfDay.now());
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        InkWell(
          key: fieldKey,
          borderRadius: borderRadius,
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              suffixIcon: optional && value != null
                  ? IconButton(
                      key: clearKey,
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                      onPressed: () => onChanged(null),
                    )
                  : const Icon(Icons.schedule_outlined, size: 18, color: AppColors.textSecondary),
              border: OutlineInputBorder(borderRadius: borderRadius, borderSide: const BorderSide(color: AppColors.borderSubtle)),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Text(
              value != null ? formatPickedTime(value!) : hintText,
              style: TextStyle(fontSize: 14, color: value != null ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
