import 'package:flutter/material.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text("Savings Goals"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 2,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(
                    Icons.savings,
                    color: Colors.red,
                  ),
                ),
                title: const Text(
                  "Emergency Fund",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "₱50,000 / ₱100,000",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: const Text(
                  "50%",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Card(
              elevation: 2,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(
                    Icons.flight,
                    color: Colors.red,
                  ),
                ),
                title: const Text(
                  "Travel Fund",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "₱15,000 / ₱40,000",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: const Text(
                  "37.5%",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}