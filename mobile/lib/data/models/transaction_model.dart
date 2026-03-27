/// Represents a payment transaction (e.g. contribution upload) for "My transactions" list.
class TransactionModel {
  final String id;
  final double amount;
  final String currency;
  final String status; // PENDING, SUCCESS, FAILED
  final DateTime createdAt;
  final String? reference;
  final String? equbId;
  final String? equbName;
  final String? roundId;
  final int? roundNumber;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.reference,
    this.equbId,
    this.equbName,
    this.roundId,
    this.roundNumber,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final equb = json['equb'] as Map<String, dynamic>?;
    final round = json['round'] as Map<String, dynamic>?;
    final amount = json['amount'];
    double amountValue = 0;
    if (amount is num) {
      amountValue = amount.toDouble();
    } else if (amount is String) {
      amountValue = double.tryParse(amount) ?? 0;
    }
    return TransactionModel(
      id: json['id'] as String? ?? '',
      amount: amountValue,
      currency: json['currency'] as String? ?? 'ETB',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reference: json['reference'] as String?,
      equbId: equb?['id'] as String?,
      equbName: equb?['name'] as String?,
      roundId: round?['id'] as String?,
      roundNumber: round?['roundNumber'] as int?,
    );
  }
}
