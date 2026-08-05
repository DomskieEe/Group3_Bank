import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/transaction_model.dart';
import '../models/bank_card.dart';
import '../models/savings_goal.dart';
import '../models/notification_item.dart';

class DataService {
  static const String _usersKey = 'ds_users';
  static const String _transactionsKey = 'ds_transactions';
  static const String _cardsKey = 'ds_cards';
  static const String _goalsKey = 'ds_savings_goals';
  static const String _notificationsKey = 'ds_notifications';
  static const String _seededKey = 'ds_is_seeded_v3';
  static const String _sessionUsernameKey = 'ds_session_username';
  static const String _budgetsKey = 'ds_budgets';
  static const String _billRemindersKey = 'ds_bill_reminders';

  // ─── INIT ───────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool(_seededKey) ?? false;
    if (!isSeeded) {
      await _seedData(prefs);
      await prefs.setBool(_seededKey, true);
    }
  }

  static Future<void> _seedData(SharedPreferences prefs) async {
    final now = DateTime.now();

    // USERS
    final users = [
      AppUser(
        id: 1,
        name: 'Admin',
        surname: 'User',
        middleName: 'A',
        birthday: '1990-01-01',
        username: 'admin',
        password: 'Admin123',
        email: 'admin@snapwallet.ph',
        phone: '09171234567',
        accountNumber: '1234-5678-9012',
        checkingAccountNumber: '2109-8765-4321',
        accountType: 'checking',
        accountStatus: 'active',
        savingsBalance: 50000.0,
        checkingBalance: 25000.0,
      ),
      AppUser(
        id: 2,
        name: 'Dominic',
        surname: 'Santos',
        middleName: 'R',
        birthday: '1998-05-14',
        username: 'dominic',
        password: 'pass123',
        email: 'dominic@email.com',
        phone: '09981234567',
        accountNumber: '9876-5432-1098',
        checkingAccountNumber: '8901-2345-6789',
        accountType: 'savings',
        accountStatus: 'active',
        savingsBalance: 45750.0,
        checkingBalance: 12500.0,
      ),
    ];
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );

    // TRANSACTIONS
    String fd(int daysAgo) =>
        now.subtract(Duration(days: daysAgo)).toString().substring(0, 16);
    final transactions = [
      TransactionModel(
        id: 't1',
        username: 'dominic',
        type: 'credit',
        category: 'salary',
        description: 'Monthly Salary Deposit',
        amount: 25000,
        date: fd(1),
      ),
      TransactionModel(
        id: 't2',
        username: 'dominic',
        type: 'debit',
        category: 'shopping',
        description: 'SM Department Store',
        amount: 1250,
        date: fd(1),
      ),
      TransactionModel(
        id: 't3',
        username: 'dominic',
        type: 'debit',
        category: 'food',
        description: 'GrabFood Delivery',
        amount: 800,
        date: fd(2),
      ),
      TransactionModel(
        id: 't4',
        username: 'dominic',
        type: 'debit',
        category: 'bills',
        description: 'Meralco Electric Bill',
        amount: 1500,
        date: fd(3),
        note: 'July billing',
      ),
      TransactionModel(
        id: 't5',
        username: 'dominic',
        type: 'debit',
        category: 'bills',
        description: 'Maynilad Water Bill',
        amount: 350,
        date: fd(4),
      ),
      TransactionModel(
        id: 't6',
        username: 'dominic',
        type: 'debit',
        category: 'bills',
        description: 'PLDT Internet Bill',
        amount: 999,
        date: fd(5),
      ),
      TransactionModel(
        id: 't7',
        username: 'dominic',
        type: 'debit',
        category: 'transfer',
        description: 'Transfer to Savings',
        amount: 5000,
        date: fd(7),
        note: 'Monthly savings',
      ),
      TransactionModel(
        id: 't8',
        username: 'dominic',
        type: 'credit',
        category: 'transfer',
        description: 'Received from Juan dela Cruz',
        amount: 2000,
        date: fd(10),
        note: 'Bayad sa utang',
      ),
      TransactionModel(
        id: 't9',
        username: 'dominic',
        type: 'debit',
        category: 'shopping',
        description: 'Lazada Online Shopping',
        amount: 1800,
        date: fd(12),
      ),
      TransactionModel(
        id: 't10',
        username: 'dominic',
        type: 'debit',
        category: 'food',
        description: 'Jollibee Drive-Thru',
        amount: 450,
        date: fd(14),
      ),
      TransactionModel(
        id: 't11',
        username: 'dominic',
        type: 'debit',
        category: 'bills',
        description: 'Globe Mobile Load',
        amount: 299,
        date: fd(16),
      ),
      TransactionModel(
        id: 't12',
        username: 'dominic',
        type: 'credit',
        category: 'salary',
        description: 'Freelance Payment',
        amount: 8000,
        date: fd(20),
      ),
      TransactionModel(
        id: 't13',
        username: 'admin',
        type: 'credit',
        category: 'salary',
        description: 'Monthly Salary',
        amount: 40000,
        date: fd(1),
      ),
      TransactionModel(
        id: 't14',
        username: 'admin',
        type: 'debit',
        category: 'bills',
        description: 'Electric Bill',
        amount: 2500,
        date: fd(3),
      ),
    ];
    await prefs.setString(
      _transactionsKey,
      jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );

    // CARDS
    final cards = [
      BankCard(
        id: 'c1',
        username: 'dominic',
        cardNumber: '**** **** **** 4521',
        cardHolder: 'DOMINIC R SANTOS',
        expiry: '12/27',
        cardType: 'debit',
        spendingLimit: 50000,
        cvv: '•••',
      ),
      BankCard(
        id: 'c2',
        username: 'dominic',
        cardNumber: '**** **** **** 7839',
        cardHolder: 'DOMINIC R SANTOS',
        expiry: '08/26',
        cardType: 'credit',
        spendingLimit: 100000,
        cvv: '•••',
      ),
      BankCard(
        id: 'c3',
        username: 'dominic',
        cardNumber: '**** **** **** 0011',
        cardHolder: 'DOMINIC R SANTOS',
        expiry: '03/25',
        cardType: 'virtual',
        spendingLimit: 10000,
        cvv: '•••',
      ),
      BankCard(
        id: 'c4',
        username: 'admin',
        cardNumber: '**** **** **** 9900',
        cardHolder: 'ADMIN USER',
        expiry: '06/28',
        cardType: 'debit',
        spendingLimit: 75000,
        cvv: '•••',
      ),
    ];
    await prefs.setString(
      _cardsKey,
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );

    // SAVINGS GOALS
    final goals = [
      SavingsGoal(
        id: 'g1',
        username: 'dominic',
        title: 'Emergency Fund',
        targetAmount: 100000,
        currentAmount: 50000,
        icon: 'shield',
      ),
      SavingsGoal(
        id: 'g2',
        username: 'dominic',
        title: 'Travel Fund',
        targetAmount: 40000,
        currentAmount: 15000,
        icon: 'flight',
      ),
      SavingsGoal(
        id: 'g3',
        username: 'dominic',
        title: 'New Laptop',
        targetAmount: 60000,
        currentAmount: 8000,
        icon: 'laptop_mac',
      ),
    ];
    await prefs.setString(
      _goalsKey,
      jsonEncode(goals.map((g) => g.toJson()).toList()),
    );

    // NOTIFICATIONS
    final notifications = [
      NotificationItem(
        id: 'n1',
        username: 'dominic',
        title: 'Salary Credited',
        message: '₱25,000 has been successfully credited to your account.',
        type: 'success',
        date: fd(1),
      ),
      NotificationItem(
        id: 'n2',
        username: 'dominic',
        title: 'Bills Due Reminder',
        message: 'Your Internet bill is due in 3 days. Avoid late charges.',
        type: 'warning',
        date: fd(2),
      ),
      NotificationItem(
        id: 'n3',
        username: 'dominic',
        title: 'Transfer Successful',
        message: '₱5,000 transferred to your Savings account successfully.',
        type: 'success',
        date: fd(7),
      ),
      NotificationItem(
        id: 'n4',
        username: 'dominic',
        title: 'Security Alert',
        message:
            'New login detected from this device. If this was not you, change your password immediately.',
        type: 'security',
        date: fd(8),
        isRead: true,
      ),
      NotificationItem(
        id: 'n5',
        username: 'dominic',
        title: 'Incoming Deposit',
        message: '₱2,000 received from Juan dela Cruz.',
        type: 'success',
        date: fd(10),
        isRead: true,
      ),
    ];
    await prefs.setString(
      _notificationsKey,
      jsonEncode(notifications.map((n) => n.toJson()).toList()),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  /// Generates a collision-resistant local identifier for demo records.
  /// A real banking app should receive identifiers from its backend.
  static String generateId() {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().microsecondsSinceEpoch}_$random';
  }

  static Future<String> generateUniqueAccountNumber() async {
    final users = await getUsers();
    final existing = <String>{
      for (final user in users) user.accountNumber,
      for (final user in users) user.checkingAccountNumber,
    };
    final random = Random.secure();

    while (true) {
      final digits = List.generate(12, (_) => random.nextInt(10)).join();
      final number =
          '${digits.substring(0, 4)}-${digits.substring(4, 8)}-${digits.substring(8)}';
      if (!existing.contains(number)) return number;
    }
  }

  static String formatDate(DateTime dt) => dt.toString().substring(0, 16);

  /// Formats a double as Philippine Peso currency: ₱45,750.00
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '₱${formatter.format(amount)}';
  }

  // ─── USERS ───────────────────────────────────────────────────────────────────

  static Future<List<AppUser>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_usersKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => AppUser.fromJson(e)).toList();
  }

  static Future<void> _saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  static Future<AppUser?> login(String username, String password) async {
    final users = await getUsers();
    try {
      return users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> usernameExists(String username) async {
    final users = await getUsers();
    return users.any((u) => u.username == username);
  }

  static Future<bool> registerUser(AppUser user) async {
    final users = await getUsers();
    if (users.any((u) => u.username == user.username)) return false;
    user.id = users.length + 1;
    users.add(user);
    await _saveUsers(users);
    return true;
  }

  static Future<void> updateUser(AppUser updated) async {
    final users = await getUsers();
    final idx = users.indexWhere((u) => u.username == updated.username);
    if (idx != -1) {
      users[idx] = updated;
      await _saveUsers(users);
    }
  }

  static Future<AppUser?> getUserByAccountNumber(String accountNumber) async {
    final users = await getUsers();
    try {
      return users.firstWhere(
        (u) =>
            u.accountNumber == accountNumber ||
            u.checkingAccountNumber == accountNumber,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<AppUser?> getUserByUsername(String username) async {
    final users = await getUsers();
    try {
      return users.firstWhere((user) => user.username == username);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUsernameKey, username);
  }

  static Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_sessionUsernameKey);
    return username == null ? null : getUserByUsername(username);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUsernameKey);
  }

  static Future<bool> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await login(username, currentPassword);
    if (user == null) return false;
    user.password = newPassword;
    await updateUser(user);
    return true;
  }

  // ── BUDGETS ──────────────────────────────────────────────────────────────

  static Future<Map<String, double>> getBudgets(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_budgetsKey);
    if (raw == null) return {};
    final all = jsonDecode(raw) as Map<String, dynamic>;
    final userBudgets = (all[username] as Map?) ?? {};
    return userBudgets.map(
      (category, amount) =>
          MapEntry(category.toString(), (amount as num).toDouble()),
    );
  }

  static Future<void> setBudget(
    String username,
    String category,
    double amount,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_budgetsKey);
    final all = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final userBudgets = Map<String, dynamic>.from(
      (all[username] as Map?) ?? <String, dynamic>{},
    );
    if (amount <= 0) {
      userBudgets.remove(category);
    } else {
      userBudgets[category] = amount;
    }
    all[username] = userBudgets;
    await prefs.setString(_budgetsKey, jsonEncode(all));
  }

  // ── BILL REMINDERS ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBillReminders(
    String username,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_billRemindersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .where((reminder) => reminder['username'] == username)
        .toList();
  }

  static Future<void> saveBillReminder({
    required String username,
    required String billName,
    required int dueDay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_billRemindersKey);
    final reminders = raw == null ? <dynamic>[] : jsonDecode(raw) as List;
    reminders.removeWhere(
      (reminder) =>
          reminder['username'] == username && reminder['billName'] == billName,
    );
    reminders.add({
      'id': generateId(),
      'username': username,
      'billName': billName,
      'dueDay': dueDay,
    });
    await prefs.setString(_billRemindersKey, jsonEncode(reminders));
  }

  static Future<void> removeBillReminder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_billRemindersKey);
    if (raw == null) return;
    final reminders = jsonDecode(raw) as List;
    reminders.removeWhere((reminder) => reminder['id'] == id);
    await prefs.setString(_billRemindersKey, jsonEncode(reminders));
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────────

  static Future<List<TransactionModel>> getTransactions(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_transactionsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list
        .map((e) => TransactionModel.fromJson(e))
        .where((t) => t.username == username)
        .toList();
  }

  static Future<void> addTransaction(TransactionModel tx) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_transactionsKey);
    final list = data != null ? jsonDecode(data) as List : [];
    list.insert(0, tx.toJson());
    await prefs.setString(_transactionsKey, jsonEncode(list));
  }

  // ─── CARDS ────────────────────────────────────────────────────────────────────

  static Future<List<BankCard>> getCards(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cardsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list
        .map((e) => BankCard.fromJson(e))
        .where((c) => c.username == username)
        .toList();
  }

  static Future<void> _saveAllCards(List<BankCard> allCards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cardsKey,
      jsonEncode(allCards.map((c) => c.toJson()).toList()),
    );
  }

  static Future<void> updateCard(BankCard updated) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cardsKey);
    if (data == null) return;
    final list = (jsonDecode(data) as List)
        .map((e) => BankCard.fromJson(e))
        .toList();
    final idx = list.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
      await _saveAllCards(list);
    }
  }

  static Future<void> addCard(BankCard card) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cardsKey);
    final list = data != null
        ? (jsonDecode(data) as List).map((e) => BankCard.fromJson(e)).toList()
        : <BankCard>[];
    list.add(card);
    await _saveAllCards(list);
  }

  // ─── SAVINGS GOALS ───────────────────────────────────────────────────────────

  static Future<List<SavingsGoal>> getSavingsGoals(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_goalsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list
        .map((e) => SavingsGoal.fromJson(e))
        .where((g) => g.username == username)
        .toList();
  }

  static Future<void> saveGoals(
    List<SavingsGoal> goals,
    String username,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_goalsKey);
    final all = data != null
        ? (jsonDecode(data) as List)
              .map((e) => SavingsGoal.fromJson(e))
              .toList()
        : <SavingsGoal>[];
    all.removeWhere((g) => g.username == username);
    all.addAll(goals);
    await prefs.setString(
      _goalsKey,
      jsonEncode(all.map((g) => g.toJson()).toList()),
    );
  }

  static Future<void> addGoal(SavingsGoal goal) async {
    final goals = await getSavingsGoals(goal.username);
    goals.add(goal);
    await saveGoals(goals, goal.username);
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

  static Future<List<NotificationItem>> getNotifications(
    String username,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_notificationsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list
        .map((e) => NotificationItem.fromJson(e))
        .where((n) => n.username == username)
        .toList();
  }

  static Future<int> getUnreadCount(String username) async {
    final notifs = await getNotifications(username);
    return notifs.where((n) => !n.isRead).length;
  }

  static Future<void> addNotification(NotificationItem notif) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_notificationsKey);
    final list = data != null ? jsonDecode(data) as List : [];
    list.insert(0, notif.toJson());
    await prefs.setString(_notificationsKey, jsonEncode(list));
  }

  static Future<void> markAllRead(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_notificationsKey);
    if (data == null) return;
    final list = (jsonDecode(data) as List)
        .map((e) => NotificationItem.fromJson(e))
        .toList();
    for (final n in list) {
      if (n.username == username) n.isRead = true;
    }
    await prefs.setString(
      _notificationsKey,
      jsonEncode(list.map((n) => n.toJson()).toList()),
    );
  }

  // ─── SETTINGS ────────────────────────────────────────────────────────────────

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('setting_dark_mode') ?? true;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_dark_mode', value);
  }

  static Future<bool> getBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('setting_biometrics') ?? false;
  }

  static Future<void> setBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_biometrics', value);
  }

  static Future<bool> getOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_seen') ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
  }
}
