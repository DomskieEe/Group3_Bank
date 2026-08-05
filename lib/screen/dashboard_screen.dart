import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../models/transaction_model.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import 'accounts_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TransactionModel> _recentTx = [];
  int _unreadNotifs = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    final txs = await DataService.getTransactions(user.username);
    final unread = await DataService.getUnreadCount(user.username);

    if (!mounted) return;
    setState(() {
      _recentTx = txs.take(5).toList();
      _unreadNotifs = unread;
      _loading = false;
    });
  }

  Future<void> _showCashInDialog() async {
    final amtCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.add_card, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text('Cash In / Deposit'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the amount to deposit into your Savings account.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (₱)',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
                ),
              ),
            ),
          ],
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
              final amt = double.tryParse(amtCtrl.text.trim());
              if (amt == null || amt <= 0) return;
              Navigator.pop(ctx, amt);
            },
            child: const Text('Deposit'),
          ),
        ],
      ),
    ).then((amount) async {
      if (amount == null) return;
      await _processCashIn(amount as double);
    });
  }

  Future<void> _processCashIn(double amount) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    user.savingsBalance += amount;
    await DataService.updateUser(user);

    final tx = TransactionModel(
      id: DataService.generateId(),
      username: user.username,
      type: 'credit',
      category: 'deposit',
      description: 'Cash In / Deposit',
      amount: amount,
      date: DataService.formatDate(DateTime.now()),
    );
    await DataService.addTransaction(tx);

    final notif = NotificationItem(
      id: DataService.generateId(),
      username: user.username,
      title: 'Deposit Successful',
      message:
      '${DataService.formatCurrency(amount)} has been deposited to your Savings account.',
      type: 'success',
      date: DataService.formatDate(DateTime.now()),
    );
    await DataService.addNotification(notif);

    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Successfully deposited ${DataService.formatCurrency(amount)}!',
        ),
      ),
    );
  }

  String _buildInsight() {
    if (_recentTx.isEmpty) {
      return 'Start transacting to get personalized financial insights!';
    }
    final debits = _recentTx
        .where((t) => t.type == 'debit' && t.category != 'transfer')
        .toList();
    if (debits.isEmpty) return 'Great job! No expenses recorded recently.';

    final Map<String, double> catTotals = {};
    for (final tx in debits) {
      catTotals[tx.category] = (catTotals[tx.category] ?? 0) + tx.amount;
    }
    final topCat = catTotals.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
    );
    final totalSpent = debits.fold(0.0, (sum, t) => sum + t.amount);
    return '📊 You\'ve spent ${DataService.formatCurrency(totalSpent)} recently. '
        'Your biggest category is ${topCat.key.toUpperCase()} at '
        '${DataService.formatCurrency(topCat.value)}. '
        'Consider reviewing your ${topCat.key} budget!';
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.currentUser;
    if (user == null || _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFD32F2F),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFD32F2F),
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_unreadNotifs > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_unreadNotifs',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Balance Card ───────────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountsScreen()),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD32F2F), Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white70,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Total Balance',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right,
                                color: Colors.white54, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DataService.formatCurrency(user.totalBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniBalance(
                              'Savings',
                              user.savingsBalance,
                              Icons.savings_outlined,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white24,
                            ),
                            _buildMiniBalance(
                              'Checking',
                              user.checkingBalance,
                              Icons.credit_card_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showCashInDialog,
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Cash In',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Recent Transactions Header ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Color(0xFFD32F2F),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionHistoryScreen(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Color(0xFFD32F2F),
                      ),
                      label: const Text(
                        'See All',
                        style: TextStyle(color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_recentTx.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No recent transactions',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._recentTx.map((tx) => _buildTxTile(tx)),

                const SizedBox(height: 32),

                // ─── AI Insights Header ─────────────────────────────────────
                const Row(
                  children: [
                    Icon(
                      Icons.auto_graph,
                      color: Color(0xFFD32F2F),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Insights',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _buildInsight(),
                          style: TextStyle(
                            color:
                            Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBalance(String label, double amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DataService.formatCurrency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
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
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          tx.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(tx.date, style: const TextStyle(fontSize: 12)),
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