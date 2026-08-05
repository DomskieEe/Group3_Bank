import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/data_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final surname = _surnameCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (name.isEmpty || surname.isEmpty || user.isEmpty || pass.isEmpty) {
      _showSnack('Please fill in all required fields.');
      return;
    }
    if (pass.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      _showSnack('Passwords do not match.');
      return;
    }
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnack('A valid email address is required for Firebase login.');
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      _showSnack('Please enter a valid phone number.');
      return;
    }

    setState(() => _loading = true);

    final exists = await DataService.usernameExists(user);
    if (!mounted) return;
    if (exists) {
      setState(() => _loading = false);
      _showSnack('Username already taken.');
      return;
    }

    final savingsAccountNumber =
        await DataService.generateUniqueAccountNumber();
    String checkingAccountNumber;
    do {
      checkingAccountNumber = await DataService.generateUniqueAccountNumber();
    } while (checkingAccountNumber == savingsAccountNumber);

    final newUser = AppUser(
      name: name,
      surname: surname,
      username: user,
      password: pass,
      email: email,
      phone: phone,
      accountNumber: savingsAccountNumber,
      checkingAccountNumber: checkingAccountNumber,
      accountType: 'savings',
      accountStatus: 'active',
      savingsBalance: 0.0,
      checkingBalance: 0.0,
    );

    final success = await DataService.registerUser(newUser);
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      _showSnack('Registration successful! Please login.');
      Navigator.pop(context);
    } else {
      _showSnack('An error occurred during registration.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff000000), Color(0xff1f0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join Snap Wallet today.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _nameCtrl,
                        hint: 'First Name',
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _surnameCtrl,
                        hint: 'Last Name',
                        icon: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailCtrl,
                  hint: 'Email Address',
                  icon: Icons.email,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _phoneCtrl,
                  hint: 'Phone Number',
                  icon: Icons.phone,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _userCtrl,
                  hint: 'Username *',
                  icon: Icons.account_circle,
                ),
                const SizedBox(height: 16),

                _buildField(
                  controller: _passCtrl,
                  hint: 'Password *',
                  icon: Icons.lock,
                  obscure: _obscurePass,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _confirmPassCtrl,
                  hint: 'Confirm Password *',
                  icon: Icons.lock_outline,
                  obscure: _obscureConfirm,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'REGISTER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white38) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
      ),
    );
  }
}
