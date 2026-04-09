import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes.dart';
import '../../auth/auth_controller.dart';
import '../notification_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../theme/app_colors.dart';
import '../../payment/views/payment_screen.dart';
import '../../home/views/notifications_screen.dart';

class ProfileScreen extends GetView<AuthController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    final user = authController.user.value;
    final notificationController = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => authController.logout(),
            child: Text(
              'Logout',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user != null) ...[
              _ProfileHeader(
                user: user,
                onEdit: () => Get.toNamed(AppRoutes.editProfile),
              ),
              const SizedBox(height: 18),
            ] else ...[
              _NoUserPlaceholder(),
              const SizedBox(height: 24),
            ],

            Text(
              'Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              tiles: [
                _SettingsTileData(
                  icon: Icons.groups_rounded,
                  title: 'My equbs',
                  onTap: () => Get.toNamed(AppRoutes.myEqubs),
                ),
                _SettingsTileData(
                  icon: Icons.receipt_long_rounded,
                  title: 'My transactions',
                  onTap: () => Get.toNamed(AppRoutes.transactions),
                ),
                _SettingsTileData(
                  icon: Icons.payment_rounded,
                  title: 'Submit payment',
                  onTap: () => Get.to(() => const PaymentScreen()),
                ),
                _SettingsTileData(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification',
                  onTap: notificationController == null
                      ? null
                      : () => Get.to(() => const NotificationsScreen()),
                ),
                // _SettingsTileData(
                //   icon: Icons.g_translate_rounded,
                //   title: 'Languages',
                //   onTap: () => _comingSoon(context),
                // ),
                // _SettingsTileData(
                //   icon: Icons.palette_outlined,
                //   title: 'Theme',
                //   trailing: Text(
                //     'Light',
                //     style: theme.textTheme.bodySmall?.copyWith(
                //       color: theme.colorScheme.onSurface.withOpacity(0.6),
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                //   onTap: () => _comingSoon(context),
                // ),
                _SettingsTileData(
                  icon: Icons.info_outline_rounded,
                  title: 'Terms & Conditions',
                  onTap: () => _comingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.user,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = user.fullName.trim();
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final idLabel = (user.referenceCode != null &&
            user.referenceCode!.trim().isNotEmpty)
        ? user.referenceCode!.trim()
        : (user.id.length > 10 ? user.id.substring(0, 10) : user.id);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? Text(
                    initial,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Edit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'ID No : $idLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 18, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  'Standard Member',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoUserPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No user loaded',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTileData {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTileData({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsTileData> tiles;

  const _SettingsCard({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.18 : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            _SettingsRow(tile: tiles[i]),
            if (i != tiles.length - 1)
              Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: theme.dividerColor.withOpacity(0.35),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsTileData tile;

  const _SettingsRow({required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = tile.onTap != null;
    final iconBg = AppColors.primary.withOpacity(0.08);
    return ListTile(
      onTap: tile.onTap,
      enabled: enabled,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          tile.icon,
          size: 20,
          color: enabled
              ? AppColors.primary
              : theme.colorScheme.onSurface.withOpacity(0.35),
        ),
      ),
      title: Text(
        tile.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: tile.trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
