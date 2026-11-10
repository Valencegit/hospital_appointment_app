import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/department_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Metro Health Hospital Appointment Booking Screen matching Mockup Screen 5.
class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? slotData;

  const BookAppointmentScreen({super.key, this.slotData});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String _selectedDepartmentId = 'dept_cardiology';
  String _selectedDepartmentName = 'Cardiology';
  DateTime _selectedDate = DateTime(2025, 12, 2);
  String _selectedTimeSlot = '10:00 AM';
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _timeSlots = const [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    // Default or passed slotData
    if (widget.slotData != null && widget.slotData!.isNotEmpty) {
      if (widget.slotData!['departmentId'] != null) {
        _selectedDepartmentId = widget.slotData!['departmentId'] as String;
      }
      if (widget.slotData!['departmentName'] != null) {
        _selectedDepartmentName = widget.slotData!['departmentName'] as String;
      }
      if (widget.slotData!['date'] != null) {
        _selectedDate = widget.slotData!['date'] as DateTime;
      }
      if (widget.slotData!['startTime'] != null) {
        _selectedTimeSlot = widget.slotData!['startTime'] as String;
      }
    } else {
      // Default to next day if past 2025
      final now = DateTime.now();
      if (now.isAfter(DateTime(2025, 12, 3))) {
        _selectedDate = now.add(const Duration(days: 1));
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleBookAppointment() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final patient = auth.patientProfile;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book an appointment.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final name = patient?.fullName ?? user.fullName;
    final apptProvider = context.read<AppointmentProvider>();

    final slotId = widget.slotData?['slotId'] as String? ??
        'slot_${_selectedDepartmentId}_${DateFormat('yyyyMMdd').format(_selectedDate)}_${_selectedTimeSlot.replaceAll(' ', '')}';

    final id = await apptProvider.book(
      patientId: user.uid,
      patientName: name,
      slotId: slotId,
      departmentId: _selectedDepartmentId,
      departmentName: _selectedDepartmentName,
      appointmentDate: _selectedDate,
      appointmentTime: _selectedTimeSlot,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (id != null) {
      // Navigate to the dedicated confirmation screen only after Firebase confirms
      context.pushReplacement(
        '/patient/booking-confirmation',
        extra: {
          'appointmentId': id,
          'departmentName': _selectedDepartmentName,
          'appointmentDate':
              DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
          'appointmentTime': _selectedTimeSlot,
          'status': 'Confirmed',
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apptProvider.error ?? 'Booking failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptProvider = context.watch<DepartmentProvider>();
    final departments = deptProvider.departments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        leading: IconButton(
          icon: const Icon(BootstrapIcons.arrow_left, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Select Department ──────────────────────────────────
                    const Text(
                      'Select Department',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDCE6F2), width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDepartmentName,
                          isExpanded: true,
                          icon: const Icon(
                            BootstrapIcons.chevron_down,
                            color: AppColors.textSecondary,
                          ),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setState(() {
                                _selectedDepartmentName = newVal;
                                final match = departments.firstWhere(
                                  (d) => d.name == newVal,
                                  orElse: () => DepartmentModel(
                                    id: 'dept_cardiology',
                                    name: 'Cardiology',
                                    description: '',
                                    createdAt: DateTime.now(),
                                  ),
                                );
                                _selectedDepartmentId = match.id;
                              });
                            }
                          },
                          items: [
                            'Cardiology',
                            'Neurology',
                            'Pediatrics',
                            'Orthopedics',
                            'General Medicine',
                            'Dermatology',
                          ].map((name) {
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF3FE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      name == 'Cardiology'
                                          ? BootstrapIcons.heart_fill
                                          : BootstrapIcons.hospital_fill,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 2. Choose Date ────────────────────────────────────────
                    const Text(
                      'Choose Date',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDCE6F2), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              BootstrapIcons.calendar_date,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              BootstrapIcons.calendar_fill,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 3. Available Time Slots ───────────────────────────────
                    const Text(
                      'Available Time Slots',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (ctx, i) {
                        final slot = _timeSlots[i];
                        final isSelected = slot == _selectedTimeSlot;

                        return InkWell(
                          onTap: () => setState(() => _selectedTimeSlot = slot),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFDCE6F2),
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Optional Notes
                    const Text(
                      'Additional Notes (Optional)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Describe any symptoms or specific requests...',
                        filled: true,
                        fillColor: const Color(0xFFF9FBFE),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Book Appointment Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEAF0F8), width: 1),
                ),
              ),
              child: CustomButton(
                text: 'Book Appointment',
                isLoading: _isSubmitting,
                onPressed: _handleBookAppointment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
