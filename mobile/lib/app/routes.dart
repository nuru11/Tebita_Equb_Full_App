import 'package:get/get.dart';

import '../modules/auth/auth_binding.dart';
import '../modules/auth/views/login_screen.dart';
import '../modules/auth/views/register_screen.dart';
import '../modules/auth/views/register_otp_screen.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/views/home_screen.dart';
import '../modules/main/main_binding.dart';
import '../modules/main/views/main_shell.dart';
import '../modules/equb/equb_detail_binding.dart';
import '../modules/equb/equb_winners_binding.dart';
import '../modules/equb/views/equb_detail_screen.dart';
import '../modules/equb/views/equb_winners_screen.dart';
import '../modules/splash/views/splash_screen.dart';
import '../modules/transactions/transactions_binding.dart';
import '../modules/transactions/views/transactions_screen.dart';
import '../modules/profile/views/edit_profile_screen.dart';
import '../modules/profile/views/my_equbs_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerOtp = '/register/otp';
  static const String home = '/home';
  static const String main = '/main';
  static const String equbDetail = '/equbs/detail';
  static const String equbWinners = '/equbs/winners';
  static const String transactions = '/transactions';
  static const String editProfile = '/profile/edit';
  static const String myEqubs = '/profile/my-equbs';

  static List<GetPage> get pages => [
        GetPage(
          name: splash,
          page: () => const SplashScreen(),
          // No binding: splash does not need a controller; auth check uses InitialBinding deps
        ),
        GetPage(
          name: login,
          page: () => const LoginScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: register,
          page: () => const RegisterScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: registerOtp,
          page: () => const RegisterOtpScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: home,
          page: () => const HomeScreen(),
          binding: HomeBinding(),
        ),
        GetPage(
          name: main,
          page: () => const MainShell(),
          binding: MainBinding(),
        ),
        GetPage(
          name: equbDetail,
          page: () => const EqubDetailScreen(),
          binding: EqubDetailBinding(),
        ),
        GetPage(
          name: equbWinners,
          page: () => const EqubWinnersScreen(),
          binding: EqubWinnersBinding(),
        ),
        GetPage(
          name: transactions,
          page: () => const TransactionsScreen(),
          binding: TransactionsBinding(),
        ),
        GetPage(
          name: editProfile,
          page: () => const EditProfileScreen(),
        ),
        GetPage(
          name: myEqubs,
          page: () => const MyEqubsScreen(),
        ),
      ];
}
