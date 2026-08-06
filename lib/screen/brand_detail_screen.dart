import 'package:flutter/material.dart';

class BrandDetailScreen extends StatelessWidget {
  final String brandName;
  final String description;
  final String assetPath;

  const BrandDetailScreen({
    super.key,
    required this.brandName,
    required this.description,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(brandName),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage(assetPath),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              brandName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_offer, color: Color(0xFFD32F2F)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Show this voucher code at checkout to claim your exclusive discount!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}