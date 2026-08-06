import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifs = [];
  bool _loading = true;
  StreamSubscription? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _notificationsSubscription =
        DataService.watchCurrentNotifications().listen((notifications) {
      if (!mounted) return;
      setState(() {
        _notifs = notifications;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    final list = await DataService.getNotifications(user.username);
    if (!mounted) return;
    setState(() {
      _notifs = list;
      _loading = false;
    });

    // Mark as read after rendering
    await DataService.markAllRead(user.username);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _notifs.isEmpty
          ? const Center(
              child: Text(
                'No notifications.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _notifs.length,
              itemBuilder: (ctx, i) {
                final n = _notifs[i];
                IconData icon;
                Color color;
                switch (n.type) {
                  case 'success':
                    icon = Icons.check_circle;
                    color = Colors.green;
                    break;
                  case 'warning':
                    icon = Icons.warning;
                    color = Colors.orange;
                    break;
                  case 'security':
                    icon = Icons.security;
                    color = Colors.red;
                    break;
                  default:
                    icon = Icons.info;
                    color = Colors.blue;
                }

                return Container(
                  color: n.isRead
                      ? Colors.transparent
                      : color.withValues(alpha: 0.05),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(n.message),
                        const SizedBox(height: 8),
                        Text(
                          n.date,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
