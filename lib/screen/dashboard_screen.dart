import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/notification_item.dart';
import '../models/transaction_model.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import 'accounts_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'transaction_history_screen.dart';
import 'brand_detail_screen.dart';
import 'youtube_play_screen.dart';

// Global audio player instance helper
final AudioPlayer _globalAudioPlayer = AudioPlayer();

void _playSwooshSound() async {
  try {
    await _globalAudioPlayer.stop();
    await _globalAudioPlayer.play(AssetSource('swoosh.mp3'));
  } catch (e) {
    debugPrint('Error playing sound: $e');
  }
}

// ─── Sub-Screens for Tabs ───────────────────────────────────────────────────

class DiscountScreen extends StatelessWidget {
  const DiscountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brands = [
      {'name': 'Puma', 'desc': 'Up to 50% off on sportswear', 'asset': 'assets/puma.png'},
      {'name': 'Adidas', 'desc': 'Exclusive voucher codes available', 'asset': 'assets/adidas.jpg'},
      {'name': 'McDo', 'desc': 'Buy 1 Take 1 on select meals', 'asset': 'assets/mcdo.jpg'},
      {'name': 'Jollibee', 'desc': 'Free delivery + discount bundles', 'asset': 'assets/jollibee.jpg'},
      {'name': 'Greenwich', 'desc': 'Slash ₱100 off on large pizzas', 'asset': 'assets/greenwich.png'},
      {'name': 'PC Express', 'desc': 'Discount on PC parts & builds', 'asset': 'assets/pcexpress.png'},
      {'name': 'Easy PC', 'desc': 'Affordable tech accessories sale', 'asset': 'assets/easypc.jpeg'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage(brand['asset'] as String),
            ),
            title: Text(brand['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(brand['desc'] as String),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _playSwooshSound();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrandDetailScreen(
                    brandName: brand['name'] as String,
                    description: brand['desc'] as String,
                    assetPath: brand['asset'] as String,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class YouTubeTabScreen extends StatelessWidget {
  const YouTubeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🔥 Trending on YouTube',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.play_circle_fill, color: Colors.red, size: 40),
          title: const Text('Top 10 Flutter Development Tips'),
          subtitle: const Text('Tech Insights • 1.2M views'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const YouTubePlayerScreen(
                  videoTitle: 'Top 10 Flutter Development Tips',
                  channelName: 'Tech Insights',
                  views: '1.2M views',
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.play_circle_fill, color: Colors.red, size: 40),
          title: const Text('Latest Global News & Updates'),
          subtitle: const Text('World News 24/7 • 850K views'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const YouTubePlayerScreen(
                  videoTitle: 'Latest Global News & Updates',
                  channelName: 'World News 24/7',
                  views: '850K views',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TikTokTabScreen extends StatelessWidget {
  const TikTokTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('⚡ Viral TikTok Videos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ListTile(
          leading: Icon(Icons.video_collection, color: Colors.black, size: 40),
          title: Text('#MoneySavingTips - Quick Budget Hack'),
          subtitle: Text('@financeguru • 3.4M likes'),
        ),
      ],
    );
  }
}

class SpotifyTabScreen extends StatelessWidget {
  const SpotifyTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('🎶 Trending Musics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ListTile(
          leading: Icon(Icons.music_note, color: Colors.green, size: 40),
          title: Text('Global Top 50 - Hits Playlist'),
          subtitle: Text('Various Artists • 25M streams'),
        ),
      ],
    );
  }
}

class TravelTabScreen extends StatelessWidget {
  const TravelTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('✈️ Ticket Discounts & Promos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ListTile(
          leading: Icon(Icons.flight, color: Colors.orange, size: 40),
          title: Text('Cebu Pacific Seat Sale'),
          subtitle: Text('Up to 30% off on domestic flights'),
        ),
      ],
    );
  }
}

class GamesTabScreen extends StatelessWidget {
  const GamesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('🎮 Entertainment & Gaming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ListTile(
          leading: Icon(Icons.sports_esports, color: Colors.purple, size: 40),
          title: Text('Top Esports Tournaments Live'),
          subtitle: Text('Stream matches and win rewards'),
        ),
      ],
    );
  }
}

// ─── Chat Support Modal Sheet Widget ────────────────────────────────────────

class SupportChatModal extends StatefulWidget {
  const SupportChatModal({super.key});

  @override
  State<SupportChatModal> createState() => _SupportChatModalState();
}

