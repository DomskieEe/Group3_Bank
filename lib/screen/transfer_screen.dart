import 'package:flutter/material.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() =>
      _TransferScreenState();
}

class _TransferScreenState
    extends State<TransferScreen> {

  final accountController =
  TextEditingController();

  final amountController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transfer Money"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: accountController,
              decoration: const InputDecoration(
                labelText: "Account Number",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: "Amount",
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: () {

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      "Transferred ₱${amountController.text}",
                    ),
                  ),
                );
              },
              child: const Text("Transfer"),
            )
          ],
        ),
      ),
    );
  }
}