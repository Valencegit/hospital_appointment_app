import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 11: Notifications — appointment updates with read/unread indicator.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(BootstrapIcons.arrow_left, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await NotificationService.instance.markAllRead(uid);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not mark notifications as read.'),
                  ),
                );
              }
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: context.read<FirestoreService>().notificationsStream(uid),
        builder: (ctx, snap) {
          final liveList = snap.data ?? [];

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(
              child: Text('Unable to load notifications. Please try again.'),
            );
          }
          if (liveList.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('You have no notifications yet.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: liveList.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) {
              final n = liveList[i];
              final (icon, iconColor, iconBg) =
                  _styleForNotification(n.type ?? '');
              final timeAgo = _formatTimeAgo(n.createdAt);

              return _NotificationItemRow(
                icon: icon,
                iconColor: iconColor,
                iconBgColor: iconBg,
                title: n.title,
                message: n.body,
                timeAgo: timeAgo,
                isRead: n.isRead,
                onTap: () async {
                  if (!n.isRead) {
                    try {
                      await context
                          .read<FirestoreService>()
                          .markNotificationRead(n.id);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not update this notification.'),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  static (IconData, Color, Color) _styleForNotification(String type) {
    switch (type.toLowerCase()) {
      case 'confirmed':
      case 'appointment_confirmed':
        return (BootstrapIcons.check_lg, Colors.white, const Color(0xFF0EA568));
      case 'reminder':
      case 'appointment_reminder':
        return (
          BootstrapIcons.bell_fill,
          Colors.white,
          const Color(0xFF008F87)
        );
      case 'updated':
      case 'appointment_updated':
      case 'rescheduled':
        return (
          BootstrapIcons.info_circle_fill,
          Colors.white,
          const Color(0xFFF59E0B)
        );
      case 'cancelled':
      case 'appointment_cancelled':
        return (BootstrapIcons.x_lg, Colors.white, const Color(0xFFEF4444));
      case 'appointment_completed':
        return (
          BootstrapIcons.check_circle_fill,
          Colors.white,
          const Color(0xFF00897B)
        );
      default:
        return (BootstrapIcons.bell, Colors.white, const Color(0xFF008F87));
    }
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 59)}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _NotificationItemRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;
  final String timeAgo;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationItemRow({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? Colors.transparent : const Color(0xFFF5F9FF),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular status icon with unread dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (!isRead)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Title & message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeAgo,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
