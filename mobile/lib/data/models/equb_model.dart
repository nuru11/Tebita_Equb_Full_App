class EqubOrganizerSummary {
  final String id;
  final String fullName;
  final String phone;

  const EqubOrganizerSummary({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory EqubOrganizerSummary.fromJson(Map<String, dynamic> json) {
    return EqubOrganizerSummary(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
    );
  }
}

class EqubModel {
  final String id;
  final String name;
  final String? description;
  final String type;
  final String? equbType;
  final double contributionAmount;
  final String currency;
  final String frequency;
  final String payoutOrderType;
  final int maxMembers;
  final int currentCycleNumber;
  final String? inviteCode;
  final bool isInviteOnly;
  final String status;
  final String memberType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? organizerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EqubOrganizerSummary? organizer;
  final int memberCount;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankInstructions;
  final int currentRoundNumber;
  final double memberPaidAmount;
  final double willPayAmount;
  final int wonRoundNumber;
  final bool hasWon;

  const EqubModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.equbType,
    required this.contributionAmount,
    required this.currency,
    required this.frequency,
    required this.payoutOrderType,
    required this.maxMembers,
    required this.currentCycleNumber,
    this.inviteCode,
    required this.isInviteOnly,
    required this.status,
    required this.memberType,
    this.startDate,
    this.endDate,
    this.organizerId,
    required this.createdAt,
    required this.updatedAt,
    this.organizer,
    required this.memberCount,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankInstructions,
    this.currentRoundNumber = 0,
    this.memberPaidAmount = 0,
    this.willPayAmount = 0,
    this.wonRoundNumber = 0,
    this.hasWon = false,
  });

  factory EqubModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawAmount = json['contributionAmount'];
    final double amount;
    if (rawAmount is num) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      amount = double.tryParse(rawAmount) ?? 0;
    } else {
      amount = 0;
    }

    final organizerJson = json['organizer'] as Map<String, dynamic>?;
    final membersJson = json['members'] as List<dynamic>?;

    return EqubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      equbType: (json['equbType'] ?? json['equb_type']) as String?,
      contributionAmount: amount,
      currency: json['currency'] as String,
      frequency: json['frequency'] as String,
      payoutOrderType: json['payoutOrderType'] as String,
      maxMembers: (json['maxMembers'] as num).toInt(),
      currentCycleNumber: (json['currentCycleNumber'] as num).toInt(),
      inviteCode: json['inviteCode'] as String?,
      isInviteOnly: json['isInviteOnly'] as bool? ?? false,
      status: json['status'] as String,
      memberType: json['memberType'] as String,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      organizerId: json['organizerId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      organizer:
          organizerJson != null ? EqubOrganizerSummary.fromJson(organizerJson) : null,
      memberCount: membersJson != null ? membersJson.length : 0,
      bankName: json['bankName'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankInstructions: json['bankInstructions'] as String?,
      currentRoundNumber: (json['currentRoundNumber'] as num?)?.toInt() ?? 0,
      memberPaidAmount: (json['memberPaidAmount'] as num?)?.toDouble() ?? 0,
      willPayAmount: (json['willPayAmount'] as num?)?.toDouble() ?? 0,
      wonRoundNumber: (json['wonRoundNumber'] as num?)?.toInt() ?? 0,
      hasWon: json['hasWon'] as bool? ?? false,
    );
  }
}

