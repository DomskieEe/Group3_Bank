import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../models/transaction_model.dart';
import '../models/notification_item.dart';

class BillsScreen extends StatefulWidget {
  final double currentBalance;
  const BillsScreen({super.key, required this.currentBalance});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final List<Map<String, dynamic>> _billCategories = [
    {
      'name': 'Meralco Electric',
      'icon': Icons.flash_on,
      'color': Colors.orange,
    },
    {'name': 'Maynilad Water', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'PLDT Internet', 'icon': Icons.wifi, 'color': Colors.lightBlue},
    {
      'name': 'Globe Mobile Load',
      'icon': Icons.phone_android,
      'color': Colors.green,
    },
    {
      'name': 'Pru Life Insurance',
      'icon': Icons.health_and_safety,
      'color': Colors.red,
    },
    {'name': 'Credit Card', 'icon': Icons.credit_card, 'color': Colors.purple},
    {'name': 'Tuition Fee', 'icon': Icons.school, 'color': Colors.indigo},
    {'name': 'Cignal TV', 'icon': Icons.tv, 'color': Colors.teal},
    {
      'name': 'SSS Contribution',
      'icon': Icons.account_balance,
      'color': Colors.brown,
    },
    {
      'name': 'PhilHealth',
      'icon': Icons.medical_services,
      'color': Colors.cyan,
    },
  ];

  List<TransactionModel> _paymentHistory = [];
  List<Map<String, dynamic>> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final txs = await DataService.getTransactions(user.username);
    final reminders = await DataService.getBillReminders(user.username);
    if (!mounted) return;
    setState(() {
      _paymentHistory = txs.where((t) => t.category == 'bills').toList();
      _reminders = reminders;
      _loading = false;
    });
  }

  Future<void> _showReminders() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bill Reminders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_reminders.isEmpty) const Text('No reminders yet.'),
              ..._reminders.map(
                (reminder) => ListTile(
                  leading: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFFD32F2F),
                  ),
                  title: Text(reminder['billName'] as String),
                  subtitle: Text(
                    'Due every month on day ${reminder['dueDay']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await DataService.removeBillReminder(
                        reminder['id'] as String,
                      );
                      await _loadHistory();
                      if (!ctx.mounted) return;
                      setModalState(() {});
                    },
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addReminder(ctx, setModalState),
                icon: const Icon(Icons.add),
                label: const Text('Add reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addReminder(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    String billName = _billCategories.first['name'] as String;
    final dueCtrl = TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Bill Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: billName,
              items: _billCategories
                  .map(
                    (bill) => DropdownMenuItem(
                      value: bill['name'] as String,
                      child: Text(bill['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) => billName = value ?? billName,
            ),
            TextField(
              controller: dueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Due day (1–31)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final day = int.tryParse(dueCtrl.text);
              final user = AppState.instance.currentUser;
              if (day == null || day < 1 || day > 31 || user == null) return;
              await DataService.saveBillReminder(
                username: user.username,
                billName: billName,
                dueDay: day,
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _loadHistory();
              // Refresh the reminders list inside the bottom sheet.
              if (sheetContext.mounted) {
                setSheetState(() {
                  _reminders = List.from(_reminders)
                    ..removeWhere((r) => r['billName'] == billName)
                    ..add({
                      'id': '',
                      'billName': billName,
                      'dueDay': day,
                      'username': user.username,
                    });
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    dueCtrl.dispose();
  }

  void _payBill(String billName) {
    final controller = TextEditingController();
    final user = AppState.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pay $billName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checking Balance: ${DataService.formatCurrency(user.checkingBalance)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Amount (₱)',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context);
              if (amount > 0) await _processPayment(billName, amount);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(String billName, double amount) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    if (user.checkingBalance < amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient Checking Balance. You have ${DataService.formatCurrency(user.checkingBalance)}.',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    user.checkingBalance -= amount;
    await DataService.updateUser(user);
    // Refresh the in-memory user so all screens show the updated balance.
    AppState.instance.currentUser = user;

    await DataService.addTransaction(
      TransactionModel(
        id: DataService.generateId(),
        username: user.username,
        type: 'debit',
        category: 'bills',
        description: billName,
        amount: amount,
        date: DataService.formatDate(DateTime.now()),
      ),
    );

    await DataService.addNotification(
      NotificationItem(
        id: DataService.generateId(),
        username: user.username,
        title: 'Bill Payment Successful',
        message:
            '${DataService.formatCurrency(amount)} paid for $billName successfully.',
        type: 'success',
        date: DataService.formatDate(DateTime.now()),
      ),
    );

    await _loadHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$billName paid: ${DataService.formatCurrency(amount)}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Bills'),
        actions: [
          IconButton(
            onPressed: _showReminders,
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Bill reminders',
          ),
        ],
      ),
      body: _loading || user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Colors.black],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Checking Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        DataService.formatCurrency(user.checkingBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Biller Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _billCategories.length,
                    itemBuilder: (ctx, i) {
                      final item = _billCategories[i];
                      return GestureDetector(
                        onTap: () => _payBill(item['name']),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item['icon'],
                                color: item['color'],
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['name'].split(' ').first,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Bill Payments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _paymentHistory.isEmpty
                      ? const Center(
                          child: Text(
                            'No bills paid yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _paymentHistory.length,
                          itemBuilder: (context, index) {
                            final tx = _paymentHistory[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: const Icon(
                                    Icons.receipt,
                                    color: Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  tx.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  tx.date,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '- ${DataService.formatCurrency(tx.amount)}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
