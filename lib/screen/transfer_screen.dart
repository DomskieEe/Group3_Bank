import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../models/transaction_model.dart';
import '../models/notification_item.dart';

enum _TransferFrom { savings, checking }

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _acctCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _transferType = 'Own Account';
  _TransferFrom _from = _TransferFrom.savings;
  bool _loading = false;

  @override
  void dispose() {
    _acctCtrl.dispose();
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String get _hintText {
    if (_transferType == 'Own Account') {
      final user = AppState.instance.currentUser;
      if (user == null) return '';
      if (_from == _TransferFrom.savings) {
        return user.checkingAccountNumber.isNotEmpty
            ? 'Checking: ${user.checkingAccountNumber}'
            : 'Your Checking Account Number';
      } else {
        return user.accountNumber.isNotEmpty
            ? 'Savings: ${user.accountNumber}'
            : 'Your Savings Account Number';
      }
    }
    return 'e.g. 1234-5678-9012';
  }

  void _confirmTransfer() {
    final amtStr = _amtCtrl.text.trim();
    final acct = _acctCtrl.text.trim();
    if (amtStr.isEmpty || acct.isEmpty) {
      _showSnack('Please enter an account number and amount.');
      return;
    }
    final amt = double.tryParse(amtStr.replaceAll(',', ''));
    if (amt == null || amt <= 0) {
      _showSnack('Please enter a valid amount.');
      return;
    }

    final user = AppState.instance.currentUser;
    if (user == null) return;

    final fromBalance = _from == _TransferFrom.savings
        ? user.savingsBalance
        : user.checkingBalance;
    final fromLabel = _from == _TransferFrom.savings ? 'Savings' : 'Checking';

    if (fromBalance < amt) {
      _showSnack('Insufficient balance in $fromLabel account.');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Text(
          'Transfer ${DataService.formatCurrency(amt)} from $fromLabel to $acct?',
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
            onPressed: () {
              Navigator.pop(ctx);
              _processFirestoreTransfer(amt, acct, _noteCtrl.text.trim());
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processFirestoreTransfer(
    double amount,
    String targetAcct,
    String note,
  ) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    final error = await DataService.transferFunds(
      senderUsername: user.username,
      targetAccountNumber: targetAcct,
      fromSavings: _from == _TransferFrom.savings,
      amount: amount,
      note: note,
    );
    final refreshedUser = error == null
        ? await DataService.restoreSession()
        : null;
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (error == null) {
        _acctCtrl.clear();
        _amtCtrl.clear();
        _noteCtrl.clear();
      }
    });
    if (error != null) {
      _showSnack(error);
      return;
    }

    if (refreshedUser != null) {
      AppState.instance.currentUser = refreshedUser;
    }
    _showSnack('Transfer successful!');
  }

  // ignore: unused_element
  Future<void> _processTransfer(
    double amount,
    String targetAcct,
    String note,
  ) async {
    setState(() => _loading = true);
    final user = AppState.instance.currentUser!;

    // ── Own Account transfer ──────────────────────────────────────────────────
    if (_transferType == 'Own Account') {
      final String expectedTarget;
      final String fromLabel;
      final String toLabel;

      if (_from == _TransferFrom.savings) {
        expectedTarget = user.checkingAccountNumber;
        fromLabel = 'Savings';
        toLabel = 'Checking';
      } else {
        expectedTarget = user.accountNumber;
        fromLabel = 'Checking';
        toLabel = 'Savings';
      }

      if (targetAcct != expectedTarget) {
        setState(() => _loading = false);
        _showSnack('Invalid account number. Check your Accounts screen.');
        return;
      }

      if (_from == _TransferFrom.savings) {
        user.savingsBalance -= amount;
        user.checkingBalance += amount;
      } else {
        user.checkingBalance -= amount;
        user.savingsBalance += amount;
      }
      await DataService.updateUser(user);
      if (!mounted) return;

      final debitTx = TransactionModel(
        id: DataService.generateId(),
        username: user.username,
        type: 'debit',
        category: 'transfer',
        description: 'Transfer $fromLabel → $toLabel',
        amount: amount,
        date: DataService.formatDate(DateTime.now()),
        note: note,
      );
      final creditTx = TransactionModel(
        id: DataService.generateId(),
        username: user.username,
        type: 'credit',
        category: 'transfer',
        description: 'Transfer $fromLabel → $toLabel',
        amount: amount,
        date: DataService.formatDate(DateTime.now()),
        note: note,
      );
      await DataService.addTransaction(debitTx);
      await DataService.addTransaction(creditTx);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _acctCtrl.clear();
        _amtCtrl.clear();
        _noteCtrl.clear();
      });
      _showSnack('${DataService.formatCurrency(amount)} moved to $toLabel!');
      return;
    }

    // ── Other User / Other Bank ───────────────────────────────────────────────
    final recipient = await DataService.getUserByAccountNumber(targetAcct);
    if (!mounted) return;

    if (recipient == null) {
      setState(() => _loading = false);
      _showSnack('Account number not found. Transfer cancelled.');
      return;
    }
    if (recipient.username == user.username) {
      setState(() => _loading = false);
      _showSnack('Use "Own Account" type to transfer between your accounts.');
      return;
    }

    // Deduct from sender
    if (_from == _TransferFrom.savings) {
      user.savingsBalance -= amount;
    } else {
      user.checkingBalance -= amount;
    }
    await DataService.updateUser(user);
    if (!mounted) return;

    final fromLabel = _from == _TransferFrom.savings ? 'Savings' : 'Checking';

    await DataService.addTransaction(
      TransactionModel(
        id: DataService.generateId(),
        username: user.username,
        type: 'debit',
        category: 'transfer',
        description: 'Transfer to $targetAcct',
        amount: amount,
        date: DataService.formatDate(DateTime.now()),
        note: note,
      ),
    );

    await DataService.addNotification(
      NotificationItem(
        id: DataService.generateId(),
        username: user.username,
        title: 'Transfer Successful',
        message:
            '${DataService.formatCurrency(amount)} sent from $fromLabel to $targetAcct.',
        type: 'success',
        date: DataService.formatDate(DateTime.now()),
      ),
    );

    // Credit the account number the sender selected.
    final recipientAccountType = targetAcct == recipient.checkingAccountNumber
        ? 'Checking'
        : 'Savings';
    if (recipientAccountType == 'Checking') {
      recipient.checkingBalance += amount;
    } else {
      recipient.savingsBalance += amount;
    }
    await DataService.updateUser(recipient);

    await DataService.addTransaction(
      TransactionModel(
        id: '${DataService.generateId()}_rx',
        username: recipient.username,
        type: 'credit',
        category: 'transfer',
        description: 'Received in $recipientAccountType from ${user.fullName}',
        amount: amount,
        date: DataService.formatDate(DateTime.now()),
        note: note,
      ),
    );

    await DataService.addNotification(
      NotificationItem(
        id: '${DataService.generateId()}_rx',
        username: recipient.username,
        title: 'Incoming Transfer',
        message:
            'You received ${DataService.formatCurrency(amount)} from ${user.fullName}.',
        type: 'success',
        date: DataService.formatDate(DateTime.now()),
      ),
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _acctCtrl.clear();
      _amtCtrl.clear();
      _noteCtrl.clear();
    });
    _showSnack('Transfer Successful!');
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Transfer Type ──────────────────────────────────────────────
            const Text(
              'Transfer Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _transferType,
                  isExpanded: true,
                  items: ['Own Account', 'Other User', 'Other Bank']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _transferType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── From Account ────────────────────────────────────────────────
            const Text(
              'From',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _fromOption(
                    label: 'Savings',
                    balance: user.savingsBalance,
                    selected: _from == _TransferFrom.savings,
                    onTap: () => setState(() => _from = _TransferFrom.savings),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _fromOption(
                    label: 'Checking',
                    balance: user.checkingBalance,
                    selected: _from == _TransferFrom.checking,
                    onTap: () => setState(() => _from = _TransferFrom.checking),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Recipient ───────────────────────────────────────────────────
            const Text(
              'Recipient Account',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _acctCtrl,
              decoration: InputDecoration(
                hintText: _hintText,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.account_balance),
              ),
            ),
            const SizedBox(height: 24),

            // ── Amount ──────────────────────────────────────────────────────
            const Text(
              'Amount (₱)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 24),

            // ── Notes ───────────────────────────────────────────────────────
            const Text(
              'Notes (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Payment for lunch',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CONFIRM TRANSFER',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fromOption({
    required String label,
    required double balance,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD32F2F).withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFD32F2F)
                : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFFD32F2F) : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DataService.formatCurrency(balance),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
