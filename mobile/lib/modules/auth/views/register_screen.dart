import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes.dart';
import '../../../theme/app_colors.dart';
import '../auth_controller.dart';
import 'auth_ui_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _referenceCodeController;
  bool _obscurePassword = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  AuthController get _authController => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _referenceCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _referenceCodeController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final verificationId = await _authController.requestRegisterOtp(
      phone: _phoneController.text.trim(),
    );
    if (verificationId == null || !mounted) return;
    Get.toNamed(
      AppRoutes.registerOtp,
      arguments: {
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'referenceCode': _referenceCodeController.text.trim().isEmpty
            ? null
            : _referenceCodeController.text.trim(),
        'verificationId': verificationId,
        'retryAfter': _authController.otpRetryAfter.value,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkTheme
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    AppColors.primary.withOpacity(0.06),
                    AppColors.background,
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthLogo(),
                    const SizedBox(height: 32),
                    Text(
                      'Create your account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to join equbs and manage your contributions in one place.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AuthTabs(isLogin: false),
                            const SizedBox(height: 28),
                            AuthErrorBanner(controller: _authController),
                            const SizedBox(height: 20),
                            AuthModernTextField(
                              controller: _fullNameController,
                              label: 'Full name',
                              hint: 'Your name',
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.person_rounded,
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return 'Full name is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            AuthModernTextField(
                              controller: _emailController,
                              label: 'Email (optional)',
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.email_rounded,
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return null;
                                if (!s.contains('@') || !s.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            AuthModernTextField(
                              controller: _referenceCodeController,
                              label: 'Reference code (optional)',
                              hint: 'Enter code',
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.tag_rounded,
                              validator: (v) => null,
                            ),
                            const SizedBox(height: 20),
                            AuthModernTextField(
                              controller: _phoneController,
                              label: 'Phone number',
                              hint: '09XXXXXXXX',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.phone_android_rounded,
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return 'Phone is required';
                                if (s.length != 10 || !s.startsWith('09')) {
                                  return 'Use 10 digits starting with 09';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            AuthModernTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'At least 6 characters',
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              prefixIcon: Icons.lock_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  size: 22,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                              validator: (v) {
                                final s = v ?? '';
                                if (s.isEmpty) return 'Password is required';
                                if (s.length < 6) {
                                  return 'At least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.55),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Obx(() {
                              final isLoading =
                                  _authController.isLoading.value;
                              return FilledButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!
                                            .validate()) return;
                                        _authController.clearError();
                                        await _requestOtp();
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<
                                              Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Send security code',
                                      ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.offNamed('/login'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
