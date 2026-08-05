import 'package:flutter/material.dart';
import '../models/bank_card.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<BankCard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final list = await DataService.getCards(user.username);
    if (!mounted) return;
    setState(() {
      _cards = list;
      _loading = false;
    });
  }

  Future<void> _toggleFreeze(BankCard card) async {
    card.isFrozen = !card.isFrozen;
    await DataService.updateCard(card);
    await _loadCards();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          card.isFrozen ? 'Card frozen successfully' : 'Card unfrozen',
        ),
      ),
    );
  }

  Future<void> _showAddCardDialog() async {
    String? selectedType = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose Card Type'),
        children: [
          _dialogOption(
            ctx,
            'debit',
            Icons.credit_card,
            'Debit Card',
            'Linked to your Savings account',
            const Color(0xFFD32F2F),
          ),
          _dialogOption(
            ctx,
            'credit',
            Icons.credit_score,
            'Credit Card',
            'Spend now, pay later',
            Colors.deepPurple,
          ),
          _dialogOption(
            ctx,
            'virtual',
            Icons.phone_android,
            'Virtual Card',
            'For online purchases only',
            Colors.teal,
          ),
        ],
      ),
    );

    if (selectedType == null || !mounted) return;
    await _addCard(selectedType);
  }

  Widget _dialogOption(
    BuildContext ctx,
    String type,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, type),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCard(String cardType) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final last4 = ts.substring(ts.length - 4);

    final newCard = BankCard(
      id: DataService.generateId(),
      username: user.username,
      cardNumber: '**** **** **** $last4',
      cardHolder: user.fullName.toUpperCase(),
      expiry: '12/29',
      cardType: cardType,
      spendingLimit: cardType == 'credit' ? 100000.0 : 25000.0,
    );

    await DataService.addCard(newCard);
    await _loadCards();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${cardType.capitalize()} card added!')),
    );
  }

  void _showCardHistory(BankCard card) async {
    final user = AppState.instance.currentUser;
    if (user == null) return;

    final allTx = await DataService.getTransactions(user.username);
    // Show recent transactions as card history (in a real app, txs would be linked to a card ID)
    final recent = allTx.take(10).toList();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Text(
                    'Card History — ${card.cardNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: recent.isEmpty
                  ? const Center(child: Text('No transactions yet.'))
                  : ListView.builder(
                      controller: scroll,
                      itemCount: recent.length,
                      itemBuilder: (_, i) {
                        final tx = recent[i];
                        final isCredit = tx.type == 'credit';
                        return ListTile(
                          title: Text(
                            tx.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            tx.date,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '${isCredit ? '+' : '-'} ${DataService.formatCurrency(tx.amount)}',
                            style: TextStyle(
                              color: isCredit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpendingLimit(BankCard card) {
    double currentLimit = card.spendingLimit;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Spending Limit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DataService.formatCurrency(currentLimit),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentLimit,
                min: 5000,
                max: 200000,
                divisions: 39,
                activeColor: const Color(0xFFD32F2F),
                label: DataService.formatCurrency(currentLimit),
                onChanged: (val) => setModalState(() => currentLimit = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '₱5,000',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '₱200,000',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
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
              onPressed: () async {
                card.spendingLimit = currentLimit;
                await DataService.updateCard(card);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                await _loadCards();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Limit updated to ${DataService.formatCurrency(currentLimit)}',
                    ),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Cards')),
      body: _cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No cards found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddCardDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Apply for a Card'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _cards.length,
              itemBuilder: (ctx, i) => _buildCardItem(_cards[i]),
            ),
      floatingActionButton: _cards.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddCardDialog,
              backgroundColor: const Color(0xFFD32F2F),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCardItem(BankCard card) {
    Color cardColor;
    switch (card.cardType) {
      case 'credit':
        cardColor = Colors.deepPurple;
        break;
      case 'virtual':
        cardColor = Colors.teal;
        break;
      default:
        cardColor = const Color(0xFFD32F2F);
    }
    if (card.isFrozen) cardColor = Colors.grey.shade700;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cardColor.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.cardType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (card.isFrozen)
                    const Row(
                      children: [
                        Icon(Icons.ac_unit, color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'FROZEN',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.contactless, color: Colors.white70),
                ],
              ),
              Text(
                card.cardNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CARD HOLDER',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      Text(
                        card.cardHolder,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EXPIRES',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      Text(
                        card.expiry,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIMIT',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      Text(
                        DataService.formatCurrency(card.spendingLimit),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCardAction(
              icon: card.isFrozen ? Icons.ac_unit : Icons.lock_outline,
              label: card.isFrozen ? 'Unfreeze' : 'Freeze',
              onTap: () => _toggleFreeze(card),
            ),
            _buildCardAction(
              icon: Icons.tune,
              label: 'Limits',
              onTap: () => _showSpendingLimit(card),
            ),
            _buildCardAction(
              icon: Icons.history,
              label: 'History',
              onTap: () => _showCardHistory(card),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCardAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: const Color(0xFFD32F2F)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
