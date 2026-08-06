import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../models/transaction_model.dart';
import '../models/notification_item.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

// ─── Icon catalogue ──────────────────────────────────────────────────────────
// Each entry maps a string key (stored in SavingsGoal.icon) to a Flutter
// IconData. Keeping it here means the model stays a plain-data class and we
// never need to import flutter/material.dart inside the model layer.
const Map<String, IconData> kGoalIcons = {
  'savings':     Icons.savings,
  'shield':      Icons.shield,
  'flight':      Icons.flight,
  'laptop_mac':  Icons.laptop_mac,
  'home':        Icons.home,
  'directions_car': Icons.directions_car,
  'school':      Icons.school,
  'favorite':    Icons.favorite,
  'beach_access': Icons.beach_access,
  'card_giftcard': Icons.card_giftcard,
  'phone_iphone': Icons.phone_iphone,
  'fitness_center': Icons.fitness_center,
  'restaurant':  Icons.restaurant,
  'local_hospital': Icons.local_hospital,
  'attach_money': Icons.attach_money,
};

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  List<SavingsGoal> _goals = [];
  bool _loading = true;

  // Primary brand colour used throughout the app.
  static const _red = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // ─── Data loading ────────────────────────────────────────────────────────

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

  // ─── Add goal dialog ─────────────────────────────────────────────────────

  void _showAddGoalDialog() {
    final titleCtrl  = TextEditingController();
    final targetCtrl = TextEditingController();
    // Default icon selection – mutable inside the dialog via StatefulBuilder.
    String selectedIcon = 'savings';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal name field
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Target amount field
                TextField(
                  controller: targetCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (₱)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Icon picker label
                const Text(
                  'Choose an icon',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 10),

                // Icon grid – 5 columns of tappable circles
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kGoalIcons.entries.map((entry) {
                    final isSelected = entry.key == selectedIcon;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedIcon = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _red.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? _red : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          size: 22,
                          color: isSelected ? _red : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _red, foregroundColor: Colors.white),
              onPressed: () async {
                final title  = titleCtrl.text.trim();
                final target = double.tryParse(targetCtrl.text.trim());
                // Validate before closing the dialog
                if (title.isEmpty || target == null || target <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text(
                          'Please enter a valid goal name and target amount.')));
                  return;
                }
                Navigator.pop(ctx);
                await _addGoal(title, target, selectedIcon);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGoal(
      String title, double target, String iconKey) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final goal = SavingsGoal(
      id: DataService.generateId(),
      username: user.username,
      title: title,
      targetAmount: target,
      currentAmount: 0,
      icon: iconKey,
    );
    await DataService.addGoal(goal);
    await _loadGoals();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal "${goal.title}" created!')));
  }

  // ─── Contribute / deposit dialog ─────────────────────────────────────────

  void _showContributeDialog(SavingsGoal goal) {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    final amtCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to "${goal.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show the user how much savings balance they can draw from.
            // This makes the validation below transparent to the user.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: _red, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Available Savings: '
                    '${DataService.formatCurrency(user.savingsBalance)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount to deposit (₱)',
                prefixIcon: Icon(Icons.add),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _red, width: 2)),
              ),
            ),
            const SizedBox(height: 8),
            // Show how much is still needed for context.
            Text(
              '${DataService.formatCurrency(goal.remaining)} remaining to reach target',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text.trim());
              if (amt == null || amt <= 0) return;
              Navigator.pop(ctx);
              await _contribute(goal, amt);
            },
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
  }

  Future<void> _contribute(SavingsGoal goal, double amount) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    // ── Validation: prevent depositing more than the available savings balance
    if (user.savingsBalance < amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Insufficient Savings balance. Top up your account first.')));
      return;
    }

    // ── Validation: cap deposit at the remaining amount so we never overshoot
    final effectiveAmount = amount.clamp(0.0, goal.remaining);
    if (effectiveAmount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This goal is already complete!')));
      return;
    }

    // ── Atomically deduct from the user's savings balance and update the goal.
    // We update the local in-memory object first so the UI stays consistent
    // even before Firestore confirms the write.
    user.savingsBalance -= effectiveAmount;
    await DataService.updateUser(user);
    // Keep the singleton in sync so other screens (dashboard, accounts) reflect
    // the new balance immediately without a full reload.
    AppState.instance.currentUser = user;

    goal.currentAmount += effectiveAmount;
    await DataService.updateGoal(goal);

    // ── Record a debit transaction so the history and analytics screens
    // correctly reflect this internal fund movement.
    final tx = TransactionModel(
      id: DataService.generateId(),
      username: user.username,
      type: 'debit',
      category: 'transfer',
      description: 'Savings deposit → ${goal.title}',
      amount: effectiveAmount,
      date: DataService.formatDate(DateTime.now()),
      note: 'Savings goal contribution',
    );
    await DataService.addTransaction(tx);

    // ── Push a notification so the user gets confirmation in the inbox.
    final notif = NotificationItem(
      id: DataService.generateId(),
      username: user.username,
      title: 'Goal Deposit Successful',
      message:
          '${DataService.formatCurrency(effectiveAmount)} was added to '
          '"${goal.title}". '
          '${goal.progress >= 1.0 ? "🎉 Goal complete!" : "${DataService.formatCurrency(goal.remaining)} remaining."}',
      type: 'success',
      date: DataService.formatDate(DateTime.now()),
    );
    await DataService.addNotification(notif);

    await _loadGoals();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${DataService.formatCurrency(effectiveAmount)} added to '
            '"${goal.title}"!')));
  }

  // ─── Delete goal ─────────────────────────────────────────────────────────

  Future<void> _confirmDeleteGoal(SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
            'Delete "${goal.title}"? '
            'Any saved amount will not be refunded automatically.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DataService.deleteGoal(goal.id, goal.username);
    await _loadGoals();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${goal.title}" deleted.')));
  }

  // ─── Savings automation dialog ───────────────────────────────────────────

  Future<void> _configureAutomation() async {
    if (_goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a savings goal first.')));
      return;
    }
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final current = await DataService.getSavingsAutomation(user.username);
    var enabled  = current['enabled'] == true;
    var goalId   = (current['goalId'] as String?) ?? _goals.first.id;
    var mode     = (current['mode']   as String?) ?? 'roundUp';
    final fixedCtrl = TextEditingController(
        text: current['amount']?.toString() ?? '10');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Savings automation'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SwitchListTile(
              title: const Text('Enable auto-save'),
              value: enabled,
              onChanged: (v) => setDialogState(() => enabled = v),
            ),
            DropdownButtonFormField<String>(
              initialValue: goalId,
              items: _goals
                  .map((g) =>
                      DropdownMenuItem(value: g.id, child: Text(g.title)))
                  .toList(),
              onChanged: (v) => setDialogState(() => goalId = v ?? goalId),
              decoration: const InputDecoration(labelText: 'Savings goal'),
            ),
            DropdownButtonFormField<String>(
              initialValue: mode,
              items: const [
                DropdownMenuItem(
                    value: 'roundUp',
                    child: Text('Round up each expense')),
                DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Fixed amount per expense')),
              ],
              onChanged: (v) => setDialogState(() => mode = v ?? mode),
              decoration: const InputDecoration(labelText: 'Rule'),
            ),
            if (mode == 'fixed')
              TextField(
                controller: fixedCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Amount per expense (₱)'),
              ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _red, foregroundColor: Colors.white),
              onPressed: () async {
                await DataService.setSavingsAutomation(user.username, {
                  'enabled': enabled,
                  'goalId': goalId,
                  'mode': mode,
                  'amount': double.tryParse(fixedCtrl.text) ?? 0,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    fixedCtrl.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            onPressed: _configureAutomation,
            icon: const Icon(Icons.auto_graph),
            tooltip: 'Savings automation',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  color: _red,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: _goals.length,
                    itemBuilder: (ctx, i) => _buildGoalCard(_goals[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: _red,
        tooltip: 'New savings goal',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings,
              size: 72, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          const Text('No savings goals yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Create a goal and start building\ntowards something meaningful.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _showAddGoalDialog,
            style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: Colors.white),
            icon: const Icon(Icons.add),
            label: const Text('Create a Goal'),
          ),
        ],
      ),
    );
  }

  // ─── Goal card ─────────────────────────────────────────────────────────

  Widget _buildGoalCard(SavingsGoal goal) {
    final pct        = (goal.progress * 100).toInt();
    final isComplete = goal.progress >= 1.0;
    // Resolve the stored icon string to an IconData, fall back to savings icon.
    final iconData   = kGoalIcons[goal.icon] ?? Icons.savings;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header: icon + title + action buttons ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal icon circle
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? Colors.green.withValues(alpha: 0.15)
                        : _red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isComplete ? Icons.check_circle : iconData,
                    color: isComplete ? Colors.green : _red,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + percentage label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isComplete
                            ? 'Goal reached 🎉'
                            : '$pct% complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: isComplete ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                if (!isComplete)
                  TextButton.icon(
                    onPressed: () => _showContributeDialog(goal),
                    icon: const Icon(Icons.add, size: 16, color: _red),
                    label: const Text('Deposit',
                        style: TextStyle(color: _red)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Complete!',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                // Delete button (always visible)
                IconButton(
                  onPressed: () => _confirmDeleteGoal(goal),
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.grey),
                  tooltip: 'Delete goal',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Progress bar ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                color: isComplete ? Colors.green : _red,
                minHeight: 10,
              ),
            ),

            const SizedBox(height: 12),

            // ── Amount labels ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DataService.formatCurrency(goal.currentAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'of ${DataService.formatCurrency(goal.targetAmount)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),

            // ── Remaining amount (only while goal is active) ──────────────
            if (!isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${DataService.formatCurrency(goal.remaining)} remaining',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
