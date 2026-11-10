import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/slot_model.dart';
import '../../../providers/department_provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class SlotsScreen extends StatefulWidget {
  final String departmentId;
  final String departmentName;

  const SlotsScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.departmentName)),
      body: Column(
        children: [
          _DatePickerStrip(
            selectedDate: _selectedDate,
            onDateChanged: (d) => setState(() => _selectedDate = d),
          ),
          Expanded(
            child: StreamBuilder<List<SlotModel>>(
              stream: context
                  .read<DepartmentProvider>()
                  .slotsStream(widget.departmentId, _selectedDate),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final slots = snap.data ?? [];
                if (slots.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(BootstrapIcons.calendar_date,
                            size: 56, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text('No slots available for this date',
                            style: TextStyle(color: AppColors.textSecondary)),
                        SizedBox(height: 8),
                        Text('Try selecting another date',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: slots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SlotCard(slot: slots[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DatePickerStrip({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(BootstrapIcons.chevron_left),
                onPressed: () => onDateChanged(
                    selectedDate.subtract(const Duration(days: 1))),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) onDateChanged(picked);
                },
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE').format(selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM d, yyyy').format(selectedDate),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(BootstrapIcons.chevron_right),
                onPressed: () =>
                    onDateChanged(selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
          // 7-day week strip
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (_, i) {
                final day =
                    DateTime.now().add(Duration(days: i));
                final isSelected = day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;
                return GestureDetector(
                  onTap: () => onDateChanged(day),
                  child: Container(
                    width: 44,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(day).substring(0, 2),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d').format(day),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final SlotModel slot;

  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final available = slot.isAvailable;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: available ? AppColors.surface : AppColors.surfaceVariant,
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: available
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (available ? AppColors.primary : AppColors.textMuted)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              BootstrapIcons.clock_fill,
              color:
                  available ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.startTime}  –  ${slot.endTime}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      available
                          ? BootstrapIcons.check_circle
                          : BootstrapIcons.x_circle,
                      size: 13,
                      color: available
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      available
                          ? '${slot.remainingSlots} slot${slot.remainingSlots != 1 ? 's' : ''} available'
                          : 'Fully booked',
                      style: TextStyle(
                        fontSize: 12,
                        color: available
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (available)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(72, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => context.push(
                '/patient/book',
                extra: {
                  'slotId': slot.id,
                  'departmentId': slot.departmentId,
                  'departmentName': slot.departmentName,
                  'date': slot.date,
                  'startTime': slot.startTime,
                  'endTime': slot.endTime,
                },
              ),
              child: const Text('Book'),
            ),
        ],
      ),
    );
  }
}
