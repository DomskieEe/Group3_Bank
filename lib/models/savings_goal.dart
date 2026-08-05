class SavingsGoal {
  final String id;
  final String username;
  final String title;
  final double targetAmount;
  double currentAmount;
  final String icon;

  SavingsGoal({
    required this.id,
    required this.username,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.icon = 'savings',
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => targetAmount - currentAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'icon': icon,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        title: json['title'] ?? '',
        targetAmount: (json['targetAmount'] ?? 0.0).toDouble(),
        currentAmount: (json['currentAmount'] ?? 0.0).toDouble(),
        icon: json['icon'] ?? 'savings',
      );
}
