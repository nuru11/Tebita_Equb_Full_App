import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../auth/auth_controller.dart';
import '../../../data/models/equb_model.dart';
import '../../home/home_controller.dart';
import '../../main/main_controller.dart';
import '../../payment/views/payment_screen.dart';
import '../../profile/notification_controller.dart';
import 'notifications_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final PageController _bannerController = PageController(viewportFraction: 0.88);
  int _bannerPage = 0;

  @override
  void initState() {
    super.initState();
    // Preload equbs for category rows on the dashboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<HomeController>()) return;
      final homeController = Get.find<HomeController>();
      if (homeController.showMyEqubsOnly.value) {
        homeController.showMyEqubsOnly.value = false;
        homeController.fetchEqubs(myEqubsOnly: false);
        return;
      }
      if (homeController.equbs.isEmpty && !homeController.isLoading.value) {
        homeController.fetchEqubs(myEqubsOnly: false);
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  String _initials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].length >= 2
        ? parts[0].substring(0, 2).toUpperCase()
        : parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    final homeController = Get.find<HomeController>();
    final mainController = Get.find<MainController>();
    final notificationController = Get.find<NotificationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await notificationController.fetchNotifications();
                homeController.showMyEqubsOnly.value = false;
                await homeController.fetchEqubs(myEqubsOnly: false, isRefresh: true);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DashboardHeader(
                      authController: authController,
                      notificationController: notificationController,
                      mainController: mainController,
                      initialsBuilder: _initials,
                    ),
                    const SizedBox(height: 20),
                    _SavingsCard(
                      theme: theme,
                      homeController: homeController,
                      mainController: mainController,
                    ),
                    const SizedBox(height: 20),
                    _BannerCarousel(
                      controller: _bannerController,
                      page: _bannerPage,
                      onPageChanged: (i) => setState(() => _bannerPage = i),
                    ),
                    const SizedBox(height: 20),
                    _RoundWonBannerHost(notificationController: notificationController),
                    // _JoinEqubCard(
                    //   onTap: () => mainController.openBrowseAllEqubs(),
                    // ),
                    const SizedBox(height: 20),
                    _CategoryRows(homeController: homeController),
                    const SizedBox(height: 20),
                    _FeatureGrid(theme: theme),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 8,
              child: _HelpFab(theme: theme),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRows extends StatelessWidget {
  const _CategoryRows({required this.homeController});

  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<EqubModel> equbs = homeController.equbs;
      if (homeController.isLoading.value && equbs.isEmpty) {
        return const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      final house = _filterByType(equbs, 'House');
      final car = _filterByType(equbs, 'Car');
      final stove = _filterByType(equbs, 'Stove');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryRow(title: 'House Equb', items: house),
          const SizedBox(height: 18),
          _CategoryRow(title: 'Car Equb', items: car),
          const SizedBox(height: 18),
          _CategoryRow(title: 'Stove Equb', items: stove),
        ],
      );
    });
  }

  List<EqubModel> _filterByType(List<EqubModel> equbs, String type) {
    return equbs.where((e) {
      final t = e.equbType;
      if (t == null || t.trim().isEmpty) return false;
      return t.trim().toLowerCase() == type.toLowerCase();
    }).toList();
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.title, required this.items});

  final String title;
  final List<EqubModel> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              Text(
                '${items.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: items.isEmpty
              ? _EmptyCategoryHint(title: title)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    return _EqubMiniCard(equb: items[i]);
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyCategoryHint extends StatelessWidget {
  const _EmptyCategoryHint({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No $title equb yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EqubMiniCard extends StatelessWidget {
  const _EqubMiniCard({required this.equb});

  final EqubModel equb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String id = equb.id;
    final String name = equb.name;
    final String currency = equb.currency;
    final double amount = equb.contributionAmount;
    final int members = equb.memberCount;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.equbDetail, arguments: id),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_rounded,
                          size: 16,
                          color: AppColors.primary.withOpacity(0.95),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${amount.toStringAsFixed(0)} $currency',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$members',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'View details',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.authController,
    required this.notificationController,
    required this.mainController,
    required this.initialsBuilder,
  });

  final AuthController authController;
  final NotificationController notificationController;
  final MainController mainController;
  final String Function(String?) initialsBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Obx(() {
            final user = authController.user.value;
            final name = user?.fullName ?? 'Guest';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }),
        ),
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => Get.snackbar(
              'Language',
              'Amharic / multilingual support coming soon.',
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            ),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                'አ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Obx(() {
          final unread = notificationController.notifications
              .where((n) => !n.isRead)
              .length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => Get.to(() => const NotificationsScreen()),
                icon: const Icon(Icons.notifications_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: unread > 9 ? 5 : 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),
        const SizedBox(width: 4),
        Obx(() {
          final user = authController.user.value;
          return Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => mainController.changeTab(2),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Text(
                    initialsBuilder(user?.fullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({
    required this.theme,
    required this.homeController,
    required this.mainController,
  });

  final ThemeData theme;
  final HomeController homeController;
  final MainController mainController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final joined = homeController.joinedEqubIds;
      final recentJoined = homeController.equbs
          .where((e) => joined.contains(e.id))
          .take(3)
          .toList();

      return Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earn Equb',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Br 0.00',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Recent activity',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (recentJoined.isEmpty)
                    Text(
                      'Join an equb to start earning.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in recentJoined)
                          InkWell(
                            onTap: () => Get.toNamed(
                              AppRoutes.equbDetail,
                              arguments: e.id,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      e.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.92),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${e.contributionAmount.toStringAsFixed(0)} ${e.currency}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withOpacity(0.82),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => mainController.openBrowseAllEqubs(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Browse equbs',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.92),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.controller,
    required this.page,
    required this.onPageChanged,
  });

  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;

  static const _slides = [
    _BannerSlide(
      color: Color(0xFF9B59B6),
      icon: Icons.menu_book_rounded,
      title: 'Learn About Equbs',
      subtitle: 'Discover how equbs help you save and reach your goals together.',
    ),
    _BannerSlide(
      color: Color(0xFFE67E22),
      icon: Icons.payment_rounded,
      title: 'How payments work',
      subtitle: 'Submit your contribution on time and track every transaction.',
    ),
    _BannerSlide(
      color: Color(0xFF3498DB),
      icon: Icons.groups_rounded,
      title: 'Join a circle',
      subtitle: 'Browse active equbs and start your saving journey today.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: _slides.length,
            padEnds: true,
            itemBuilder: (context, i) {
              final s = _slides[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: s.color.withOpacity(0.18), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -18,
                          top: -26,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: s.color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: s.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: s.color.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                s.icon,
                                color: s.color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    s.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.62),
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: s.color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                color: s.color.withOpacity(0.9),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withOpacity(0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerSlide {
  const _BannerSlide({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _RoundWonBannerHost extends StatelessWidget {
  const _RoundWonBannerHost({
    required this.notificationController,
  });

  final NotificationController notificationController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final wins = notificationController.notifications
          .where((n) => n.type == 'ROUND_WON' && !n.isRead)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final win = wins.isEmpty ? null : wins.first;
      if (win == null) return const SizedBox.shrink();

      return _RoundWonBanner(
        key: ValueKey(win.id),
        notification: win,
        duration: const Duration(days: 1),
        onDismiss: () => notificationController.markAsRead(win),
      );
    });
  }
}

class _RoundWonBanner extends StatefulWidget {
  const _RoundWonBanner({
    required this.notification,
    required this.duration,
    required this.onDismiss,
    super.key,
  });

  final NotificationModel notification;
  final Duration duration;
  final Future<void> Function() onDismiss;

  @override
  State<_RoundWonBanner> createState() => _RoundWonBannerState();
}

class _RoundWonBannerState extends State<_RoundWonBanner> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _onTimeout);
  }

  Future<void> _onTimeout() async {
    if (!mounted) return;
    setState(() => _visible = false);
    await widget.onDismiss();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _visible = false);
    await widget.onDismiss();
  }

  Future<void> _openDetails() async {
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _visible = false);
    await widget.onDismiss();
    if (!mounted) return;
    Get.to(() => const NotificationsScreen());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_visible) return const SizedBox.shrink();

    final title = widget.notification.title;
    final body = widget.notification.body;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Material(
        key: ValueKey(widget.notification.id),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.25),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            onTap: _openDetails,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (body != null && body.trim().isNotEmpty)
                        Text(
                          body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.62),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _dismiss(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class _JoinEqubCard extends StatelessWidget {
//   const _JoinEqubCard({required this.onTap});

//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(18),
//       elevation: 2,
//       shadowColor: Colors.black.withOpacity(0.06),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: const BoxDecoration(
//                   color: AppColors.primary,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.add, color: Colors.white, size: 24),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Join Equb',
//                       style: theme.textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Discover equbs and start your journey',
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: theme.colorScheme.onSurface.withOpacity(0.55),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.chevron_right_rounded,
//                 color: theme.colorScheme.onSurface.withOpacity(0.35),
//                 size: 28,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Keep tiles tall enough after redesign to avoid RenderFlex overflow.
      childAspectRatio: 0.98,
      children: [
        _FeatureTile(
          label: 'Make Payment',
          description: 'Upload proof and confirm your contribution.',
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primary.withOpacity(0.12),
          onTap: () => Get.to(() => const PaymentScreen()),
        ),
        _FeatureTile(
          label: 'Equb Book',
          description: 'View your history and contribution status.',
          icon: Icons.menu_book_outlined,
          iconColor: const Color(0xFF3498DB),
          iconBg: const Color(0xFF3498DB).withOpacity(0.12),
          onTap: () => Get.toNamed(AppRoutes.transactions),
        ),
        _FeatureTile(
          label: 'Your Referral',
          description: 'Invite friends and earn more perks.',
          icon: Icons.card_giftcard_rounded,
          iconColor: const Color(0xFFE67E22),
          iconBg: const Color(0xFFE67E22).withOpacity(0.12),
          onTap: () => Get.snackbar(
            'Referrals',
            'Referral program coming soon.',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
          ),
        ),
        _FeatureTile(
          label: 'Lucky Draw',
          description: 'Prizes & winners updates.',
          icon: Icons.celebration_rounded,
          iconColor: const Color(0xFFE67E22),
          iconBg: const Color(0xFFE67E22).withOpacity(0.12),
          badge: '2',
          onTap: () => Get.snackbar(
            'Lucky Draw',
            'Check back soon for draws and prizes.',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.label,
    this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String? description;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = iconColor.withOpacity(0.10);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: iconColor.withOpacity(0.20),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top accent strip
                  Container(
                    height: 7,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconColor.withOpacity(0.92),
                          iconColor.withOpacity(0.22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: iconColor.withOpacity(0.24),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: iconColor.withOpacity(0.22),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.62),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                right: 8,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.75),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HelpFab extends StatelessWidget {
  const _HelpFab({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4, right: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Help',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Help & support'),
              content: const Text(
                'Need assistance? Contact your equb organizer or reach out through the app support channel.\n\nMore help options will be available soon.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 4,
          child: const Icon(Icons.headset_mic_rounded, color: Colors.white),
        ),
      ],
    );
  }
}
