import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../home/views/equbs_list_screen.dart';
import '../../home/views/home_dashboard_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../main_controller.dart';

class MainShell extends GetView<MainController> {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final index = controller.currentIndex.value;
      return Scaffold(
        body: IndexedStack(
          index: index,
          children: const [
            HomeDashboardScreen(),
            EqubsListScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Theme(
          data: theme.copyWith(
            splashColor: AppColors.primary.withOpacity(0.08),
            highlightColor: AppColors.primary.withOpacity(0.05),
          ),
          child: BottomNavigationBar(
            currentIndex: index,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.brightness == Brightness.dark
                ? theme.colorScheme.surface
                : Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.45),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            elevation: 8,
            items: [
              BottomNavigationBarItem(
                icon: Icon(index == 0 ? Icons.home_rounded : Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  index == 1 ? Icons.groups_rounded : Icons.groups_outlined,
                ),
                label: 'Equbs',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  index == 2 ? Icons.person_rounded : Icons.person_outline,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );
    });
  }
}
