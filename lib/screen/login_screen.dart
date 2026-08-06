import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/data_service.dart';
import '../services/app_state.dart';

// ─── Custom Logo Painter ────────────────────────────────────────────────────

class SnapWalletLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw solid red rounded background card
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgRRect = RRect.fromRectAndRadius(bgRect, Radius.circular(w * 0.22));

    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFD32F2F);
    canvas.drawRRect(bgRRect, bgPaint);

    // 2. Draw crisp white border frame matching reference layout
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(bgRRect, borderPaint);

    // 3. Draw the Exact Motion Wallet Icon matching the reference image in Pure White
    final whitePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    // Top-middle streak
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.17, h * 0.44, w * 0.22, h * 0.08),
        Radius.circular(w * 0.04),
      ),
      whitePaint,
    );

    // Bottom long streak
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.17, h * 0.60, w * 0.32, h * 0.08),
        Radius.circular(w * 0.04),
      ),
      whitePaint,
    );

    // Main Wallet Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.38, w * 0.38, h * 0.35),
        Radius.circular(w * 0.06),
      ),
      whitePaint,
    );

    // Wallet Flap / Open Card top angle element
    final flapPath = Path();
    flapPath.moveTo(w * 0.31, h * 0.38);
    flapPath.lineTo(w * 0.63, h * 0.38);
    flapPath.lineTo(w * 0.58, h * 0.24);
    flapPath.lineTo(w * 0.28, h * 0.31);
    flapPath.close();
    canvas.drawPath(flapPath, whitePaint);

    // Wallet Clasp / Button patch on the right edge
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.61, h * 0.50, w * 0.14, h * 0.12),
        Radius.circular(w * 0.03),
      ),
      whitePaint,
    );

    // Negative space punch-out / dot inside the clasp
    final redDotPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(w * 0.68, h * 0.56),
      w * 0.025,
      redDotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Login Screen ───────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _userController.text.trim();
    final password = _passController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter your email and password.');
      return;
    }
    setState(() => _loading = true);
    final user = await DataService.login(email, password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (user != null) {
      AppState.instance.currentUser = user;
      Navigator.pushReplacementNamed(context, '/shell');
    } else {
      _showSnack('Invalid username or password.');
    }
  }

  Future<void> _biometricLogin() async {
    final biometricsEnabled = await DataService.getBiometrics();
    if (!biometricsEnabled) {
      _showSnack('Biometric login is not enabled. Enable it in Settings.');
      return;
    }
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        _showSnack('Biometrics not available on this device.');
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Snap Wallet',
        biometricOnly: true,
      );
      if (authenticated) {
        if (!mounted) return;
        final user = await DataService.restoreSession();
        if (!mounted) return;
        if (user != null) {
          AppState.instance.currentUser = user;
          Navigator.pushReplacementNamed(context, '/shell');
        } else {
          _showSnack('Sign in with email first before using biometrics.');
        }
      }
    } catch (e) {
      _showSnack('Biometric authentication failed.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff000000), Color(0xff1f0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Custom Logo Painter
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: SnapWalletLogoPainter(),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Snap Wallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your way to financial freedom',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 48),
                // Username
                _buildField(
                  controller: _userController,
                  hint: 'Email Address',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                // Password
                _buildField(
                  controller: _passController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 12),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot'),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color(0xFFD32F2F)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
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
                      'LOGIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Biometric button
                OutlinedButton.icon(
                  onPressed: _biometricLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.fingerprint, color: Colors.white70),
                  label: const Text(
                    'Login with Biometrics',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 40),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.white54),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
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