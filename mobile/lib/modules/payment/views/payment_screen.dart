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
  /// Current user's contribution id for the selected round (resolved from round detail when opening from profile).
  String? _myContributionId;
  final RxBool _loadingMyContribution = false.obs;

  /// Effective round when opening from profile (no roundId): comes from fetched active round.
  String? get _effectiveRoundId => widget.roundId?.isNotEmpty == true ? widget.roundId : _activeRoundId;
  int? get _effectiveRoundNumber => widget.roundNumber ?? _activeRoundNumber;
  /// Use contribution from navigation args, or the one we resolved for the current user in this round.
  String? get _effectiveContributionId => widget.contributionId ?? _myContributionId;

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

  Future<void> _loadEqubs() async {
    if (!Get.isRegistered<EqubRepository>()) return;
    final repo = Get.find<EqubRepository>();
    _loadingEqubs.value = true;
    try {
      final list = await repo.list(myEqubsOnly: true, status: 'ACTIVE');
      _equbs.assignAll(list);
      if (list.isNotEmpty) {
        _onEqubSelected(list.first);
      }
    } catch (_) {
      // ignore errors – user will just see no equbs
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
      final round = await Get.find<EqubRepository>().getRoundById(equbId, roundId);
      final contributions = round['contributions'] as List<dynamic>? ?? [];
      final userIdStr = userId.toString();
      for (final c in contributions) {
        final map = c as Map<String, dynamic>;
        final member = map['member'] as Map<String, dynamic>?;
        final user = member?['user'] as Map<String, dynamic>?;
        // API may return camelCase (id) or snake_case (user_id on member)
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
      _amountController.text =
          equb.contributionAmount.toStringAsFixed(0);
      _activeRoundId = null;
      _activeRoundNumber = null;
      _myContributionId = null;
    });
    if (widget.roundId != null && widget.roundId!.isNotEmpty) {
      // Opened with a specific round; still resolve my contribution if not passed
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
      // Active round = latest round that is PENDING or COLLECTING (not yet completed)
      const activeStatuses = ['PENDING', 'COLLECTING'];
      final activeRounds = rounds.where((r) {
        final status = r['status'] as String?;
        return status != null && activeStatuses.contains(status);
      }).toList();
      if (activeRounds.isNotEmpty) {
        activeRounds.sort((a, b) => (b['roundNumber'] as int? ?? 0).compareTo(a['roundNumber'] as int? ?? 0));
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
    }
  }

  Future<void> _submit() async {
    if (widget.alreadyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already paid for this round.'),
        ),
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

    final parsedAmount =
        double.tryParse(_amountController.text.trim());
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay contribution'),
      ),
      body: Obx(() {
        final isSubmitting = _paymentController.isSubmitting.value;
        final loadingEqubs = _loadingEqubs.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_effectiveRoundNumber != null) ...[
                Text(
                  'Round $_effectiveRoundNumber',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              Obx(() {
                if (_loadingActiveRound.value && _effectiveRoundId == null && widget.roundId == null)
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Loading round…'),
                      ],
                    ),
                  );
                if (_effectiveRoundId == null && _selectedEqub != null && widget.roundId == null)
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'No active round for this equb. You can only pay when a round has started.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                if (_loadingMyContribution.value && _effectiveRoundId != null && widget.contributionId == null)
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Loading your contribution…'),
                      ],
                    ),
                  );
                if (_effectiveRoundId != null && _effectiveContributionId == null && !_loadingMyContribution.value && widget.contributionId == null)
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Your contribution for this round could not be linked automatically. You can still submit; the organizer will link your payment to the correct contribution.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  );
                return const SizedBox.shrink();
              }),
              if (widget.alreadyPaid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'You have already paid for this round.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
              Text(
                'Select equb',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (loadingEqubs)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_equbs.isEmpty)
                Text(
                  'You have not joined any equbs yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                )
              else
                DropdownButtonFormField<EqubModel>(
                  value: _selectedEqub,
                  items: _equbs
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            _onEqubSelected(value);
                          }
                        },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Choose equb',
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Amount',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (ETB)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedEqub != null) ...[
                Text(
                  'Bank account',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedEqub!.bankName != null &&
                          _selectedEqub!.bankName!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _selectedEqub!.bankName!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (_selectedEqub!.bankAccountName != null &&
                          _selectedEqub!
                              .bankAccountName!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'Account name: ${_selectedEqub!.bankAccountName!}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      if (_selectedEqub!.bankAccountNumber != null &&
                          _selectedEqub!
                              .bankAccountNumber!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'Account number: ${_selectedEqub!.bankAccountNumber!}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      if (_selectedEqub!.bankInstructions != null &&
                          _selectedEqub!
                              .bankInstructions!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _selectedEqub!.bankInstructions!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Payment screenshot',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isSubmitting ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _selectedImage == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 32,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload payment screenshot',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            // ignore: avoid_as
                            // XFile has a path property for Image.file
                            // cast is safe here
                            // ignore: unnecessary_cast
                            File(_selectedImage!.path as String),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                  hintText: 'Transaction number or note',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit payment'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

