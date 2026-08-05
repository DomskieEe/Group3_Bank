import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../services/document_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _allTx = [];
  bool _loading = true;
  String _filter = 'All';
  String _query = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  double? _minimumAmount;
  double? _maximumAmount;
  StreamSubscription? _transactionsSubscription;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _transactionsSubscription =
        DataService.watchCurrentTransactions().listen((transactions) {
      if (!mounted) return;
      setState(() {
        _allTx = transactions;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final txs = await DataService.getTransactions(user.username);
    if (!mounted) return;
    setState(() {
      _allTx = txs;
      _loading = false;
    });
  }

  List<TransactionModel> get _filtered {
    final categoryFiltered = switch (_filter) {
      'Income' => _allTx.where((t) => t.type == 'credit'),
      'Expense' => _allTx.where((t) => t.type == 'debit'),
      'All' => _allTx,
      _ => _allTx.where((t) => t.category == _filter.toLowerCase()),
    };
    final query = _query.toLowerCase();
    return categoryFiltered
        .where(
          (t) =>
              query.isEmpty ||
              '${t.description} ${t.category} ${t.note}'.toLowerCase().contains(
                query,
              ),
        )
        .where((t) {
          final date = DateTime.tryParse(t.date);
          if (date == null) return _fromDate == null && _toDate == null;
          if (_fromDate != null && date.isBefore(_fromDate!)) return false;
          if (_toDate != null && date.isAfter(_toDate!.add(const Duration(days: 1)))) return false;
          return true;
        })
        .where((t) => _minimumAmount == null || t.amount >= _minimumAmount!)
        .where((t) => _maximumAmount == null || t.amount <= _maximumAmount!)
        .toList();
  }

  Future<void> _showAdvancedFilters() async {
    final minCtrl = TextEditingController(text: _minimumAmount?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maximumAmount?.toString() ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Advanced filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () async {
                final value = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDate: _fromDate ?? DateTime.now());
                if (value != null) setSheetState(() => _fromDate = value);
              }, child: Text(_fromDate == null ? 'From date' : _fromDate!.toIso8601String().substring(0, 10)))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () async {
                final value = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDate: _toDate ?? DateTime.now());
                if (value != null) setSheetState(() => _toDate = value);
              }, child: Text(_toDate == null ? 'To date' : _toDate!.toIso8601String().substring(0, 10)))),
            ]),
            const SizedBox(height: 8),
            TextField(controller: minCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Minimum amount')),
            TextField(controller: maxCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Maximum amount')),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () { setState(() { _fromDate = null; _toDate = null; _minimumAmount = null; _maximumAmount = null; }); Navigator.pop(ctx); }, child: const Text('Clear')),
              ElevatedButton(onPressed: () { setState(() { _minimumAmount = double.tryParse(minCtrl.text); _maximumAmount = double.tryParse(maxCtrl.text); }); Navigator.pop(ctx); }, child: const Text('Apply')),
            ]),
          ]),
        ),
      ),
    );
    minCtrl.dispose();
    maxCtrl.dispose();
  }

  void _showDetails(TransactionModel tx) {
    final isCredit = tx.type == 'credit';
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCredit ? 'Money Received' : 'Transaction Details',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              '${isCredit ? '+' : '-'} ${DataService.formatCurrency(tx.amount)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Description', tx.description),
            _detailRow('Category', tx.category.toUpperCase()),
            _detailRow('Date', tx.date),
            _detailRow('Reference ID', tx.id),
            if (tx.note.isNotEmpty) _detailRow('Note', tx.note),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => DocumentService.printReceipt(tx),
                icon: const Icon(Icons.download),
                label: const Text('Receipt PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(onPressed: _showAdvancedFilters, icon: const Icon(Icons.tune), tooltip: 'Advanced filters'),
          IconButton(onPressed: () {
            final user = AppState.instance.currentUser;
            if (user == null) return;
            final now = DateTime.now();
            final monthTransactions = _allTx.where((tx) { final date = DateTime.tryParse(tx.date); return date?.year == now.year && date?.month == now.month; }).toList();
            DocumentService.printMonthlyStatement(user: user, transactions: monthTransactions, month: now);
          }, icon: const Icon(Icons.picture_as_pdf), tooltip: 'Monthly statement PDF'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: 'Search transactions',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children:
                  [
                        'All',
                        'Income',
                        'Expense',
                        'Bills',
                        'Shopping',
                        'Food',
                        'Transfer',
                      ]
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f),
                            selected: _filter == f,
                            selectedColor: const Color(
                              0xFFD32F2F,
                            ).withValues(alpha: 0.15),
                            checkmarkColor: const Color(0xFFD32F2F),
                            onSelected: (_) => setState(() => _filter = f),
                            labelStyle: TextStyle(
                              color: _filter == f
                                  ? const Color(0xFFD32F2F)
                                  : null,
                              fontWeight: _filter == f ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _buildTxTile(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxTile(TransactionModel tx) {
    final isCredit = tx.type == 'credit';
    IconData icon;
    Color iconColor;

    switch (tx.category) {
      case 'salary':
        icon = Icons.payments;
        iconColor = Colors.green;
        break;
      case 'shopping':
        icon = Icons.shopping_bag;
        iconColor = Colors.purple;
        break;
      case 'food':
        icon = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case 'bills':
        icon = Icons.receipt;
        iconColor = Colors.blue;
        break;
      case 'transfer':
        icon = Icons.swap_horiz;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.attach_money;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: () => _showDetails(tx),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          tx.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tx.date, style: const TextStyle(fontSize: 12)),
            if (tx.note.isNotEmpty)
              Text(
                tx.note,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'} ${DataService.formatCurrency(tx.amount)}',
          style: TextStyle(
            color: isCredit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
