import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/department_model.dart';
import '../../../providers/department_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({super.key});

  @override
  State<ManageDepartmentsScreen> createState() =>
      _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Departments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(BootstrapIcons.plus_lg),
        label: const Text('Add Department'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search departments',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DepartmentModel>>(
        stream: context.read<DepartmentProvider>().departmentsStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final departments = (snap.data ?? [])
              .where((department) =>
                  _search.isEmpty ||
                  department.name.toLowerCase().contains(_search) ||
                  (department.description ?? '')
                      .toLowerCase()
                      .contains(_search))
              .toList();
          if (departments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(BootstrapIcons.hospital,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('No departments yet',
                      style:
                          TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(BootstrapIcons.plus_lg),
                    label: const Text('Add First Department'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: departments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _DeptTile(department: departments[i]),
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    context.read<DepartmentProvider>().clearError();
    await showDialog(
      context: context,
      builder: (_) => const _AddDepartmentDialog(),
    );
  }

  static Future<void> _showEditDialog(
    BuildContext context,
    DepartmentModel department,
  ) async {
    final nameCtrl = TextEditingController(text: department.name);
    final descCtrl =
        TextEditingController(text: department.description ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Department'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameCtrl,
                label: 'Department Name',
                prefixIcon: BootstrapIcons.hospital,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Name is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: descCtrl,
                label: 'Description (optional)',
                prefixIcon: BootstrapIcons.info_circle,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final updated = department.copyWith(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
              );
              final ok = await context
                  .read<DepartmentProvider>()
                  .saveDepartment(updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Department updated successfully.'
                        : 'Failed to update department.'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AddDepartmentDialog extends StatefulWidget {
  const _AddDepartmentDialog();

  @override
  State<_AddDepartmentDialog> createState() => _AddDepartmentDialogState();
}

class _AddDepartmentDialogState extends State<_AddDepartmentDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addDepartment() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);
    final department = DepartmentModel(
      id: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdAt: DateTime.now(),
    );
    final provider = context.read<DepartmentProvider>();
    final added = await provider.saveDepartment(department);
    if (!mounted) return;

    if (!added) {
      setState(() => _saving = false);
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Department added successfully.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Department'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Department Name',
              hintText: 'e.g. Cardiology',
              prefixIcon: BootstrapIcons.hospital,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Name is required.'
                  : null,
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              hintText: 'Brief description',
              prefixIcon: BootstrapIcons.info_circle,
              maxLines: 2,
              enabled: !_saving,
            ),
            if (context.watch<DepartmentProvider>().error != null) ...[
              const SizedBox(height: 12),
              Text(
                context.watch<DepartmentProvider>().error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _addDepartment,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _DeptTile extends StatelessWidget {
  final DepartmentModel department;
  const _DeptTile({required this.department});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(BootstrapIcons.bag_plus,
              color: AppColors.primary, size: 20),
        ),
        title: Text(department.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: department.description != null
            ? Text(department.description!,
                style: const TextStyle(fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit department',
              icon: const Icon(BootstrapIcons.pencil),
              onPressed: () =>
                  _ManageDepartmentsScreenState._showEditDialog(
                    context,
                    department,
                  ),
            ),
            Switch(
              value: department.isActive,
              onChanged: (_) => context
                  .read<DepartmentProvider>()
                  .toggleDepartmentActive(department),
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
