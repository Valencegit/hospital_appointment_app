import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/patient_model.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class StaffPatientsScreen extends StatefulWidget {
  const StaffPatientsScreen({super.key});

  @override
  State<StaffPatientsScreen> createState() => _StaffPatientsScreenState();
}

class _StaffPatientsScreenState extends State<StaffPatientsScreen> {
  final _searchCtrl = TextEditingController();
  List<PatientModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final results =
          await context.read<FirestoreService>().searchPatients(query);
      setState(() => _results = results);
    } catch (_) {
      setState(() => _results = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Records')),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _searchCtrl,
                    hintText: 'Search by first name...',
                    prefixIcon: BootstrapIcons.search,
                    onFieldSubmitted: (_) => _search(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(70, 52)),
                  onPressed: _search,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(BootstrapIcons.person_lines_fill,
                                size: 56, color: AppColors.textMuted),
                            SizedBox(height: 16),
                            Text('Search for a patient',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                            SizedBox(height: 4),
                            Text('Enter a first name to search records',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(BootstrapIcons.person_dash,
                                    size: 56,
                                    color: AppColors.textMuted),
                                SizedBox(height: 16),
                                Text('No patients found',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (_, i) =>
                                _PatientTile(patient: _results[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final PatientModel patient;
  const _PatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding, vertical: 8),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          patient.firstName.isNotEmpty
              ? patient.firstName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(patient.phoneNumber,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          if (patient.dateOfBirth != null)
            Text(
              'DOB: ${DateFormat('MMM d, yyyy').format(patient.dateOfBirth!)}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11),
            ),
        ],
      ),
      trailing: patient.bloodGroup != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                patient.bloodGroup!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )
          : null,
    );
  }
}
