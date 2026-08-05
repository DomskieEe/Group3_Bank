import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _editProfile() async {
    final user = AppState.instance.currentUser;
    if (user == null) return;
    final firstCtrl = TextEditingController(text: user.name);
    final lastCtrl = TextEditingController(text: user.surname);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);
    final birthdayCtrl = TextEditingController(text: user.birthday);

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstCtrl,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                TextField(
                  controller: lastCtrl,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address'),
                ),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                TextField(
                  controller: birthdayCtrl,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Birthday (YYYY-MM-DD)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final first = firstCtrl.text.trim();
                final last = lastCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final birthday = birthdayCtrl.text.trim();
                if (first.isEmpty ||
                    last.isEmpty ||
                    (email.isNotEmpty &&
                        !RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) ||
                    (phone.isNotEmpty &&
                        !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) ||
                    (birthday.isNotEmpty &&
                        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birthday))) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide valid profile details.'),
                    ),
                  );
                  return;
                }
                user
                  ..name = first
                  ..surname = last
                  ..email = email
                  ..phone = phone
                  ..birthday = birthday;
                await DataService.updateUser(user);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully.'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      firstCtrl.dispose();
      lastCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      birthdayCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFD32F2F),
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            _buildProfileItem(
              Icons.email,
              'Email Address',
              user.email.isNotEmpty ? user.email : 'Not set',
            ),
            _buildProfileItem(
              Icons.phone,
              'Phone Number',
              user.phone.isNotEmpty ? user.phone : 'Not set',
            ),
            _buildProfileItem(
              Icons.cake,
              'Birthday',
              user.birthday.isNotEmpty ? user.birthday : 'Not set',
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _editProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'EDIT PROFILE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
