import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'transfer_screen.dart';
import 'bills_screen.dart';
import 'cards_screen.dart';
import 'savings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double balance = 0.00;
  List<Map<String, String>> paymentHistory = [];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      balance = prefs.getDouble('balance') ?? 0.00;

      // Load payment history saved from the BillsScreen
      final String? historyString = prefs.getString('paymentHistory');
      if (historyString != null) {
        final List<dynamic> decodedList = jsonDecode(historyString);
        paymentHistory = decodedList
            .map((item) => Map<String, String>.from(item))
            .toList();
      }
    });
  }

  Future<void> saveBalance(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', value);
  }

  void updateBalance() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Available Balance"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter amount to add",
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
              onPressed: () async {
                double addedAmount =
                    double.tryParse(controller.text) ?? 0;

                setState(() {
                  balance += addedAmount;
                });

                await saveBalance(balance);

                Navigator.pop(context);
              },
              child: const Text("Add"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0b0b0b),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Snap Wallet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFD32F2F), // Red
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // BALANCE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD32F2F), // Red
                      Colors.black,      // Black
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Available Balance",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "₱${balance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Track your personal expenses",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: updateBalance,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Balance"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // BUDGET STATUS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Budget Overview",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Current Balance: ₱${balance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(
                      value: 0.65,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "65% Budget Remaining",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Quick Actions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildAction(
                    context,
                    Icons.send,
                    "Transfer",
                    const TransferScreen(),
                  ),
                  InkWell(
                    onTap: () async {
                      final updatedBalance = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillsScreen(
                            currentBalance: balance,
                          ),
                        ),
                      );

                      loadDashboardData();

                      if (updatedBalance != null) {
                        setState(() {
                          balance = updatedBalance;
                        });

                        await saveBalance(updatedBalance);
                      }
                    },
                    child: const Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFD32F2F), // Red
                          child: Icon(
                            Icons.payment,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Bills",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildAction(
                    context,
                    Icons.credit_card,
                    "Cards",
                    const CardsScreen(),
                  ),
                  buildAction(
                    context,
                    Icons.savings,
                    "Savings",
                    const SavingsScreen(),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Recent Transactions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // DYNAMIC BILLS PAYMENT HISTORY LIST
              if (paymentHistory.isNotEmpty) ...[
                ...paymentHistory.map((item) {
                  return transactionTile(
                    Icons.receipt_long,
                    item["bill"]!,
                    "- ${item["amount"]!}",
                    Colors.redAccent,
                    item["date"]!,
                  );
                }),
              ],

              // STATIC/MOCK TRANSACTIONS
              transactionTile(
                Icons.shopping_bag,
                "SM Department Store",
                "- ₱1,250",
                Colors.redAccent,
                "Today",
              ),
              transactionTile(
                Icons.restaurant,
                "Food Delivery",
                "- ₱800",
                Colors.redAccent,
                "Today",
              ),
              transactionTile(
                Icons.attach_money,
                "Salary Deposit",
                "+ ₱25,000",
                Colors.greenAccent,
                "Today",
              ),

              const SizedBox(height: 30),

              const Text(
                "AI Insights",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Based on your spending habits, reducing food delivery by 20% may help save approximately ₱1,600 this month.",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAction(
      BuildContext context,
      IconData icon,
      String title,
      Widget screen,
      ) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => screen,
          ),
        );
        loadDashboardData();
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFD32F2F), // Red
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  Widget transactionTile(
      IconData icon,
      String title,
      String amount,
      Color amountColor,
      String subtitleDate,
      ) {
    return Card(
      color: Colors.white10,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white12,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitleDate,
          style: const TextStyle(
            color: Colors.white54,
          ),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}