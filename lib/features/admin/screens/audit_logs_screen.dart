import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/firestore_service.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 22: Audit Logs — searchable admin action history with filter.
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all'; // all | destructive | role | status

  static const _filterOptions = [
    ('all', 'All'),
    ('destructive', 'Destructive'),
    ('role', 'Role Changes'),
    ('status', 'Status Changes'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Audit Logs')),
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by action or actor...',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                itemCount: _filterOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (value, label) = _filterOptions[i];
                  final selected = _filter == value;
                  return FilterChip(
                    label: Text(label,
                        style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _filter = value),
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            ),
          ),

          // ── Logs List ──────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context
                  .read<FirestoreService>()
                  .auditLogsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                var logs = snap.data ?? [];

                // Apply action type filter
                if (_filter == 'destructive') {
                  logs = logs
                      .where((l) =>
                          (l['action'] as String? ?? '')
                              .contains('cancel') ||
                          (l['action'] as String? ?? '')
                              .contains('deactivat') ||
                          (l['action'] as String? ?? '')
                              .contains('delet'))
                      .toList();
                } else if (_filter == 'role') {
                  logs = logs
                      .where((l) => (l['action'] as String? ?? '')
                          .contains('role'))
                      .toList();
                } else if (_filter == 'status') {
                  logs = logs
                      .where((l) => (l['action'] as String? ?? '')
                          .contains('status'))
                      .toList();
                }

                // Apply search query
                if (_searchQuery.isNotEmpty) {
                  logs = logs
                      .where((l) =>
                          (l['action'] as String? ?? '')
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          (l['actorUid'] as String? ?? '')
                              .toLowerCase()
                              .contains(_searchQuery))
                      .toList();
                }

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(BootstrapIcons.clock_history,
                            size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No audit logs found',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 6),
                  itemBuilder: (_, i) => _LogTile(log: logs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String? ?? 'unknown_action';
    final actorUid = log['actorUid'] as String? ?? '';
    final recordRef = log['recordRef'] as String?;
    final ts = log['timestamp'];
    DateTime? date;
    if (ts is Timestamp) date = ts.toDate();

    final isDestructive = action.contains('cancel') ||
        action.contains('deactivat') ||
        action.contains('delet');
    final isRoleChange = action.contains('role');

    Color dotColor;
    if (isDestructive) {
      dotColor = AppColors.error;
    } else if (isRoleChange) {
      dotColor = const Color(0xFF7C3AED);
    } else {
      dotColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDestructive
                  ? Icons.warning_amber_rounded
                  : isRoleChange
                      ? Icons.manage_accounts_outlined
                      : Icons.task_alt_outlined,
              size: 18,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Actor: ${actorUid.length > 12 ? '${actorUid.substring(0, 12)}...' : actorUid}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
                if (recordRef != null && recordRef.isNotEmpty)
                  Text(
                    'Record: ${recordRef.length > 14 ? '${recordRef.substring(0, 14)}...' : recordRef}',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (date != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('d MMM').format(date),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(date),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
