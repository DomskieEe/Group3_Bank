class BankCard {
  final String id;
  final String username;
  final String cardNumber;
  final String cardHolder;
  final String expiry;
  final String cardType; // 'debit', 'credit', 'virtual'
  bool isFrozen;
  double spendingLimit;
  final String cvv;

  BankCard({
    required this.id,
    required this.username,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiry,
    required this.cardType,
    this.isFrozen = false,
    this.spendingLimit = 50000.0,
    this.cvv = '•••',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'cardNumber': cardNumber,
        'cardHolder': cardHolder,
        'expiry': expiry,
        'cardType': cardType,
        'isFrozen': isFrozen,
        'spendingLimit': spendingLimit,
        'cvv': cvv,
      };

  factory BankCard.fromJson(Map<String, dynamic> json) => BankCard(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        cardNumber: json['cardNumber'] ?? '',
        cardHolder: json['cardHolder'] ?? '',
        expiry: json['expiry'] ?? '',
        cardType: json['cardType'] ?? 'debit',
        isFrozen: json['isFrozen'] ?? false,
        spendingLimit: (json['spendingLimit'] ?? 50000.0).toDouble(),
        cvv: json['cvv'] ?? '•••',
      );
}
