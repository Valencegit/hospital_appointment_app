import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/department_model.dart';
import '../../../providers/department_provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 6: Departments — searchable grid of active hospital departments.
class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _deptIcons = <String, IconData>{
    'cardio': BootstrapIcons.heart,
    'ortho': BootstrapIcons.universal_access,
    'paedia': BootstrapIcons.emoji_smile,
    'pedi': BootstrapIcons.emoji_smile,
    'neuro': Icons.psychology_outlined,
    'gynae': BootstrapIcons.person_heart,
    'gyne': BootstrapIcons.person_heart,
    'obs': BootstrapIcons.person_heart,
    'radio': BootstrapIcons.eyedropper,
    'derma': BootstrapIcons.person_bounding_box,
    'ophthal': BootstrapIcons.eye,
    'ent': BootstrapIcons.ear,
    'dent': BootstrapIcons.bag_plus,
    'dental': BootstrapIcons.bag_plus,
  };

  IconData _getIcon(String name) {
    final lower = name.toLowerCase();
    for (final e in _deptIcons.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return BootstrapIcons.hospital;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Departments')),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search department by name...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 22),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                ),
              ),
            ),
          ),

          // ── Department Grid ───────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<DepartmentModel>>(
              stream: context
                  .read<DepartmentProvider>()
                  .activeDepartmentsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                final departments = _query.isEmpty
                    ? all
                    : all
                        .where((d) =>
                            d.name.toLowerCase().contains(_query))
                        .toList();

                if (departments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          _query.isEmpty
                              ? 'No departments available'
                              : 'No results for "$_query"',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: departments.length,
                  itemBuilder: (_, i) => _DepartmentCard(
                    department: departments[i],
                    icon: _getIcon(departments[i].name),
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

class _DepartmentCard extends StatelessWidget {
  final DepartmentModel department;
  final IconData icon;

  const _DepartmentCard({required this.department, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: InkWell(
        onTap: () => context.push(
          '/patient/departments/slots',
          extra: {
            'departmentId': department.id,
            'departmentName': department.name,
          },
        ),
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                department.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              if (department.description != null &&
                  department.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  department.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const Spacer(),
              // View Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
