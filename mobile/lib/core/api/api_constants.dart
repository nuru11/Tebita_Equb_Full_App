/// API path constants. Base URL is configured in [ApiClient].
class ApiConstants {
  ApiConstants._();

  static const String auth = '/api/auth';
  static const String register = '$auth/register';
  static const String registerRequestOtp = '$auth/register/request-otp';
  static const String registerVerifyOtp = '$auth/register/verify-otp';
  static const String login = '$auth/login';
  static const String refresh = '$auth/refresh';

  static const String equbs = '/api/equbs';

  static const String payments = '/api/payments';

  static const String users = '/api/users';
  static const String userMe = '$users/me';

  static String equbJoin(String equbId) => '$equbs/$equbId/join';
  static String equbById(String equbId) => '$equbs/$equbId';
  static String equbLeave(String equbId) => '$equbs/$equbId/leave';
  static String equbRounds(String equbId) => '$equbs/$equbId/rounds';
  static String equbRoundById(String equbId, String roundId) =>
      '$equbs/$equbId/rounds/$roundId';

  static const String notifications = '/api/notifications';
  static String notificationMarkRead(String id) => '$notifications/$id/read';
}
