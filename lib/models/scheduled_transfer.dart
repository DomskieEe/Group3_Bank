class ScheduledTransfer {
  final String id;
  final String username;
  final String accountNumber;
  final String beneficiaryName;
  final double amount;
  final bool fromSavings;
  final String note;
  final String scheduledFor;
  final bool repeatsMonthly;
  final bool isActive;

  const ScheduledTransfer({
    required this.id,
    required this.username,
    required this.accountNumber,
    required this.beneficiaryName,
    required this.amount,
    required this.fromSavings,
    required this.note,
    required this.scheduledFor,
    this.repeatsMonthly = false,
    this.isActive = true,
  });

  DateTime get dueDate => DateTime.tryParse(scheduledFor) ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'accountNumber': accountNumber,
        'beneficiaryName': beneficiaryName,
        'amount': amount,
        'fromSavings': fromSavings,
        'note': note,
        'scheduledFor': scheduledFor,
        'repeatsMonthly': repeatsMonthly,
        'isActive': isActive,
      };

  factory ScheduledTransfer.fromJson(Map<String, dynamic> json) => ScheduledTransfer(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        accountNumber: json['accountNumber'] ?? '',
        beneficiaryName: json['beneficiaryName'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        fromSavings: json['fromSavings'] ?? true,
        note: json['note'] ?? '',
        scheduledFor: json['scheduledFor'] ?? '',
        repeatsMonthly: json['repeatsMonthly'] ?? false,
        isActive: json['isActive'] ?? true,
      );
}
