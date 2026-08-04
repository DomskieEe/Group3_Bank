import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillsScreen extends StatefulWidget {
  final double currentBalance;

  const BillsScreen({
    super.key,
    required this.currentBalance,
  });

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late double balance;

  double electricBill = 0;
  double waterBill = 0;
  double internetBill = 0;
  double Iphone = 0;

  List<Map<String, String>> paymentHistory = [];

  @override
  void initState() {
    super.initState();
    balance = widget.currentBalance;
    _loadData();
  }

  // Load saved data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      electricBill = prefs.getDouble('electricBill') ?? electricBill;
      waterBill = prefs.getDouble('waterBill') ?? waterBill;
      internetBill = prefs.getDouble('internetBill') ?? internetBill;
      Iphone = prefs.getDouble('Iphone') ?? Iphone;

      // If balance wasn't modified externally, load saved balance if available
      balance = prefs.getDouble('bills_balance') ?? widget.currentBalance;

      // Load payment history list
      final String? historyString = prefs.getString('paymentHistory');
      if (historyString != null) {
        final List<dynamic> decodedList = jsonDecode(historyString);
        paymentHistory = decodedList
            .map((item) => Map<String, String>.from(item))
            .toList();
      }
    });
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('electricBill', electricBill);
    await prefs.setDouble('waterBill', waterBill);
    await prefs.setDouble('internetBill', internetBill);
    await prefs.setDouble('Iphone', Iphone);
    await prefs.setDouble('bills_balance', balance);
    await prefs.setString('paymentHistory', jsonEncode(paymentHistory));
  }

  void editBill(String billName) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter $billName Amount"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter Amount",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final amount = double.tryParse(controller.text) ?? 0;

                setState(() {
                  balance -= amount;

                  if (balance < 0) {
                    balance = 0;
                  }

                  switch (billName) {
                    case "Electric Bill":
                      electricBill += amount;
                      break;

                    case "Water Bill":
                      waterBill += amount;
                      break;

                    case "Internet Bill":
                      internetBill += amount;
                      break;

                    case "Iphone":
                      Iphone += amount;
                      break;
                  }

                  paymentHistory.insert(0, {
                    "bill": billName,
                    "amount": "₱${amount.toStringAsFixed(2)}",
                    "date": DateTime.now().toString().substring(0, 16),
                  });
                });

                // Save automatically after every transaction update
                _saveData();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.grey[800],
                    content: Text(
                      "$billName paid: ₱${amount.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void saveAndReturn() {
    _saveData();
    Navigator.pop(context, balance);
  }

  Widget buildBillTile(
      IconData icon,
      Color color,
      String title,
      double totalPaid,
      ) {
    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "Total Paid: ₱${totalPaid.toStringAsFixed(2)}",
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => editBill(title),
          child: const Text("Add"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text("Bills Tracker"),
        actions: [
          IconButton(
            onPressed: saveAndReturn,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red[700],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Available Balance",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "₱${balance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          buildBillTile(
            Icons.flash_on,
            Colors.redAccent,
            "Electric Bill",
            electricBill,
          ),
          buildBillTile(
            Icons.water_drop,
            Colors.redAccent,
            "Water Bill",
            waterBill,
          ),
          buildBillTile(
            Icons.wifi,
            Colors.redAccent,
            "Internet Bill",
            internetBill,
          ),
          buildBillTile(
            Icons.phone,
            Colors.redAccent,
            "Iphone",
            Iphone, // Fixed bug where Iphone was using internetBill variable
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Payment History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: paymentHistory.isEmpty
                ? const Center(
              child: Text(
                "No payments recorded yet.",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              itemCount: paymentHistory.length,
              itemBuilder: (context, index) {
                final item = paymentHistory[index];

                return Card(
                  elevation: 1,
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.red,
                      ),
                    ),
                    title: Text(
                      item["bill"]!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      item["date"]!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      item["amount"]!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}