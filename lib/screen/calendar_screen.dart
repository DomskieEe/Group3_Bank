import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_event.dart';
import '../models/transaction_model.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<PaymentEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final list = await DataService.getPaymentEvents(user.username);
    if (!mounted) return;
    setState(() {
      _events = list;
      _loading = false;
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'flight':
        return Icons.flight;
      case 'cake':
        return Icons.cake;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'hotel':
        return Icons.hotel;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'restaurant':
        return Icons.restaurant;
      case 'movie':
        return Icons.movie;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'school':
        return Icons.school;
      case 'medical_services':
        return Icons.medical_services;
      default:
        return Icons.payment;
    }
  }

  Color _getEventColor(PaymentEvent event) {
    if (event.isPaid) return Colors.green;
    final daysUntil = event.date.difference(DateTime.now()).inDays;
    if (daysUntil < 0) return Colors.red; // Overdue
    if (daysUntil <= 3) return Colors.orange; // Due soon
    return const Color(0xFFD32F2F); // Normal
  }

  void _showAddEventDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedType = 'payment';
    String selectedIcon = 'payment';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    final types = [
      {'label': 'Payment', 'value': 'payment', 'icon': 'payment'},
      {'label': 'Flight', 'value': 'flight', 'icon': 'flight'},
      {'label': 'Birthday', 'value': 'birthday', 'icon': 'cake'},
      {'label': 'Bill', 'value': 'bill', 'icon': 'receipt_long'},
      {'label': 'Subscription', 'value': 'subscription', 'icon': 'subscriptions'},
      {'label': 'Insurance', 'value': 'insurance', 'icon': 'local_shipping'},
      {'label': 'Travel', 'value': 'travel', 'icon': 'hotel'},
      {'label': 'Shopping', 'value': 'shopping', 'icon': 'shopping_bag'},
      {'label': 'Dining', 'value': 'dining', 'icon': 'restaurant'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Flight to Cebu',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: types
                      .map((t) => DropdownMenuItem(
                            value: t['value'],
                            child: Row(
                              children: [
                                Icon(_getIconData(t['icon']!), size: 20),
                                const SizedBox(width: 8),
                                Text(t['label']!),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedType = val!;
                      selectedIcon = types.firstWhere(
                        (t) => t['value'] == val,
                      )['icon']!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₱)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    hintText: 'Enter amount (e.g., 1000)',
                    helperText: 'Enter a positive number',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim());
                
                // Validation with feedback
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a title'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(ctx);
                await _addEvent(
                  title,
                  selectedType,
                  selectedIcon,
                  selectedDate,
                  amount,
                  noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEvent(
    String title,
    String type,
    String icon,
    DateTime date,
    double amount,
    String? note,
  ) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    final event = PaymentEvent(
      id: DataService.generateId(),
      username: user.username,
      title: title,
      type: type,
      icon: icon,
      date: date,
      amount: amount,
      note: note,
    );

    await DataService.addPaymentEvent(event);
    await _loadEvents();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment scheduled successfully!')),
    );
  }

  Future<void> _payNow(PaymentEvent event) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    // Check if user has sufficient balance
    if (user.totalBalance < event.amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance.')),
      );
      return;
    }

    // Confirm payment
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Pay ${DataService.formatCurrency(event.amount)} for "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Deduct from savings balance
    user.savingsBalance -= event.amount;
    await DataService.updateUser(user);

    // Mark event as paid
    final updatedEvent = event.copyWith(isPaid: true);
    await DataService.updatePaymentEvent(updatedEvent);

    // Add transaction record
    final transaction = TransactionModel(
      id: DataService.generateId(),
      username: user.username,
      type: 'debit',
      category: event.type,
      description: event.title,
      amount: event.amount,
      date: DataService.formatDate(DateTime.now()),
      note: event.note ?? '',
    );
    await DataService.addTransaction(transaction);

    await _loadEvents();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful! ${DataService.formatCurrency(event.amount)} paid.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteEvent(PaymentEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DataService.deletePaymentEvent(event.id);
    await _loadEvents();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
            tooltip: 'Schedule Payment',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No scheduled payments',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showAddEventDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Schedule Payment'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (ctx, i) => _buildEventCard(_events[i], isDark),
                  ),
                ),
    );
  }

  Widget _buildEventCard(PaymentEvent event, bool isDark) {
    final daysUntil = event.date.difference(DateTime.now()).inDays;
    final eventColor = _getEventColor(event);
    final isOverdue = daysUntil < 0 && !event.isPaid;

    String dueDateText;
    if (event.isPaid) {
      dueDateText = 'Paid ✓';
    } else if (isOverdue) {
      dueDateText = 'Overdue by ${-daysUntil} day${-daysUntil == 1 ? '' : 's'}';
    } else if (daysUntil == 0) {
      dueDateText = 'Due Today';
    } else if (daysUntil == 1) {
      dueDateText = 'Due Tomorrow';
    } else {
      dueDateText = 'Due in $daysUntil days';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: event.isPaid
              ? Colors.green.withValues(alpha: 0.3)
              : eventColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: event.isPaid ? null : () => _deleteEvent(event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(event.icon),
                      color: eventColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: event.isPaid
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(event.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DataService.formatCurrency(event.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: eventColor,
                    ),
                  ),
                ],
              ),
              if (event.note != null && event.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dueDateText,
                        style: TextStyle(
                          color: eventColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (!event.isPaid) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _payNow(event),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Pay Now'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
