class Beneficiary {
  final String id;
  final String username;
  final String nickname;
  final String accountNumber;
  final String createdAt;

  const Beneficiary({
    required this.id,
    required this.username,
    required this.nickname,
    required this.accountNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'accountNumber': accountNumber,
        'createdAt': createdAt,
      };

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        nickname: json['nickname'] ?? '',
        accountNumber: json['accountNumber'] ?? '',
        createdAt: json['createdAt'] ?? '',
      );
}
