import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Clean, modern custom date range selector matching the design:
/// [ FROM  13/10/2026  📅 ]  →  [ TO  dd/mm/yyyy  📅 ]  [ ✕ Reset ]
class CustomDateRangePicker extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTime?> onFromDateSelected;
  final ValueChanged<DateTime?> onToDateSelected;
  final VoidCallback onReset;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDateRangePicker({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateSelected,
    required this.onToDateSelected,
    required this.onReset,
    this.firstDate,
    this.lastDate,
  });

  Future<void> _pickDate(
    BuildContext context, {
    required bool isFrom,
  }) async {
    final now = DateTime.now();
    final defaultFirstDate = firstDate ?? DateTime(2023, 1, 1);
    final defaultLastDate = lastDate ?? DateTime(now.year + 5, 12, 31);

    final initialDate = isFrom
        ? (fromDate ?? now)
        : (toDate ?? fromDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(defaultLastDate)
          ? defaultLastDate
          : (initialDate.isBefore(defaultFirstDate) ? defaultFirstDate : initialDate),
      firstDate: defaultFirstDate,
      lastDate: defaultLastDate,
      helpText: isFrom ? 'Select Start Date (FROM)' : 'Select End Date (TO)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF1C7BFF),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: const Color(0xFF0F172A),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isFrom) {
        onFromDateSelected(picked);
      } else {
        onToDateSelected(picked);
      }
    }
  }

  Widget _buildDateBox(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required bool isFrom,
  }) {
    final hasValue = date != null;
    final dateText = hasValue ? DateFormat('dd/MM/yyyy').format(date) : 'dd/mm/yyyy';

    return InkWell(
      onTap: () => _pickDate(context, isFrom: isFrom),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasValue ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              dateText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                color: hasValue ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: Color(0xFF0F172A),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = fromDate != null || toDate != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // FROM box
        _buildDateBox(
          context,
          label: 'FROM',
          date: fromDate,
          isFrom: true,
        ),

        const SizedBox(width: 8),

        // Arrow
        const Text(
          '→',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(width: 8),

        // TO box
        _buildDateBox(
          context,
          label: 'TO',
          date: toDate,
          isFrom: false,
        ),

        const SizedBox(width: 10),

        // Reset button
        InkWell(
          onTap: onReset,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: isActive ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                ),
                const SizedBox(width: 4),
                Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
