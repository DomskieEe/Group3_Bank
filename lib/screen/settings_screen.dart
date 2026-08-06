import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = true;
  bool _useBiometrics = false;
  bool _loading = true;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isDark = await DataService.getDarkMode();
    final useBio = await DataService.getBiometrics();
    if (!mounted) return;
    setState(() {
      _isDark = isDark;
      _useBiometrics = useBio;
      _loading = false;
    });
  }

  Future<void> _toggleDark(bool val) async {
    setState(() => _isDark = val);
    await DataService.setDarkMode(val);
    AppState.instance.themeMode.value = val ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _toggleBiometrics(bool val) async {
    if (!val) {
      setState(() => _useBiometrics = false);
      await DataService.setBiometrics(false);
      return;
    }

    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      if (!supported || !canCheck || available.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set up fingerprint or face unlock in your phone settings first.'),
          ),
        );
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm biometrics for Snap Wallet',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!mounted) return;
      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric setup was cancelled.')),
        );
        return;
      }
      setState(() => _useBiometrics = true);
      await DataService.setBiometrics(true);
    } on LocalAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to enable biometrics: ${error.code.name}.')),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final user = AppState.instance.currentUser;
    if (user == null) {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
      return;
    }

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newCtrl.text.length < 6 ||
                    newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Use matching passwords of at least 6 characters.',
                      ),
                    ),
                  );
                  return;
                }
                final changed = await DataService.changePassword(
                  username: user.username,
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (!ctx.mounted) return;
                if (!changed) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Current password is incorrect.'),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully.'),
                  ),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
    } finally {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Display',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark themes'),
            secondary: const Icon(Icons.dark_mode),
            value: _isDark,
            onChanged: _toggleDark,
            activeThumbColor: const Color(0xFFD32F2F),
          ),
          const Divider(height: 40),

          const Text(
            'Security',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Biometric Login'),
            subtitle: const Text('Use fingerprint or face ID to login'),
            secondary: const Icon(Icons.fingerprint),
            value: _useBiometrics,
            onChanged: _toggleBiometrics,
            activeThumbColor: const Color(0xFFD32F2F),
          ),
          ListTile(
            title: const Text('Change Password'),
            leading: const Icon(Icons.lock),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordDialog,
          ),
          const Divider(height: 40),

          const Text(
            'About',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('v2.0.0 (Snap Wallet)'),
            leading: const Icon(Icons.info),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
