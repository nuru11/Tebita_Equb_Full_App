import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../home/home_controller.dart';
import '../../../theme/app_colors.dart';
import '../equb_detail_controller.dart';

class EqubDetailScreen extends GetView<EqubDetailController> {
  const EqubDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equb detail'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Text(controller.errorMessage.value),
          );
        }
        final equb = controller.equb.value;
        if (equb == null) {
          return const Center(child: Text('Equb not found'));
        }

        final hasCap = equb.maxMembers > 0;
        final progress = hasCap && equb.maxMembers > 0
            ? equb.memberCount / equb.maxMembers
            : 0.0;
        final isFull = hasCap && equb.memberCount >= equb.maxMembers;

        Widget buildBody() {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        equb.name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: Text(
                        equb.status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (equb.description != null &&
                    equb.description!.isNotEmpty)
                  Text(
                    equb.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _DetailStat(
                      icon: Icons.payments_outlined,
                      label: 'Contribution',
                      value:
                          '${equb.contributionAmount.toStringAsFixed(0)} ${equb.currency}',
                    ),
                    _DetailStat(
                      icon: Icons.schedule_outlined,
                      label: 'Frequency',
                      value: equb.frequency.toLowerCase(),
                    ),
                    _DetailStat(
                      icon: Icons.swap_horiz_outlined,
                      label: 'Payout',
                      value: equb.payoutOrderType,
                    ),
                    _DetailStat(
                      icon: Icons.group_outlined,
                      label: 'Members',
                      value: hasCap
                          ? '${equb.memberCount}/${equb.maxMembers}'
                          : '${equb.memberCount}',
                    ),
                  ],
                ),
                if (hasCap) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Spots filled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${equb.memberCount} of ${equb.maxMembers} spots',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(equb.type),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Member role',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(equb.memberType),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start date',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            equb.startDate != null
                                ? equb.startDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')
                                    .first
                                : '-',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End date',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            equb.endDate != null
                                ? equb.endDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')
                                    .first
                                : '-',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (equb.organizer != null) ...[
                  Text(
                    'Organizer',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(equb.organizer!.fullName),
                            Text(
                              equb.organizer!.phone,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        }

        final body = buildBody();

        return Column(
          children: [
            Expanded(child: body),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Obx(() {
                    final joining = controller.isJoining.value;
                    final leaving = controller.isLeaving.value;
                    final joined = controller.isJoined;

                    final homeRegistered =
                        Get.isRegistered<HomeController>();

                    if (joined) {
                      return OutlinedButton(
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
                                                  Navigator.of(ctx)
                                                      .pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx)
                                                      .pop(true),
                                              child:
                                                  const Text('Leave equb'),
                                            ),
                                          ],
                                        );
                                      },
                                    ) ??
                                    false;
                                if (confirmed) {
                                  await controller.leave();
                                }
                              },
                        child: leaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Leave equb'),
                      );
                    }

                    if (isFull) {
                      return FilledButton(
                        onPressed: null,
                        child: const Text('Full'),
                      );
                    }

                    return FilledButton(
                      onPressed: joining
                          ? null
                          : () async {
                              if (homeRegistered) {
                                final home =
                                    Get.find<HomeController>();
                                final currentEqub =
                                    controller.equb.value;
                                if (currentEqub != null) {
                                  await home.joinEqub(currentEqub);
                                }
                              } else {
                                await controller.join();
                              }
                            },
                      child: joining
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(
                                        Colors.white),
                              ),
                            )
                          : const Text('Join'),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