class _SupportChatModalState extends State<SupportChatModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _floatAnimation;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text': 'Hello! I am your virtual assistant. How can I help you with your app or transactions today?'
    }
  ];

  @override
  void initState() {
    super.initState();
    // Setup animation for the floating robot effect
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
    });

    // Simple simulated bot response logic based on user keywords
    Future.delayed(const Duration(milliseconds: 600), () {
      String botReply = 'I can help you with checking your balance, cash-ins, and navigating discounts!';

      final lowerText = text.toLowerCase();
      if (lowerText.contains('balance') || lowerText.contains('money')) {
        botReply = 'You can check your total, savings, and checking balances directly from the top summary card on your dashboard.';
      } else if (lowerText.contains('cash in') || lowerText.contains('deposit')) {
        botReply = 'To cash in, simply tap the "Cash In" button inside your total balance card.';
      } else if (lowerText.contains('discount') || lowerText.contains('promo')) {
        botReply = 'Check out the "Shop & Entertainment" tab section on your dashboard to see brand vouchers and promos!';
      }

      if (mounted) {
        setState(() {
          _messages.add({'sender': 'bot', 'text': botReply});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Chat Header with Animated Floating Robot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Animated Robot Icon
                AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: child,
                    );
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.smart_toy, color: Color(0xFFD32F2F)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Support Bot',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Online • Ready to help',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Chat Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      // Bot bubble is black, user bubble remains red
                      color: isUser ? const Color(0xFFD32F2F) : Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        // Bot text is white, user text remains black
                        color: isUser ? Colors.grey: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask something about the app...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFF000000),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFD32F2F),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _handleSubmitted(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Screen ───────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TransactionModel> _recentTx = [];
  int _unreadNotifs = 0;
  bool _loading = true;
  StreamSubscription? _profileSubscription;
  StreamSubscription? _transactionSubscription;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _playSwooshSound();
      }
    });
    _loadData();
    _startLiveUpdates();
    AppState.instance.sensitiveDataVisible.addListener(_refreshPrivacy);
  }

  void _refreshPrivacy() {
    if (mounted) setState(() {});
  }

  void _startLiveUpdates() {
    _profileSubscription = DataService.watchCurrentUser().listen((user) {
      if (!mounted || user == null) return;
      setState(() => AppState.instance.currentUser = user);
    });
    _transactionSubscription = DataService.watchCurrentTransactions().listen((txs) {
      if (!mounted) return;
      setState(() {
        _recentTx = txs.take(5).toList();
        _loading = false;
      });
    });
    _notificationSubscription =
        DataService.watchCurrentNotifications().listen((notifications) {
      if (!mounted) return;
      setState(() => _unreadNotifs = notifications.where((n) => !n.isRead).length);
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _transactionSubscription?.cancel();
    _notificationSubscription?.cancel();
    _tabController.dispose();
    AppState.instance.sensitiveDataVisible.removeListener(_refreshPrivacy);
    super.dispose();
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      message: '${DataService.formatCurrency(amount)} has been deposited to your Savings account.',
      type: 'success',
      date: DataService.formatDate(DateTime.now()),
    );
    await DataService.addNotification(notif);

    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully deposited ${DataService.formatCurrency(amount)}!'),
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

  void _openChatSupport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SupportChatModal(),
    );
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
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white70,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Total Balance',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () async {
                                final next = !AppState.instance.sensitiveDataVisible.value;
                                AppState.instance.sensitiveDataVisible.value = next;
                                await DataService.setSensitiveDataVisible(next);
                              },
                              icon: Icon(
                                AppState.instance.sensitiveDataVisible.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppState.instance.sensitiveDataVisible.value
                              ? DataService.formatCurrency(user.totalBalance)
                              : '₱ ••••••',
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
                            _buildMiniBalance('Savings', user.savingsBalance, Icons.savings_outlined),
                            Container(width: 1, height: 30, color: Colors.white24),
                            _buildMiniBalance('Checking', user.checkingBalance, Icons.credit_card_outlined),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showCashInDialog,
                            icon: const Icon(Icons.add_circle, color: Colors.white),
                            label: const Text('Cash In', style: TextStyle(color: Colors.white)),
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

                // ─── Shop & Content Tabs Section ────────────────────────────
                const Text(
                  'Shop & Entertainment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: const Color(0xFFD32F2F),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFFD32F2F),
                        tabs: const [
                          Tab(text: 'Discount'),
                          Tab(text: 'YouTube'),
                          Tab(text: 'TikTok'),
                          Tab(text: 'Spotify'),
                          Tab(text: 'Travel'),
                          Tab(text: 'Games'),
                        ],
                      ),
                      SizedBox(
                        height: 250,
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            DiscountScreen(),
                            YouTubeTabScreen(),
                            TikTokTabScreen(),
                            SpotifyTabScreen(),
                            TravelTabScreen(),
                            GamesTabScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Recent Transactions Header ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history, color: Color(0xFFD32F2F), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Recent Transactions',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      icon: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFD32F2F)),
                      label: const Text('See All', style: TextStyle(color: Color(0xFFD32F2F))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_recentTx.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No recent transactions', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ..._recentTx.map((tx) => _buildTxTile(tx)),

                const SizedBox(height: 32),

                // ─── AI Insights Header ─────────────────────────────────────
                const Row(
                  children: [
                    Icon(Icons.auto_graph, color: Color(0xFFD32F2F), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'AI Insights',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.orange, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _buildInsight(),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
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
      // Floating Robot Chat Support Icon (like BIR app style assistant button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatSupport,
        backgroundColor: const Color(0xFFD32F2F),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          'Ask Bot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppState.instance.sensitiveDataVisible.value
              ? DataService.formatCurrency(amount)
              : '••••••',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
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
