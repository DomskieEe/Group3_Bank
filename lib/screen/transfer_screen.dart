import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

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

    final fromLabel = _from == _TransferFrom.savings ? 'Savings' : 'Checking';

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
