import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_user.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import 'transaction_history_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _showQr(BuildContext context, String accountNum) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My QR Code', textAlign: TextAlign.center),
        content: SizedBox(
          width: 232,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: SizedBox.square(
                  dimension: 200,
                  child: QrImageView(
                    data: accountNum,
                    version: QrVersions.auto,
                    eyeStyle: const QrEyeStyle(color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                accountNum,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialUser = AppState.instance.currentUser;
    return StreamBuilder<AppUser?>(
      stream: DataService.watchCurrentUser(),
      initialData: initialUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? initialUser;
        if (user == null) return const Center(child: Text('Not logged in.'));
        AppState.instance.currentUser = user;

        final checkingNum = user.checkingAccountNumber.isNotEmpty
            ? user.checkingAccountNumber
            : 'N/A';

        return ValueListenableBuilder<bool>(
          valueListenable: AppState.instance.sensitiveDataVisible,
          builder: (context, isVisible, _) => Scaffold(
      appBar: AppBar(
        title: const Text('My Accounts'),
        actions: [
          IconButton(
            onPressed: () async {
              final next = !isVisible;
              AppState.instance.sensitiveDataVisible.value = next;
              await DataService.setSensitiveDataVisible(next);
            },
            icon: Icon(isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            tooltip: isVisible ? 'Hide sensitive information' : 'Show sensitive information',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deposit Accounts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAccountCard(
              context,
              title: 'Savings Account',
              accountNumber: user.accountNumber,
              balance: user.savingsBalance,
              status: user.accountStatus,
              isPrimary: user.accountType == 'savings',
              isSensitiveVisible: isVisible,
              onQrTap: isVisible ? () => _showQr(context, user.accountNumber) : null,
            ),
            const SizedBox(height: 16),
            _buildAccountCard(
              context,
              title: 'Checking Account',
              accountNumber: checkingNum,
              balance: user.checkingBalance,
              status: user.accountStatus,
              isPrimary: user.accountType == 'checking',
              isSensitiveVisible: isVisible,
              onQrTap: isVisible ? () => _showQr(context, checkingNum) : null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryScreen(),
                  ),
                ),
                icon: const Icon(Icons.history, color: Color(0xFFD32F2F)),
                label: const Text(
                  'View Full Transaction History',
                  style: TextStyle(color: Color(0xFFD32F2F)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFD32F2F)),
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
        );
      },
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String title,
    required String accountNumber,
    required double balance,
    required String status,
    required bool isPrimary,
    required bool isSensitiveVisible,
    required VoidCallback? onQrTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () async {
                        final next = !AppState.instance.sensitiveDataVisible.value;
                        AppState.instance.sensitiveDataVisible.value = next;
                        await DataService.setSensitiveDataVisible(next);
                      },
                      icon: Icon(
                        isSensitiveVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: isSensitiveVisible
                          ? 'Hide account details'
                          : 'Show account details',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSensitiveVisible
                          ? DataService.formatCurrency(balance)
                          : '₱ ••••••',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text(
                      'Account Number',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSensitiveVisible ? accountNumber : '••••-••••-••••',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                      ],
                    ),
                    IconButton(
                      onPressed: onQrTap,
                      icon: const Icon(
                        Icons.qr_code,
                        color: Color(0xFFD32F2F),
                      ),
                      tooltip: 'Show account QR code',
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
