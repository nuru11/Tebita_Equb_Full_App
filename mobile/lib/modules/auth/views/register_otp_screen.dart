import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../auth_controller.dart';
import 'auth_ui_components.dart';

class RegisterOtpScreen extends StatefulWidget {
  const RegisterOtpScreen({super.key});

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
  late final AuthController _authController;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;

  late final String _phone;
  late final String _password;
  late final String _fullName;
  final String? _email = Get.arguments?['email'] as String?;
  final String? _referenceCode = Get.arguments?['referenceCode'] as String?;
  String _verificationId = '';

  int _resendSecondsLeft = 0;
  Timer? _resendTimer;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());

    final args = (Get.arguments ?? <String, dynamic>{}) as Map<String, dynamic>;
    _phone = (args['phone'] ?? '').toString();
    _password = (args['password'] ?? '').toString();
    _fullName = (args['fullName'] ?? '').toString();
    _verificationId = (args['verificationId'] ?? '').toString();
    final retryAfter = (args['retryAfter'] as int?) ?? 60;

    if (_phone.isEmpty || _password.isEmpty || _fullName.isEmpty || _verificationId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'Missing registration details. Please start again.');
        Get.offNamed('/register');
      });
      return;
    }

    _startResendCooldown(retryAfter);
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < 6; i++) {
        _otpControllers[i].text = i < digits.length ? digits[i] : '';
      }
      if (digits.length >= 6) {
        _otpFocusNodes[5].unfocus();
      } else if (digits.isNotEmpty) {
        _otpFocusNodes[digits.length].requestFocus();
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSecondsLeft = 0);
      } else if (mounted) {
        setState(() => _resendSecondsLeft--);
      }
    });
  }

  Future<void> _resendCode() async {
    _authController.clearError();
    final verificationId = await _authController.requestRegisterOtp(phone: _phone);
    if (verificationId == null || !mounted) return;
    setState(() => _verificationId = verificationId);
    _startResendCooldown(_authController.otpRetryAfter.value);
  }

  Future<void> _verifyAndCreate() async {
    if (!_isOtpComplete) {
      _authController.errorMessage.value = 'Please enter the 6-digit security code';
      return;
    }

    await _authController.verifyRegisterOtpAndRegister(
      phone: _phone,
      password: _password,
      fullName: _fullName,
      code: _otpCode,
      verificationId: _verificationId,
      email: _email,
      referenceCode: _referenceCode,
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
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthLogo(),
                    const SizedBox(height: 32),
                    Text(
                      'Verify your phone',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the security code sent to $_phone.',
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
                            AuthErrorBanner(controller: _authController),
                            const SizedBox(height: 20),
                            Text(
                              'Security code',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                return SizedBox(
                                  width: 46,
                                  child: TextFormField(
                                    controller: _otpControllers[index],
                                    focusNode: _otpFocusNodes[index],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: isDarkTheme
                                          ? theme.colorScheme.surface.withOpacity(0.5)
                                          : theme.colorScheme.surfaceContainerHighest
                                              .withOpacity(0.4),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.dividerColor.withOpacity(0.5),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.dividerColor.withOpacity(0.5),
                                        ),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                        borderSide:
                                            BorderSide(color: AppColors.primary, width: 2),
                                      ),
                                    ),
                                    onChanged: (value) => _onOtpChanged(index, value),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _resendSecondsLeft > 0 ? null : _resendCode,
                                child: Text(
                                  _resendSecondsLeft > 0
                                      ? 'Resend in ${_resendSecondsLeft}s'
                                      : 'Resend code',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Obx(() {
                              final isLoading = _authController.isLoading.value;
                              return FilledButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        _authController.clearError();
                                        await _verifyAndCreate();
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Verify code and create account'),
                              );
                            }),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Back to register'),
                            ),
                          ],
                        ),
                      ),
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

