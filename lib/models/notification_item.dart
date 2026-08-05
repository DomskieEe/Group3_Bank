class NotificationItem {
  final String id;
  final String username;
  final String title;
  final String message;
  final String type; // 'success', 'warning', 'error', 'security', 'info'
  final String date;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.username,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'title': title,
        'message': message,
        'type': type,
        'date': date,
        'isRead': isRead,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? 'info',
        date: json['date'] ?? '',
        isRead: json['isRead'] ?? false,
      );
}
