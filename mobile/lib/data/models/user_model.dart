/// User model from API (safe user, no password).
class UserModel {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String? avatarUrl;
  final String? referenceCode;
  final bool isVerified;
  final bool kyc;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    this.avatarUrl,
    this.referenceCode,
    this.isVerified = false,
    this.kyc = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      referenceCode: json['referenceCode'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      kyc: json['kyc'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'referenceCode': referenceCode,
      'isVerified': isVerified,
      'kyc': kyc,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
