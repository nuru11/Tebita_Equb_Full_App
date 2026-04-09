import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes.dart';
import '../../../data/equb_schedule.dart';
import '../../home/home_controller.dart';
import '../../../theme/app_colors.dart';
import '../equb_detail_controller.dart';

class EqubDetailScreen extends GetView<EqubDetailController> {
  const EqubDetailScreen({super.key});

  static (IconData, Color) _typeVisual(String? equbType) {
    final t = equbType?.trim().toLowerCase() ?? '';
    if (t == 'car') return (Icons.directions_car_rounded, AppColors.primary);
    if (t == 'stove') {
      return (Icons.local_fire_department_rounded, const Color(0xFFF59E0B));
    }
    if (t == 'house') return (Icons.home_rounded, const Color(0xFF60A5FA));
    if (t == 'cash') return (Icons.attach_money_rounded, const Color(0xFFFB923C));
    if (t == 'motorcycle') {
      return (Icons.two_wheeler_rounded, const Color(0xFFEF4444));
    }
    return (Icons.group_work_rounded, AppColors.primary);
  }

  static String _formatYmd(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final appBarBg = isLight ? AppColors.background : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appBarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Equb detail',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh',
              onPressed: controller.isLoading.value ? null : () => controller.refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => controller.refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final equb = controller.equb.value;
        if (equb == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: theme.colorScheme.onSurface.withOpacity(0.28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Equb not found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Go back'),
                  ),
                ],
              ),
            ),
          );
        }

        final hasCap = equb.maxMembers > 0;
        final progress = hasCap && equb.maxMembers > 0
            ? equb.memberCount / equb.maxMembers
            : 0.0;
        final isFull = hasCap && equb.memberCount >= equb.maxMembers;
        final (typeIcon, accentColor) = _typeVisual(equb.equbType);
        final cardColor = isLight ? Colors.white : theme.cardColor;

        Widget buildScroll() {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.22),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(typeIcon, color: accentColor, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      equb.name,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.35,
                                        height: 1.2,
                                      ),
                                    ),
                                    if (equb.description != null &&
                                        equb.description!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        equb.description!.trim(),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.68),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _DetailStatusChip(status: equb.status),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${equb.contributionAmount.toStringAsFixed(0)} ${equb.currency} · ${equb.frequency}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionLabel(text: 'Overview', theme: theme),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.schedule_outlined,
                          label: 'Frequency',
                          value: equb.frequency.toLowerCase(),
                          tint: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                       Expanded(
                        child: _StatTile(
                          icon: Icons.badge_outlined,
                          label: 'Your role',
                          value: equb.memberType,
                          tint: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: _StatTile(
                  //         icon: Icons.category_outlined,
                  //         label: 'Type',
                  //         value: equb.type,
                  //         tint: const Color(0xFF8B5CF6),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 10),
                  //     Expanded(
                  //       child: _StatTile(
                  //         icon: Icons.badge_outlined,
                  //         label: 'Your role',
                  //         value: equb.memberType,
                  //         tint: AppColors.warning,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  if (hasCap) ...[
                    const SizedBox(height: 14),
                    Material(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 1,
                      shadowColor: Colors.black.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Spots filled',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${equb.memberCount}/${equb.maxMembers}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: theme.colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.5),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _SectionLabel(text: 'Schedule', theme: theme),
                  const SizedBox(height: 10),
                  Material(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DateColumn(
                              label: 'Start',
                              value: _formatYmd(equb.startDate),
                              theme: theme,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.border.withOpacity(0.85),
                          ),
                          Expanded(
                            child: _DateColumn(
                              label: 'End',
                              value: _formatYmd(equb.endDate),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (equb.organizer != null) ...[
                    const SizedBox(height: 22),
                    _SectionLabel(text: 'Organizer', theme: theme),
                    const SizedBox(height: 10),
                    Material(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 1,
                      shadowColor: Colors.black.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              child: Text(
                                _organizerInitial(equb.organizer!.fullName),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    equb.organizer!.fullName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_android_rounded,
                                        size: 16,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.45),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          equb.organizer!.phone,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.62),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (controller.isJoined) ...[
                    const SizedBox(height: 22),
                    _SectionLabel(text: 'Transparency', theme: theme),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (controller.roundsSummaryLoading.value) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(minHeight: 4),
                          ),
                        );
                      }
                      if (controller.roundsSummaryError.value.isNotEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer
                                .withOpacity(0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: theme.colorScheme.error,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  controller.roundsSummaryError.value,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final next = controller.nextRoundDueSummary.value;
                      final last = controller.lastWinnerSummary.value;
                      return Material(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 1,
                        shadowColor: Colors.black.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.event_available_rounded,
                                      size: 22,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Next collection due',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.55),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          next != null
                                              ? formatScheduleDate(next)
                                              : 'No upcoming round scheduled',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (last != null && last.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.emoji_events_outlined,
                                        size: 18,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Latest winner: $last',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            height: 1.35,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.72),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: FilledButton.tonal(
                                  onPressed: () => Get.toNamed(
                                    AppRoutes.equbWinners,
                                    arguments: {
                                      'equbId': equb.id,
                                      'equbName': equb.name,
                                    },
                                  ),
                                  style: FilledButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Winners & schedule',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 88),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(child: buildScroll()),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: BoxDecoration(
                  color: appBarBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Obx(() {
                  final joining = controller.isJoining.value;
                  final leaving = controller.isLeaving.value;
                  final joined = controller.isJoined;
                  final homeRegistered = Get.isRegistered<HomeController>();

                  if (joined) {
                    return SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: leaving
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) {
                                        return AlertDialog(
                                          title: const Text('Leave equb?'),
                                          content: const Text(
                                            'Are you sure you want to leave this equb?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('Leave equb'),
                                            ),
                                          ],
                                        );
                                      },
                                    ) ??
                                    false;
                                if (confirmed) await controller.leave();
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: leaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Leave equb',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    );
                  }

                  if (isFull) {
                    return SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHigh,
                          foregroundColor:
                              theme.colorScheme.onSurface.withOpacity(0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Full',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: joining
                          ? null
                          : () async {
                              if (homeRegistered) {
                                final home = Get.find<HomeController>();
                                final currentEqub = controller.equb.value;
                                if (currentEqub != null) {
                                  await home.joinEqub(currentEqub);
                                }
                              } else {
                                await controller.join();
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: joining
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Join this equb',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: theme.colorScheme.onSurface.withOpacity(0.55),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Material(
      color: isLight ? Colors.white : theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: tint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({required this.status});

  final String status;

  (Color, Color) _statusColors(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return (AppColors.primary.withOpacity(0.15), AppColors.primary);
      case 'INACTIVE':
        return (AppColors.error.withOpacity(0.12), AppColors.error);
      case 'PENDING':
        return (AppColors.warning.withOpacity(0.2), AppColors.warning);
      default:
        return (AppColors.primary.withOpacity(0.12), AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

String _organizerInitial(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return t[0].toUpperCase();
}
