import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/transaction_model.dart';
import '../models/bank_card.dart';
import '../models/savings_goal.dart';
import '../models/notification_item.dart';
import '../models/beneficiary.dart';
import '../models/scheduled_transfer.dart';

class DataService {
  static const String _transactionsKey = 'ds_transactions';
  static const String _cardsKey = 'ds_cards';
  static const String _goalsKey = 'ds_savings_goals';
  static const String _notificationsKey = 'ds_notifications';
  static const String _seededKey = 'ds_is_seeded_v3';
  static const String _budgetsKey = 'ds_budgets';
  static const String _billRemindersKey = 'ds_bill_reminders';
  static const String _beneficiariesKey = 'ds_beneficiaries';
  static const String _scheduledTransfersKey = 'ds_scheduled_transfers';
  static const String _savingsAutomationKey = 'ds_savings_automation';

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> _notificationsFor(
    DocumentReference<Map<String, dynamic>> user,
  ) => user.collection('notifications');

  static AppUser _userFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return AppUser.fromJson({...data, 'id': null, 'password': ''});
  }

  static Map<String, dynamic> _userData(AppUser user) {
    final data = user.toJson();
    data
      ..remove('id')
      ..remove('password');
    return data;
  }

  static Future<DocumentReference<Map<String, dynamic>>?> _userReference(
    String username,
  ) async {
    final query = await _users
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty ? null : query.docs.single.reference;
  }

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
    // JavaScript bit shifts are 32-bit. On Flutter web, `1 << 32` becomes
    // zero, so Random.nextInt throws RangeError instead of returning an ID.
    // Keep the upper bound within the portable signed 32-bit range.
    final random = Random.secure().nextInt(2147483647).toRadixString(16);
    return '${DateTime.now().microsecondsSinceEpoch}_$random';
  }

  static Future<String> generateUniqueAccountNumber() async {
    final random = Random.secure();

    while (true) {
      final digits = List.generate(12, (_) => random.nextInt(10)).join();
      final number =
          '${digits.substring(0, 4)}-${digits.substring(4, 8)}-${digits.substring(8)}';
      final savingsMatch = await _users
          .where('accountNumber', isEqualTo: number)
          .limit(1)
          .get();
      final checkingMatch = await _users
          .where('checkingAccountNumber', isEqualTo: number)
          .limit(1)
          .get();
      if (savingsMatch.docs.isEmpty && checkingMatch.docs.isEmpty) {
        return number;
      }
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
    final snapshot = await _users.get();
    return snapshot.docs.map(_userFromDocument).toList();
  }

  static Future<AppUser?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final profile = await _users.doc(credential.user!.uid).get();
      if (!profile.exists) {
        await _auth.signOut();
        return null;
      }
      final user = _userFromDocument(profile);
      await processDueScheduledTransfers(user.username);
      final refreshed = await _users.doc(credential.user!.uid).get();
      return refreshed.exists ? _userFromDocument(refreshed) : null;
    } on FirebaseAuthException {
      return null;
    }
  }

  static Future<bool> usernameExists(String username) async {
    final result = await _users
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  static Future<bool> registerUser(AppUser user) async {
    try {
      if (await usernameExists(user.username)) return false;
      final credential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      await _users.doc(credential.user!.uid).set({
        ..._userData(user),
        'authUid': credential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseAuthException {
      return false;
    } on FirebaseException {
      return false;
    }
  }

  static Future<void> updateUser(AppUser updated) async {
    final reference = await _userReference(updated.username);
    if (reference != null) await reference.update(_userData(updated));
  }

  static Future<AppUser?> getUserByAccountNumber(String accountNumber) async {
    // Trim whitespace to handle copy-paste errors
    final trimmed = accountNumber.trim();
    
    // Try matching against savings account (accountNumber field)
    final savingsMatch = await _users
        .where('accountNumber', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (savingsMatch.docs.isNotEmpty) {
      return _userFromDocument(savingsMatch.docs.single);
    }
    
    // Try matching against checking account (checkingAccountNumber field)
    final checkingMatch = await _users
        .where('checkingAccountNumber', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (checkingMatch.docs.isNotEmpty) {
      return _userFromDocument(checkingMatch.docs.single);
    }
    
    // Account not found in either field
    return null;
  }

  static Future<AppUser?> getUserByUsername(String username) async {
    final reference = await _userReference(username);
    if (reference == null) return null;
    final document = await reference.get();
    return document.exists ? _userFromDocument(document) : null;
  }

  static Future<AppUser?> restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final profile = await _users.doc(firebaseUser.uid).get();
    return profile.exists ? _userFromDocument(profile) : null;
  }

  /// Emits the signed-in user's profile whenever its Firestore document changes.
  static Stream<AppUser?> watchCurrentUser() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return Stream.value(null);
    return _users.doc(firebaseUser.uid).snapshots().map(
          (profile) => profile.exists ? _userFromDocument(profile) : null,
        );
  }

  static Future<void> clearSession() async {
    await _auth.signOut();
  }

  static Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  static Future<bool> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser?.email == null) return false;
    try {
      final credential = EmailAuthProvider.credential(
        email: firebaseUser!.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  // ── BUDGETS ──────────────────────────────────────────────────────────────

  static Future<Map<String, double>> getBudgets(String username) async {
    final user = await _userReference(username);
    if (user == null) return {};

    final snapshot = await user.collection('budgets').get();

    return {
      for (final doc in snapshot.docs)
        doc.id: (doc['amount'] as num).toDouble(),
    };
  }

  static Future<void> setBudget(
    String username,
    String category,
    double amount,
  ) async {
    final user = await _userReference(username);
    if (user == null) return;

    if (amount <= 0) {
      await user.collection('budgets').doc(category).delete();
    } else {
      await user.collection('budgets').doc(category).set({
        'category': category,
        'amount': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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

  /// Moves funds and creates both account histories in one Firestore transaction.
  /// Returns an error message when the transfer cannot be completed.
  ///
  /// All Firestore reads happen BEFORE writes inside the transaction,
  /// which is required by the web SDK. The sender is resolved via the
  /// authenticated user's UID directly (no extra query). The recipient
  /// is found via account number queries before the transaction starts.
  static Future<String?> transferFunds({
    required String senderUsername,
    required String targetAccountNumber,
    required bool fromSavings,
    required double amount,
    required String note,
  }) async {
    // ── Resolve sender ref (no query needed — use auth UID directly) ──────────
    final currentAuthUser = _auth.currentUser;
    if (currentAuthUser == null) return 'You are not logged in.';
    final senderRef = _users.doc(currentAuthUser.uid);

    // ── Resolve recipient ref BEFORE the transaction (queries not allowed
    //    inside transactions on web SDK) ────────────────────────────────────────
    final trimmedTarget = targetAccountNumber.trim();
    QuerySnapshot<Map<String, dynamic>> savingsMatch;
    QuerySnapshot<Map<String, dynamic>> checkingMatch;

    try {
      savingsMatch = await _users
          .where('accountNumber', isEqualTo: trimmedTarget)
          .limit(1)
          .get();
      checkingMatch = savingsMatch.docs.isEmpty
          ? await _users
                .where('checkingAccountNumber', isEqualTo: trimmedTarget)
                .limit(1)
                .get()
          : savingsMatch; // reuse — recipient found already
    } on FirebaseException {
      return 'Account number lookup failed. Please try again.';
    } catch (_) {
      return 'Account number lookup failed. Please try again.';
    }

    final recipientDoc = savingsMatch.docs.isNotEmpty
        ? savingsMatch.docs.single
        : checkingMatch.docs.isNotEmpty
        ? checkingMatch.docs.single
        : null;

    if (recipientDoc == null) return 'Account number not found.';
    final recipientRef = recipientDoc.reference;

    try {
      // Do not throw validation errors from this callback. On web, Firestore
      // converts a Dart exception raised in a transaction callback into a JS
      // promise error (shown as `RethrownDartError`) instead of a normal
      // transfer result.
      final validationError = await _firestore.runTransaction<String?>(
        (txn) async {
        // ── ALL reads must come before any writes (web SDK requirement) ────────
        final senderSnap = await txn.get(senderRef);
        final recipientSnap = recipientRef.path == senderRef.path
            ? senderSnap
            : await txn.get(recipientRef);

        if (!senderSnap.exists) return 'Your account could not be found.';

        final sender = senderSnap.data()!;
        final receiver = recipientSnap.data()!;

        final senderSavings  = (sender['savingsBalance']  as num? ?? 0).toDouble();
        final senderChecking = (sender['checkingBalance'] as num? ?? 0).toDouble();
        final available = fromSavings ? senderSavings : senderChecking;

          if (available < amount) {
            return 'Insufficient ${fromSavings ? 'Savings' : 'Checking'} balance.';
          }

        final isOwnAccount = recipientRef.path == senderRef.path;
        final receiverUsesChecking =
            trimmedTarget == receiver['checkingAccountNumber'];

          if (isOwnAccount && receiverUsesChecking != fromSavings) {
            return 'Select your other account as the destination for an own-account transfer.';
          }

        final now = formatDate(DateTime.now());
        final senderName =
            '${sender['name'] ?? ''} ${sender['surname'] ?? ''}'.trim();

        // ── ALL writes after all reads ─────────────────────────────────────────
        final senderUpdates = <String, dynamic>{
          if (fromSavings)  'savingsBalance':  senderSavings  - amount,
          if (!fromSavings) 'checkingBalance': senderChecking - amount,
        };

        if (isOwnAccount) {
          // Credit the other account on the same document
          final receiverSavings  = (receiver['savingsBalance']  as num? ?? 0).toDouble();
          final receiverChecking = (receiver['checkingBalance'] as num? ?? 0).toDouble();
          senderUpdates[receiverUsesChecking ? 'checkingBalance' : 'savingsBalance'] =
              (receiverUsesChecking ? receiverChecking : receiverSavings) + amount;
          txn.update(senderRef, senderUpdates);

          final fromLabel = fromSavings ? 'Savings' : 'Checking';
          final toLabel   = receiverUsesChecking ? 'Checking' : 'Savings';
          final debitId  = generateId();
          final creditId = generateId();
          txn.set(
            senderRef.collection('transactions').doc(debitId),
            TransactionModel(
              id: debitId, username: senderUsername, type: 'debit',
              category: 'transfer',
              description: 'Transfer from $fromLabel to $toLabel',
              amount: amount, date: now, note: note,
            ).toJson(),
          );
          txn.set(
            senderRef.collection('transactions').doc(creditId),
            TransactionModel(
              id: creditId, username: senderUsername, type: 'credit',
              category: 'transfer',
              description: 'Transfer from $fromLabel to $toLabel',
              amount: amount, date: now, note: note,
            ).toJson(),
          );
          final notificationId = generateId();
          txn.set(
            _notificationsFor(senderRef).doc(notificationId),
            {
              ...NotificationItem(
                id: notificationId,
                username: senderUsername,
                title: 'Own Account Transfer Complete',
                message:
                    '${formatCurrency(amount)} moved from $fromLabel to $toLabel.',
                type: 'success',
                date: now,
              ).toJson(),
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
          return null;
        }

        // ── Cross-user transfer ────────────────────────────────────────────────
        final receiverSavings  = (receiver['savingsBalance']  as num? ?? 0).toDouble();
        final receiverChecking = (receiver['checkingBalance'] as num? ?? 0).toDouble();
        final recipientUsername = (receiver['username'] as String?) ?? '';

        txn.update(senderRef, senderUpdates);
        txn.update(recipientRef, {
          receiverUsesChecking ? 'checkingBalance' : 'savingsBalance':
              (receiverUsesChecking ? receiverChecking : receiverSavings) + amount,
        });

        final senderTxId    = generateId();
        final recipientTxId = generateId();
        txn.set(
          senderRef.collection('transactions').doc(senderTxId),
          TransactionModel(
            id: senderTxId, username: senderUsername, type: 'debit',
            category: 'transfer',
            description: 'Transfer to $trimmedTarget',
            amount: amount, date: now, note: note,
          ).toJson(),
        );
        txn.set(
          recipientRef.collection('transactions').doc(recipientTxId),
          TransactionModel(
            id: recipientTxId, username: recipientUsername, type: 'credit',
            category: 'transfer',
            description: 'Received from $senderName',
            amount: amount, date: now, note: note,
          ).toJson(),
        );
        final senderNotificationId = generateId();
        final recipientNotificationId = generateId();
        txn.set(
          _notificationsFor(senderRef).doc(senderNotificationId),
          {
            ...NotificationItem(
              id: senderNotificationId,
              username: senderUsername,
              title: 'Transfer Successful',
              message:
                  '${formatCurrency(amount)} sent to $trimmedTarget.',
              type: 'success',
              date: now,
            ).toJson(),
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
        txn.set(
          _notificationsFor(recipientRef).doc(recipientNotificationId),
          {
            ...NotificationItem(
              id: recipientNotificationId,
              username: recipientUsername,
              title: 'Incoming Transfer',
              message: 'You received ${formatCurrency(amount)} from $senderName.',
              type: 'success',
              date: now,
            ).toJson(),
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
          return null;
        },
      );
      if (validationError != null) return validationError;
      return null;
    } on FirebaseException {
      return 'Transfer failed. Please try again.';
    } catch (_) {
      // Keeps a web SDK error from becoming an unhandled browser promise.
      return 'Transfer failed. Please try again.';
    }
  }

  static Future<List<TransactionModel>> getTransactions(String username) async {
    final reference = await _userReference(username);
    if (reference == null) return [];
    final snapshot = await reference
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((document) => TransactionModel.fromJson(document.data()))
        .toList();
  }

  static Future<void> addTransaction(TransactionModel tx) async {
    final reference = await _userReference(tx.username);
    if (reference == null) return;
    await reference.collection('transactions').doc(tx.id).set(tx.toJson());
    await _applySavingsAutomation(tx);
  }

  static Future<Map<String, dynamic>> getSavingsAutomation(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savingsAutomationKey);
    if (raw == null) return {'enabled': false};
    final all = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return Map<String, dynamic>.from((all[username] as Map?) ?? {'enabled': false});
  }

  static Future<void> setSavingsAutomation(String username, Map<String, dynamic> setting) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savingsAutomationKey);
    final all = raw == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    all[username] = setting;
    await prefs.setString(_savingsAutomationKey, jsonEncode(all));
  }

  static Future<void> _applySavingsAutomation(TransactionModel tx) async {
    if (tx.type != 'debit' || tx.category == 'transfer') return;
    final setting = await getSavingsAutomation(tx.username);
    if (setting['enabled'] != true) return;
    final goalId = setting['goalId'] as String?;
    if (goalId == null || goalId.isEmpty) return;
    final mode = setting['mode'] as String? ?? 'roundUp';
    final amount = mode == 'fixed'
        ? ((setting['amount'] as num?) ?? 0).toDouble()
        : (tx.amount.ceilToDouble() - tx.amount);
    if (amount <= 0) return;
    final user = await getUserByUsername(tx.username);
    if (user == null || user.checkingBalance < amount) return;
    final goals = await getSavingsGoals(tx.username);
    final index = goals.indexWhere((goal) => goal.id == goalId);
    if (index == -1) return;
    final goal = goals[index];
    final newGoalAmount = (goal.currentAmount + amount).clamp(0.0, goal.targetAmount).toDouble();
    final actualAmount = newGoalAmount - goal.currentAmount;
    if (actualAmount <= 0) return;
    user.checkingBalance -= actualAmount;
    user.savingsBalance += actualAmount;
    goals[index] = SavingsGoal(
      id: goal.id,
      username: goal.username,
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentAmount: newGoalAmount,
      icon: goal.icon,
    );
    await updateUser(user);
    await saveGoals(goals, tx.username);
    final reference = await _userReference(tx.username);
    if (reference != null) {
      final id = generateId();
      await reference.collection('transactions').doc(id).set(TransactionModel(
        id: id,
        username: tx.username,
        type: 'debit',
        category: 'transfer',
        description: 'Auto-save to ${goal.title}',
        amount: actualAmount,
        date: formatDate(DateTime.now()),
        note: 'Savings automation',
      ).toJson());
    }
  }

  // â”€â”€â”€ BENEFICIARIES & SCHEDULED TRANSFERS â”€â”€â”€

  static Future<List<Beneficiary>> getBeneficiaries(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_beneficiariesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((item) => Beneficiary.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.username == username)
        .toList();
  }

  static Future<void> saveBeneficiary(Beneficiary beneficiary) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_beneficiariesKey);
    final all = raw == null ? <Beneficiary>[] : (jsonDecode(raw) as List)
        .map((item) => Beneficiary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    all.removeWhere((item) =>
        item.username == beneficiary.username &&
        item.accountNumber == beneficiary.accountNumber);
    all.add(beneficiary);
    await prefs.setString(_beneficiariesKey, jsonEncode(all.map((item) => item.toJson()).toList()));
  }

  static Future<void> removeBeneficiary(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_beneficiariesKey);
    if (raw == null) return;
    final all = jsonDecode(raw) as List;
    all.removeWhere((item) => item['id'] == id);
    await prefs.setString(_beneficiariesKey, jsonEncode(all));
  }

  static Future<List<ScheduledTransfer>> getScheduledTransfers(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scheduledTransfersKey);
    if (raw == null) return [];
    final items = (jsonDecode(raw) as List)
        .map((item) => ScheduledTransfer.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.username == username && item.isActive)
        .toList();
    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }

  static Future<void> saveScheduledTransfer(ScheduledTransfer transfer) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scheduledTransfersKey);
    final all = raw == null ? <ScheduledTransfer>[] : (jsonDecode(raw) as List)
        .map((item) => ScheduledTransfer.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    all.removeWhere((item) => item.id == transfer.id);
    all.add(transfer);
    await prefs.setString(_scheduledTransfersKey, jsonEncode(all.map((item) => item.toJson()).toList()));
  }

  static Future<void> cancelScheduledTransfer(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scheduledTransfersKey);
    if (raw == null) return;
    final all = jsonDecode(raw) as List;
    all.removeWhere((item) => item['id'] == id);
    await prefs.setString(_scheduledTransfersKey, jsonEncode(all));
  }

  /// Runs due transfers while the signed-in app is open. Background execution
  /// requires a server-side scheduler in a production banking application.
  static Future<void> processDueScheduledTransfers(String username) async {
    final due = (await getScheduledTransfers(username))
        .where((item) => !item.dueDate.isAfter(DateTime.now()))
        .toList();
    for (final item in due) {
      final error = await transferFunds(
        senderUsername: username,
        targetAccountNumber: item.accountNumber,
        fromSavings: item.fromSavings,
        amount: item.amount,
        note: item.note.isEmpty ? 'Scheduled transfer' : item.note,
      );
      if (error != null) continue;
      if (item.repeatsMonthly) {
        await saveScheduledTransfer(ScheduledTransfer(
          id: item.id,
          username: item.username,
          accountNumber: item.accountNumber,
          beneficiaryName: item.beneficiaryName,
          amount: item.amount,
          fromSavings: item.fromSavings,
          note: item.note,
          scheduledFor: DateTime(item.dueDate.year, item.dueDate.month + 1, item.dueDate.day).toIso8601String(),
          repeatsMonthly: true,
        ));
      } else {
        await cancelScheduledTransfer(item.id);
      }
    }
  }

  /// Emits the signed-in user's transaction history in real time.
  static Stream<List<TransactionModel>> watchCurrentTransactions() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return Stream.value([]);
    return _users
        .doc(firebaseUser.uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => TransactionModel.fromJson(document.data()))
              .toList(),
        );
  }

  // ─── CARDS ────────────────────────────────────────────────────────────────────

  static Future<List<BankCard>> getCards(String username) async {
    final user = await _userReference(username);
    if (user == null) return [];

    final snapshot = await user
        .collection('cards')
        .orderBy('cardType')
        .get();

    return snapshot.docs
        .map((doc) => BankCard.fromJson(doc.data()))
        .toList();
  }

  // Unused
  static Future<void> _saveAllCards(List<BankCard> allCards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cardsKey,
      jsonEncode(allCards.map((c) => c.toJson()).toList()),
    );
  }

  static Future<void> updateCard(BankCard updated) async {
    final user = await _userReference(updated.username);
    if (user == null) return;

    await user
        .collection('cards')
        .doc(updated.id)
        .update(updated.toJson());
  }

  static Future<void> addCard(BankCard card) async {
    final user = await _userReference(card.username);
    if (user == null) return;

    await user.collection('cards').doc(card.id).set(card.toJson());
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
    final user = await _userReference(username);
    if (user == null) return [];
    final snapshot = await _notificationsFor(user)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((document) => NotificationItem.fromJson(document.data()))
        .toList();
  }

  static Future<int> getUnreadCount(String username) async {
    final notifs = await getNotifications(username);
    return notifs.where((n) => !n.isRead).length;
  }

  /// Emits in-app notifications for the signed-in user in real time.
  static Stream<List<NotificationItem>> watchCurrentNotifications() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return Stream.value([]);
    return _notificationsFor(_users.doc(firebaseUser.uid))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => NotificationItem.fromJson(document.data()))
              .toList(),
        );
  }

  static Future<void> addNotification(NotificationItem notif) async {
    final user = await _userReference(notif.username);
    if (user == null) return;
    await _notificationsFor(user).doc(notif.id).set({
      ...notif.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markAllRead(String username) async {
    final user = await _userReference(username);
    if (user == null) return;
    final unread = await _notificationsFor(user)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final notification in unread.docs) {
      batch.update(notification.reference, {'isRead': true});
    }
    await batch.commit();
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

  static Future<bool> getSensitiveDataVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('setting_sensitive_data_visible') ?? true;
  }

  static Future<void> setSensitiveDataVisible(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_sensitive_data_visible', value);
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
