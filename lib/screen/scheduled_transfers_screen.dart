import 'package:flutter/material.dart';

import '../models/scheduled_transfer.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class ScheduledTransfersScreen extends StatefulWidget {
  const ScheduledTransfersScreen({super.key});

  @override
  State<ScheduledTransfersScreen> createState() => _ScheduledTransfersScreenState();
}

class _ScheduledTransfersScreenState extends State<ScheduledTransfersScreen> {
  List<ScheduledTransfer> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final items = await DataService.getScheduledTransfers(user.username);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scheduled Transfers')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(child: Text('No scheduled transfers yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, index) {
                      final item = _items[index];
                      final date = item.dueDate;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.schedule)),
                          title: Text(DataService.formatCurrency(item.amount)),
                          subtitle: Text('${item.accountNumber}\n${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}${item.repeatsMonthly ? ' • Monthly' : ''}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            tooltip: 'Cancel schedule',
                            onPressed: () async {
                              await DataService.cancelScheduledTransfer(item.id);
                              await _load();
                            },
                          ),
                        ),
                      );
                    },
                  ),
      );
}
