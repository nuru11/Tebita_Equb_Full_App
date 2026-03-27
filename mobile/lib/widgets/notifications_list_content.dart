import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/notification_model.dart';
import '../modules/profile/notification_controller.dart';
import '../theme/app_colors.dart';

/// Shared notifications list for profile card and full-screen notifications page.
class NotificationsListContent extends StatelessWidget {
  const NotificationsListContent({
    super.key,
    required this.controller,
    this.scrollPhysics,
    this.shrinkWrap = false,
  });

  final NotificationController controller;
  final ScrollPhysics? scrollPhysics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value && controller.notifications.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.errorMessage.value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      final list = controller.notifications;
      if (list.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No notifications yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: scrollPhysics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: theme.dividerColor.withOpacity(0.5),
        ),
        itemBuilder: (_, i) {
          final n = list[i];
          return NotificationListTile(
            notification: n,
            onTap: () => controller.markAsRead(n),
          );
        },
      );
    });
  }
}

class NotificationListTile extends StatelessWidget {
  const NotificationListTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWinner = notification.type == 'ROUND_WON';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isWinner
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isWinner ? Icons.emoji_events_rounded : Icons.notifications_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                        color: notification.isRead
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (notification.body != null && notification.body!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
