import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/department_model.dart';
import '../../../models/slot_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/department_provider.dart';
import '../../../services/user_service.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class ManageSlotsScreen extends StatefulWidget {
  const ManageSlotsScreen({super.key});

  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> {
  DepartmentModel? _selectedDept;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Slots')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSlotDialog,
        icon: const Icon(BootstrapIcons.plus_lg),
        label: const Text('Add Slot'),
      ),
      body: Column(
        children: [
          // Department selector
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: StreamBuilder<List<DepartmentModel>>(
              stream:
                  context.read<DepartmentProvider>().activeDepartmentsStream(),
              builder: (ctx, snap) {
                final depts = snap.data ?? [];
                return DropdownButtonFormField<DepartmentModel>(
                  initialValue: _selectedDept,
                  hint: const Text('Select Department'),
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(BootstrapIcons.hospital),
                  ),
                  items: depts
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.name),
                          ))
                      .toList(),
                  onChanged: (d) => setState(() => _selectedDept = d),
                );
              },
            ),
          ),

          // Date navigation
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(BootstrapIcons.chevron_left),
                  onPressed: () => setState(() => _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1))),
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
                IconButton(
                  icon: const Icon(BootstrapIcons.chevron_right),
                  onPressed: () => setState(() => _selectedDate =
                      _selectedDate.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _selectedDept == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(BootstrapIcons.hospital,
                            size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('Select a department to view slots',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : StreamBuilder<List<SlotModel>>(
                    stream: context
                        .read<DepartmentProvider>()
                        .slotsStream(_selectedDept!.id, _selectedDate),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final slots = snap.data ?? [];
                      if (slots.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(BootstrapIcons.clock,
                                  size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text('No slots for this date',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _showAddSlotDialog,
                                icon: const Icon(BootstrapIcons.plus_lg),
                                label: const Text('Add Slot'),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: slots.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _SlotTile(slot: slots[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _showAddSlotDialog() async {
    if (_selectedDept == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '10');
    String? selectedDoctorId;
    String? selectedDoctorName;

    // Capture before async gap so we can use after dialog closes
    final deptProvider = context.read<DepartmentProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Appointment Slot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedDept!.name}  ·  ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<UserModel>>(
                  stream: UserService().doctorsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Unable to load doctors.');
                    }
                    final doctors = snapshot.data ?? const <UserModel>[];
                    return DropdownButtonFormField<String>(
                      initialValue: selectedDoctorId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned doctor',
                        prefixIcon: Icon(BootstrapIcons.person_badge),
                      ),
                      items: doctors
                          .map(
                            (doctor) => DropdownMenuItem(
                              value: doctor.uid,
                              child: Text(
                                doctor.fullName.isEmpty
                                    ? doctor.email
                                    : doctor.fullName,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        UserModel? doctor;
                        for (final item in doctors) {
                          if (item.uid == id) {
                            doctor = item;
                            break;
                          }
                        }
                        setDialogState(() {
                          selectedDoctorId = id;
                          selectedDoctorName = doctor?.fullName;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    hintText: '09:00 AM',
                    prefixIcon: Icon(BootstrapIcons.clock),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    hintText: '09:30 AM',
                    prefixIcon: Icon(BootstrapIcons.clock),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    prefixIcon: Icon(BootstrapIcons.people),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDoctorId == null
                  ? null
                  : () async {
                      final department = _selectedDept!;
                      final date = _selectedDate;
                      Navigator.pop(dialogContext);
                      final slot = SlotModel(
                        id: '',
                        departmentId: department.id,
                        departmentName: department.name,
                        doctorId: selectedDoctorId,
                        doctorName: selectedDoctorName,
                        date: date,
                        startTime: startCtrl.text.trim(),
                        endTime: endCtrl.text.trim(),
                        capacity: int.tryParse(capacityCtrl.text.trim()) ?? 10,
                        createdAt: DateTime.now(),
                      );
                      final ok = await deptProvider.saveSlot(slot);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Slot added successfully.'
                              : 'Failed to add slot.'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                        ),
                      );
                    },
              child: const Text('Add Slot'),
            ),
          ],
        ),
      ),
    );
    startCtrl.dispose();
    endCtrl.dispose();
    capacityCtrl.dispose();
  }
}

class _SlotTile extends StatelessWidget {
  final SlotModel slot;
  const _SlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (slot.isActive ? AppColors.primary : AppColors.textMuted)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(BootstrapIcons.clock_fill,
              color: slot.isActive ? AppColors.primary : AppColors.textMuted,
              size: 20),
        ),
        title: Text(
          '${slot.startTime}  –  ${slot.endTime}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(
              'Cap: ${slot.capacity}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 8),
            const Text('·', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(width: 8),
            Text(
              'Booked: ${slot.bookedCount}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 8),
            const Text('·', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(width: 8),
            Text(
              'Free: ${slot.remainingSlots}',
              style: TextStyle(
                fontSize: 12,
                color: slot.remainingSlots > 0
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ],
        ),
        trailing: Switch(
          value: slot.isActive,
          onChanged: (_) =>
              context.read<DepartmentProvider>().toggleSlotActive(slot),
          activeThumbColor: AppColors.primary,
        ),
      ),
    );
  }
}
