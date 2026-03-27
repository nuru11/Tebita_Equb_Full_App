import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes.dart';
import '../home_controller.dart';
import '../../../data/models/equb_model.dart';
import '../../../theme/app_colors.dart';

class EqubsListScreen extends StatefulWidget {
  const EqubsListScreen({super.key});

  @override
  State<EqubsListScreen> createState() => _EqubsListScreenState();
}

class _EqubsListScreenState extends State<EqubsListScreen> {
  final List<String> _filters = const [
    'All',
    'Cash',
    'Car',
    'Motorcycle',
    'Stove',
    'House',
  ];

  String _selectedType = 'All';

  Future<void> _openTypePicker() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Equb Type',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _filters.map((f) {
                    final selected = f == _selectedType;
                    return FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedType = f);
                        Navigator.of(ctx).pop();
                      },
                      backgroundColor: selected
                          ? AppColors.primary.withOpacity(0.14)
                          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                      selectedColor: AppColors.primary.withOpacity(0.18),
                      checkmarkColor: AppColors.primary,
                      side: BorderSide(
                        color: selected ? AppColors.primary : theme.dividerColor,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await homeController.refreshEqubs();
          },
          color: AppColors.primary,
          child: Obx(() {
            final isLoading = homeController.isLoading.value;
            final error = homeController.errorMessage.value;
            final allEqubs = homeController.equbs;
            final showMyOnly = homeController.showMyEqubsOnly.value;

            if (isLoading && allEqubs.isEmpty) {
              return const _LoadingState();
            }

            if (error.isNotEmpty && allEqubs.isEmpty) {
              return _ErrorView(
                message: error,
                onRetry: () => homeController.fetchEqubs(),
              );
            }

            final filtered = _selectedType == 'All'
                ? allEqubs
                : allEqubs.where((e) {
                    final t = e.equbType;
                    if (t == null) return false;
                    return t.trim().toLowerCase() == _selectedType.toLowerCase();
                  }).toList();

            // if (filtered.isEmpty) {
            //   return _EmptyState(showMyOnly: showMyOnly);
            // }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Browse Equbs',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _TopPillButton(
                                label: 'My Equbs',
                                selected: showMyOnly,
                                onTap: () => homeController.toggleMyEqubsOnly(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TopPillButton(
                                label: 'Select Equb Type',
                                selected: _selectedType != 'All',
                                onTap: _openTypePicker,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 46,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (ctx, i) {
                              final f = _filters[i];
                              final selected = f == _selectedType;
                              return FilterChip(
                                selected: selected,
                                label: Text(f),
                                onSelected: (_) => setState(() => _selectedType = f),
                                backgroundColor: selected
                                    ? AppColors.primary.withOpacity(0.14)
                                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.85),
                                selectedColor: AppColors.primary.withOpacity(0.18),
                                checkmarkColor: AppColors.primary,
                                side: BorderSide(
                                  color: selected ? AppColors.primary : theme.dividerColor,
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _EqubJoinCardV2(equb: filtered[index]);
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _TopPillButton extends StatelessWidget {
  const _TopPillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.95)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : theme.dividerColor,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _EqubJoinCardV2 extends StatelessWidget {
  const _EqubJoinCardV2({required this.equb});

  final EqubModel equb;

  static (IconData, Color) _typeMeta(String? equbType) {
    final t = equbType?.trim().toLowerCase() ?? '';
    if (t == 'car') return (Icons.directions_car_rounded, AppColors.primary);
    if (t == 'stove') return (Icons.local_fire_department_rounded, const Color(0xFFF59E0B));
    if (t == 'house') return (Icons.home_rounded, const Color(0xFF60A5FA));
    if (t == 'cash') return (Icons.attach_money_rounded, const Color(0xFFFB923C));
    if (t == 'motorcycle') return (Icons.two_wheeler_rounded, const Color(0xFFEF4444));
    return (Icons.group_work_rounded, AppColors.primary);
  }

  String _formatStartDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.month}/${d.day}/${d.year}';
  }

  String _formatAmount(double amount, String currency) {
    return '${amount.toStringAsFixed(0)} $currency';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeController = Get.find<HomeController>();

    return Obx(() {
      final isJoining = homeController.joiningEqubId.value == equb.id;
      final isJoined = homeController.joinedEqubIds.contains(equb.id);
      final showMyOnly = homeController.showMyEqubsOnly.value;

      final isFull = equb.maxMembers > 0 && equb.memberCount >= equb.maxMembers;

      final (icon, accentColor) = _typeMeta(equb.equbType);
      final accentTint = accentColor.withOpacity(0.10);

      final maxForTotals = equb.maxMembers > 0 ? equb.maxMembers : equb.memberCount;
      final potApprox = equb.contributionAmount * maxForTotals;

      return Material(
        color: theme.brightness == Brightness.dark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.toNamed(AppRoutes.equbDetail, arguments: equb.id),
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
                        color: accentTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withOpacity(0.20), width: 1),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            equb.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Started: ${_formatStartDate(equb.startDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(status: equb.status),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Contribution: ${_formatAmount(equb.contributionAmount, equb.currency)} / ${equb.frequency}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Duration: ${maxForTotals} rounds',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total You Receive: ${_formatAmount(potApprox, equb.currency)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (!showMyOnly)
                  SizedBox(
                    width: double.infinity,
                    child: _JoinButtonV2(
                      isJoining: isJoining,
                      isJoined: isJoined,
                      isFull: isFull,
                      onJoin: () => homeController.joinEqub(equb),
                    ),
                  ),
                if (showMyOnly)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isJoined ? 'Joined' : 'Active',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _JoinButtonV2 extends StatelessWidget {
  const _JoinButtonV2({
    required this.isJoining,
    required this.isJoined,
    required this.isFull,
    required this.onJoin,
  });

  final bool isJoining;
  final bool isJoined;
  final bool isFull;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isJoined) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.45)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Joined',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        ),
        child: Center(
          child: Text(
            'Full',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ),
      );
    }

    return FilledButton(
      onPressed: isJoining ? null : onJoin,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: isJoining
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Join Equb',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: List.generate(4, (index) => const _SkeletonCard()),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? theme.cardColor : Colors.white;
    final shimmer = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
    final shimmerLight = isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 20,
                width: 140,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Container(
                height: 24,
                width: 60,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 14,
            width: 180,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: 120,
            decoration: BoxDecoration(
              color: shimmerLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: shimmerLight,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(
          Icons.error_outline_rounded,
          size: 64,
          color: theme.colorScheme.error.withOpacity(0.8),
        ),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool showMyOnly;

  const _EmptyState({required this.showMyOnly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            showMyOnly ? Icons.savings_rounded : Icons.group_work_rounded,
            size: 56,
            color: AppColors.primary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          showMyOnly ? 'No saving circles yet' : 'No equbs to show',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          showMyOnly
              ? 'Switch to All to discover equbs you can join.'
              : 'Pull down to refresh.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _EqubCard extends StatelessWidget {
  final EqubModel equb;

  const _EqubCard({required this.equb});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeController = Get.find<HomeController>();
    final isFull = equb.maxMembers > 0 && equb.memberCount >= equb.maxMembers;
    final progress = equb.maxMembers > 0
        ? (equb.memberCount / equb.maxMembers).clamp(0.0, 1.0)
        : 0.0;

    return Obx(() {
      final isJoining = homeController.joiningEqubId.value == equb.id;
      final isJoined = homeController.joinedEqubIds.contains(equb.id);
      final showMyOnly = homeController.showMyEqubsOnly.value;

      return Material(
        color: theme.brightness == Brightness.dark
            ? theme.cardTheme.color ?? theme.cardColor
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.06),
        elevation: 2,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.equbDetail, arguments: equb.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        equb.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusChip(status: equb.status),
                  ],
                ),
                if (equb.description != null &&
                    equb.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    equb.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      size: 16,
                      color: AppColors.primary.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${equb.contributionAmount.toStringAsFixed(0)} ${equb.currency}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      equb.frequency.toLowerCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      equb.maxMembers > 0
                          ? '${equb.memberCount} / ${equb.maxMembers} members'
                          : '${equb.memberCount} members',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                if (equb.maxMembers > 0 && equb.maxMembers <= 20) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFull ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                  ),
                ],
                if (equb.organizer != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'By ${equb.organizer!.fullName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (!showMyOnly) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ActionButton(
                      isJoining: isJoining,
                      isJoined: isJoined,
                      isFull: isFull,
                      onJoin: () => homeController.joinEqub(equb),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = _statusColors(status);
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
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

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
}

class _ActionButton extends StatelessWidget {
  final bool isJoining;
  final bool isJoined;
  final bool isFull;
  final VoidCallback onJoin;

  const _ActionButton({
    required this.isJoining,
    required this.isJoined,
    required this.isFull,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (isJoined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Joined',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Full',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
      );
    }

    return FilledButton(
      onPressed: isJoining ? null : onJoin,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isJoining
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Join', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
