import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/equb_model.dart';
import '../../../data/repositories/equb_repository.dart';
import '../../../theme/app_colors.dart';
import '../../auth/auth_controller.dart';
import '../payment_controller.dart';

class PaymentScreen extends StatefulWidget {
  final String? equbId;
  final String? roundId;
  final String? contributionId;
  final double? amount;
  final String? currency;
  final int? roundNumber;
  final bool alreadyPaid;

  const PaymentScreen({
    super.key,
    this.equbId,
    this.roundId,
    this.contributionId,
    this.amount,
    this.currency,
    this.roundNumber,
    this.alreadyPaid = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _referenceController = TextEditingController();
  final _amountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  late final PaymentController _paymentController;
  final RxBool _loadingEqubs = false.obs;
  final RxBool _loadingActiveRound = false.obs;
  final RxList<EqubModel> _equbs = <EqubModel>[].obs;
  EqubModel? _selectedEqub;
  String? _activeRoundId;
  int? _activeRoundNumber;
  String? _myContributionId;
  final RxBool _loadingMyContribution = false.obs;

  String? get _effectiveRoundId =>
      widget.roundId?.isNotEmpty == true ? widget.roundId : _activeRoundId;
  int? get _effectiveRoundNumber =>
      widget.roundNumber ?? _activeRoundNumber;
  String? get _effectiveContributionId =>
      widget.contributionId ?? _myContributionId;

  Color get _cardColor =>
      Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).cardColor;

  @override
  void initState() {
    super.initState();
    _paymentController = Get.put(PaymentController());
    _loadEqubs();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    ThemeData theme, {
    String? labelText,
    String? hintText,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.border.withOpacity(0.9)),
    );
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: _cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _loadEqubs({bool preserveSelection = false}) async {
    if (!Get.isRegistered<EqubRepository>()) return;
    final repo = Get.find<EqubRepository>();
    final prevId = _selectedEqub?.id;
    _loadingEqubs.value = true;
    try {
      final list = await repo.list(myEqubsOnly: true, status: 'ACTIVE');
      _equbs.assignAll(list);
      if (list.isEmpty) {
        setState(() => _selectedEqub = null);
        return;
      }
      EqubModel? pick;
      if (preserveSelection && prevId != null) {
        for (final e in list) {
          if (e.id == prevId) {
            pick = e;
            break;
          }
        }
      }
      pick ??= list.first;
      await _onEqubSelected(pick);
    } catch (_) {
      // ignore
    } finally {
      _loadingEqubs.value = false;
    }
  }

  Future<void> _loadMyContribution(String equbId, String roundId) async {
    if (!Get.isRegistered<AuthController>()) return;
    final userId = Get.find<AuthController>().user.value?.id;
    if (userId == null) return;
    if (!Get.isRegistered<EqubRepository>()) return;
    _loadingMyContribution.value = true;
    _myContributionId = null;
    try {
      final round =
          await Get.find<EqubRepository>().getRoundById(equbId, roundId);
      final contributions = round['contributions'] as List<dynamic>? ?? [];
      final userIdStr = userId.toString();
      for (final c in contributions) {
        final map = c as Map<String, dynamic>;
        final member = map['member'] as Map<String, dynamic>?;
        final user = member?['user'] as Map<String, dynamic>?;
        final memberUserId = (user?['id'] ?? member?['userId'])?.toString();
        if (memberUserId != null && memberUserId == userIdStr) {
          final cid = map['id']?.toString();
          if (cid != null && cid.isNotEmpty) {
            setState(() => _myContributionId = cid);
          }
          break;
        }
      }
    } catch (_) {
      setState(() => _myContributionId = null);
    } finally {
      _loadingMyContribution.value = false;
    }
  }

  Future<void> _onEqubSelected(EqubModel equb) async {
    setState(() {
      _selectedEqub = equb;
      _amountController.text = equb.contributionAmount.toStringAsFixed(0);
      _activeRoundId = null;
      _activeRoundNumber = null;
      _myContributionId = null;
    });
    if (widget.roundId != null && widget.roundId!.isNotEmpty) {
      if (widget.contributionId == null && _selectedEqub != null) {
        await _loadMyContribution(equb.id, widget.roundId!);
      }
      return;
    }
    if (!Get.isRegistered<EqubRepository>()) return;
    final repo = Get.find<EqubRepository>();
    _loadingActiveRound.value = true;
    try {
      final rounds = await repo.getRounds(equb.id);
      const activeStatuses = ['PENDING', 'COLLECTING'];
      final activeRounds = rounds.where((r) {
        final status = r['status'] as String?;
        return status != null && activeStatuses.contains(status);
      }).toList();
      if (activeRounds.isNotEmpty) {
        activeRounds.sort((a, b) =>
            (b['roundNumber'] as int? ?? 0).compareTo(a['roundNumber'] as int? ?? 0));
        final current = activeRounds.first;
        final roundId = current['id'] as String?;
        setState(() {
          _activeRoundId = roundId;
          _activeRoundNumber = current['roundNumber'] as int?;
        });
        if (roundId != null) await _loadMyContribution(equb.id, roundId);
      } else {
        setState(() {
          _activeRoundId = null;
          _activeRoundNumber = null;
        });
      }
    } catch (_) {
      setState(() {
        _activeRoundId = null;
        _activeRoundNumber = null;
      });
    } finally {
      _loadingActiveRound.value = false;
    }
  }

  Future<void> _pickImage() async {
    final theme = Theme.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                title: const Text('Take photo'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _submit() async {
    if (widget.alreadyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already paid for this round.')),
      );
      return;
    }
    final roundId = _effectiveRoundId;
    if (roundId == null || roundId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active round for this equb. You can only pay when a round has started.',
          ),
        ),
      );
      return;
    }
    if (_selectedEqub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an equb.')),
      );
      return;
    }

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment screenshot.')),
      );
      return;
    }
    final bytes = await _selectedImage!.readAsBytes();
    final base64 = base64Encode(bytes);

    try {
      await _paymentController.submitPayment(
        equbId: _selectedEqub?.id ?? widget.equbId,
        roundId: roundId,
        contributionId: _effectiveContributionId,
        amount: parsedAmount,
        currency: _selectedEqub?.currency ?? widget.currency ?? 'ETB',
        imageBase64: base64,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment screenshot submitted. Admin will review and mark as paid.',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      final msg = _paymentController.errorMessage.value.isNotEmpty
          ? _paymentController.errorMessage.value
          : 'Payment failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: theme.colorScheme.onSurface.withOpacity(0.55),
      ),
    );
  }

  Widget _loadingRow(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarBg =
        theme.brightness == Brightness.light ? AppColors.background : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appBarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Pay contribution',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh',
              onPressed: _loadingEqubs.value
                  ? null
                  : () => _loadEqubs(preserveSelection: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final isSubmitting = _paymentController.isSubmitting.value;
        final loadingEqubs = _loadingEqubs.value;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadEqubs(preserveSelection: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_effectiveRoundNumber != null) ...[
                  Material(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(18),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.layers_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current round',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Round $_effectiveRoundNumber',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Obx(() {
                  if (_loadingActiveRound.value &&
                      _effectiveRoundId == null &&
                      widget.roundId == null) {
                    return _loadingRow('Loading round…');
                  }
                  if (_effectiveRoundId == null &&
                      _selectedEqub != null &&
                      widget.roundId == null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _InfoCard(
                        icon: Icons.info_outline_rounded,
                        foreground: theme.colorScheme.error,
                        background: theme.colorScheme.error.withOpacity(0.08),
                        child: Text(
                          'No active round for this equb. You can only pay when a round has started.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.85),
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  if (_loadingMyContribution.value &&
                      _effectiveRoundId != null &&
                      widget.contributionId == null) {
                    return _loadingRow('Loading your contribution…');
                  }
                  if (_effectiveRoundId != null &&
                      _effectiveContributionId == null &&
                      !_loadingMyContribution.value &&
                      widget.contributionId == null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _InfoCard(
                        icon: Icons.link_off_rounded,
                        foreground: AppColors.warning,
                        background: AppColors.warning.withOpacity(0.12),
                        child: Text(
                          'Your contribution could not be linked automatically. You can still submit; the organizer will link your payment.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                if (widget.alreadyPaid) ...[
                  _InfoCard(
                    icon: Icons.check_circle_outline_rounded,
                    foreground: AppColors.primary,
                    background: AppColors.primary.withOpacity(0.10),
                    child: Text(
                      'You have already paid for this round.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withOpacity(0.88),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                _sectionLabel(theme, 'Equb'),
                const SizedBox(height: 8),
                if (loadingEqubs)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_equbs.isEmpty)
                  Material(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurface.withOpacity(0.22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'You have not joined any active equbs yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.62),
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Material(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: DropdownButtonFormField<EqubModel>(
                        value: _selectedEqub,
                        items: _equbs
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) _onEqubSelected(value);
                              },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          hintText: 'Choose equb',
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                        isExpanded: true,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _sectionLabel(theme, 'Amount'),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !isSubmitting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: _fieldDecoration(
                    theme,
                    labelText:
                        'Amount (${_selectedEqub?.currency ?? widget.currency ?? 'ETB'})',
                  ),
                ),
                if (_selectedEqub != null) ...[
                  const SizedBox(height: 20),
                  _sectionLabel(theme, 'Bank details'),
                  const SizedBox(height: 8),
                  Material(
                    color: _cardColor,
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Transfer to',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_selectedEqub!.bankName != null &&
                              _selectedEqub!.bankName!.trim().isNotEmpty)
                            Text(
                              _selectedEqub!.bankName!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          if (_selectedEqub!.bankAccountName != null &&
                              _selectedEqub!.bankAccountName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Account name: ${_selectedEqub!.bankAccountName!}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withOpacity(0.72),
                              ),
                            ),
                          ],
                          if (_selectedEqub!.bankAccountNumber != null &&
                              _selectedEqub!.bankAccountNumber!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            SelectableText(
                              _selectedEqub!.bankAccountNumber!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                          if (_selectedEqub!.bankInstructions != null &&
                              _selectedEqub!.bankInstructions!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _selectedEqub!.bankInstructions!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                  color: theme.colorScheme.onSurface.withOpacity(0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _sectionLabel(theme, 'Payment proof'),
                const SizedBox(height: 8),
                Material(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 1,
                  shadowColor: Colors.black.withOpacity(0.05),
                  child: InkWell(
                    onTap: isSubmitting ? null : _pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      alignment: Alignment.center,
                      child: _selectedImage == null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to add screenshot',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'Upload a clear photo of your transfer receipt.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.55),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Material(
                                      color: Colors.black54,
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: isSubmitting
                                            ? null
                                            : () => setState(() => _selectedImage = null),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _referenceController,
                  enabled: !isSubmitting,
                  decoration: _fieldDecoration(
                    theme,
                    labelText: 'Reference (optional)',
                    hintText: 'Transaction number or note',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Submit payment',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.child,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
