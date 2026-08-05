import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final txs = results[0] as List<TransactionModel>;
    final budgets = results[1] as Map<String, double>;
    if (!mounted) return;
    setState(() {
      // Transfers move money between accounts; they are not spending.
      _txs = txs
          .where((t) => t.type == 'debit' && t.category != 'transfer')
          .toList();
      _budgets = budgets;
      _loading = false;
    });
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
          decoration: const InputDecoration(
            hintText: 'Monthly amount (0 clears)',
            prefixText: '₱ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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

  Map<String, double> _getExpensesByCategory() {
    final map = <String, double>{};
    for (var tx in _txs) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final expensesMap = _getExpensesByCategory();
    final double totalExpense = expensesMap.values.fold(
      0,
      (sum, val) => sum + val,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Budget')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Spent',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '₱${totalExpense.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (expensesMap.isEmpty)
              const Center(child: Text('No expenses to analyze yet.'))
            else ...[
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: _buildPieSections(expensesMap),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Category Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...expensesMap.entries.map(
                (e) => _buildCategoryRow(e.key, e.value, totalExpense),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Monthly Budgets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...{'bills', 'shopping', 'food', ..._budgets.keys}.map((category) {
              final spent = expensesMap[category] ?? 0;
              final budget = _budgets[category] ?? 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(category.toUpperCase()),
                subtitle: budget == 0
                    ? const Text('Tap to set a monthly budget')
                    : LinearProgressIndicator(
                        value: (spent / budget).clamp(0.0, 1.0),
                        color: spent > budget
                            ? Colors.red
                            : const Color(0xFFD32F2F),
                      ),
                trailing: Text(
                  budget == 0
                      ? 'Set budget'
                      : '${DataService.formatCurrency(spent)} / ${DataService.formatCurrency(budget)}',
                ),
                onTap: () => _editBudget(category, budget),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    return data.entries.map((e) {
      Color color;
      switch (e.key) {
        case 'bills':
          color = Colors.blue;
          break;
        case 'shopping':
          color = Colors.purple;
          break;
        case 'food':
          color = Colors.orange;
          break;
        default:
          color = Colors.grey;
      }
      return PieChartSectionData(
        color: color,
        value: e.value,
        title:
            '${(e.value / data.values.fold(0, (sum, val) => sum + val) * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryRow(String category, double amount, double total) {
    Color color;
    IconData icon;
    switch (category) {
      case 'bills':
        color = Colors.blue;
        icon = Icons.receipt;
        break;
      case 'shopping':
        color = Colors.purple;
        icon = Icons.shopping_bag;
        break;
      case 'food':
        color = Colors.orange;
        icon = Icons.restaurant;
        break;
      default:
        color = Colors.grey;
        icon = Icons.money;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total > 0 ? amount / total : 0,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '₱${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
