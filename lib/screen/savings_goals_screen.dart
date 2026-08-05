import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  List<SavingsGoal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final list = await DataService.getSavingsGoals(user.username);
    if (!mounted) return;
    setState(() {
      _goals = list;
      _loading = false;
    });
  }

  void _showAddGoalDialog() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target Amount (₱)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final target = double.tryParse(targetCtrl.text.trim());
              if (title.isEmpty || target == null || target <= 0) return;
              Navigator.pop(ctx);
              await _addGoal(title, target);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _addGoal(String title, double target) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final goal = SavingsGoal(
      id: DataService.generateId(),
      username: user.username,
      title: title,
      targetAmount: target,
      currentAmount: 0,
      icon: 'savings',
    );
    await DataService.addGoal(goal);
    await _loadGoals();
  }

  void _showContributeDialog(SavingsGoal goal) {
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to "${goal.title}"'),
        content: TextField(
          controller: amtCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (₱)',
            prefixIcon: Icon(Icons.add),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white),
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text.trim());
              if (amt == null || amt <= 0) return;
              Navigator.pop(ctx);
              await _contribute(goal, amt);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _contribute(SavingsGoal goal, double amount) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    if (user.savingsBalance < amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient Savings balance.')));
      return;
    }

    user.savingsBalance -= amount;
    await DataService.updateUser(user);

    goal.currentAmount += amount;
    final allGoals = await DataService.getSavingsGoals(user.username);
    final idx = allGoals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) allGoals[idx] = goal;
    await DataService.saveGoals(allGoals, user.username);

    await _loadGoals();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${DataService.formatCurrency(amount)} added to "${goal.title}"!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('No savings goals yet.',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showAddGoalDialog,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white),
                        icon: const Icon(Icons.add),
                        label: const Text('Create a Goal'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _goals.length,
                  itemBuilder: (ctx, i) => _buildGoalCard(_goals[i]),
                ),
      floatingActionButton: _goals.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddGoalDialog,
              backgroundColor: const Color(0xFFD32F2F),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    final pct = (goal.progress * 100).toInt();
    final isComplete = goal.progress >= 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: isComplete
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.15))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: isComplete
                              ? Colors.green.withValues(alpha: 0.15)
                              : const Color(0xFFD32F2F).withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: Icon(
                          isComplete ? Icons.check_circle : Icons.savings,
                          color: isComplete
                              ? Colors.green
                              : const Color(0xFFD32F2F)),
                    ),
                    const SizedBox(width: 12),
                    Text(goal.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (!isComplete)
                  TextButton.icon(
                    onPressed: () => _showContributeDialog(goal),
                    icon: const Icon(Icons.add,
                        size: 16, color: Color(0xFFD32F2F)),
                    label: const Text('Add',
                        style: TextStyle(color: Color(0xFFD32F2F))),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('Complete! 🎉',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor:
                    Colors.grey.withValues(alpha: 0.15),
                color: isComplete ? Colors.green : const Color(0xFFD32F2F),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DataService.formatCurrency(goal.currentAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$pct% of ${DataService.formatCurrency(goal.targetAmount)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
              ],
            ),
            if (!isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    '${DataService.formatCurrency(goal.remaining)} remaining',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }
}
