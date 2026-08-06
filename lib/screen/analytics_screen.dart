import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<TransactionModel> _txs = [];
  Map<String, double> _budgets = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    final results = await Future.wait([
      DataService.getTransactions(user.username),
      DataService.getBudgets(user.username),
    ]);
    if (!mounted) return;
    setState(() {
      _txs = results[0] as List<TransactionModel>;
      _budgets = results[1] as Map<String, double>;
      _loading = false;
    });
  }

  bool _isInCurrentMonth(TransactionModel tx) {
    final date = DateTime.tryParse(tx.date);
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  double _totalWhere(bool Function(TransactionModel transaction) test) =>
      _txs.where((tx) => _isInCurrentMonth(tx) && test(tx)).fold(0.0, (sum, transaction) => sum + transaction.amount);

  Map<String, double> _getExpensesByCategory() {
    final map = <String, double>{};
    for (final tx in _txs.where(_isInCurrentMonth)) {
      if (tx.type != 'debit' || tx.category == 'transfer') continue;
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    return map;
  }

  double _spendingBetween(DateTime start, DateTime end) => _txs.where((tx) {
    final date = DateTime.tryParse(tx.date);
    return date != null && !date.isBefore(start) && date.isBefore(end) && tx.type == 'debit' && tx.category != 'transfer';
  }).fold(0.0, (sum, tx) => sum + tx.amount);

  int _healthScore({required double spent, required double income}) {
    final user = AppState.instance.currentUser;
    var score = 65;
    if (income > spent) score += 15;
    if (user != null && user.savingsBalance > user.checkingBalance) score += 10;
    if (_budgets.values.where((value) => value > 0).isNotEmpty) score += 5;
    if (income > 0 && spent > income) score -= 20;
    return score.clamp(0, 100);
  }

  Future<void> _editBudget(String category, double current) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${category.toUpperCase()} budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Monthly amount (0 clears)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              final user = AppState.instance.currentUser;
              if (amount == null || amount < 0 || user == null) return;
              await DataService.setBudget(user.username, category, amount);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _loadData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final expenses = _getExpensesByCategory();
    final spent = expenses.values.fold(0.0, (sum, amount) => sum + amount);
    final income = _totalWhere((tx) => tx.type == 'credit' && tx.category != 'transfer');
    final received = _totalWhere((tx) => tx.type == 'credit' && tx.category == 'transfer');
    final transferred = _totalWhere((tx) => tx.type == 'debit' && tx.category == 'transfer');
    final now = DateTime.now();
    final thisWeek = _spendingBetween(now.subtract(const Duration(days: 7)), now.add(const Duration(days: 1)));
    final lastWeek = _spendingBetween(now.subtract(const Duration(days: 14)), now.subtract(const Duration(days: 7)));
    final score = _healthScore(spent: spent, income: income);
    final budgetAlerts = _budgets.entries.where((entry) => entry.value > 0 && (expenses[entry.key] ?? 0) / entry.value >= .8).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Budget')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Month', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard('Spent', spent, Colors.red),
                _summaryCard('Income', income, Colors.green),
                _summaryCard('Received', received, Colors.teal),
                _summaryCard('Transferred', transferred, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: const Color(0xFFD32F2F).withValues(alpha: .08),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFD32F2F), child: Text('$score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                title: const Text('Financial health score', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(score >= 80 ? 'Great balance between spending and saving.' : score >= 60 ? 'Good progress—keep an eye on your budget.' : 'Focus on reducing expenses and building savings.'),
              ),
            ),
            const SizedBox(height: 12),
            Text('Weekly spending: ${DataService.formatCurrency(thisWeek)}${lastWeek > 0 ? ' (${((thisWeek - lastWeek) / lastWeek * 100).abs().toStringAsFixed(0)}% ${thisWeek > lastWeek ? 'higher' : 'lower'} than last week)' : ''}'),
            if (budgetAlerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Budget alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...budgetAlerts.map((entry) {
                final used = expenses[entry.key] ?? 0;
                final percentage = (used / entry.value * 100).round();
                return ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  title: Text('${entry.key.toUpperCase()} is at $percentage%'),
                  subtitle: Text('${DataService.formatCurrency(used)} of ${DataService.formatCurrency(entry.value)}'),
                );
              }),
            ],
            const SizedBox(height: 16),
            const Text('Personalized tip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(budgetAlerts.isNotEmpty
                    ? 'Try pausing non-essential ${budgetAlerts.first.key} purchases until your next budget cycle.'
                    : lastWeek > 0 && thisWeek > lastWeek
                        ? 'Your spending is higher than last week. Review your recent purchases before the month ends.'
                        : income > spent
                            ? 'You are spending less than you earn this month. Consider moving part of the difference to a savings goal.'
                            : 'Set budgets for your regular categories to receive tailored alerts.'),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Spending by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (expenses.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No spending to analyze this month.'),
              ))
            else ...[
              SizedBox(
                height: 250,
                child: PieChart(PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: _buildPieSections(expenses),
                )),
              ),
              const SizedBox(height: 24),
              ...expenses.entries.map((entry) => _buildCategoryRow(entry.key, entry.value, spent)),
            ],
            const SizedBox(height: 24),
            const Text('Monthly Budgets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...{'bills', 'shopping', 'food', ..._budgets.keys}.map((category) {
              final categorySpent = expenses[category] ?? 0;
              final budget = _budgets[category] ?? 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(category.toUpperCase()),
                subtitle: budget == 0
                    ? const Text('Tap to set a monthly budget')
                    : LinearProgressIndicator(
                        value: (categorySpent / budget).clamp(0.0, 1.0),
                        color: categorySpent > budget ? Colors.red : const Color(0xFFD32F2F),
                      ),
                trailing: Text(budget == 0
                    ? 'Set budget'
                    : '${DataService.formatCurrency(categorySpent)} / ${DataService.formatCurrency(budget)}'),
                onTap: () => _editBudget(category, budget),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, double amount, Color color) => SizedBox(
        width: 155,
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text(DataService.formatCurrency(amount),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, amount) => sum + amount);
    return data.entries.map((entry) {
      final color = _categoryColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${(entry.value / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildCategoryRow(String category, double amount, double total) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _categoryColor(category).withValues(alpha: 0.1),
              child: Icon(_categoryIcon(category), color: _categoryColor(category)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: amount / total, color: _categoryColor(category)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(DataService.formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Color _categoryColor(String category) => switch (category) {
        'bills' => Colors.blue,
        'shopping' => Colors.purple,
        'food' => Colors.orange,
        _ => Colors.grey,
      };

  IconData _categoryIcon(String category) => switch (category) {
        'bills' => Icons.receipt,
        'shopping' => Icons.shopping_bag,
        'food' => Icons.restaurant,
        _ => Icons.attach_money,
      };
}
