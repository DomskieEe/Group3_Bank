import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math' as math;
import '../services/data_service.dart';
import '../services/app_state.dart';

// ─── Animated 3D Custom Logo Widget ─────────────────────────────────────────

class AnimatedSnapWalletLogo extends StatefulWidget {
  final double size;
  const AnimatedSnapWalletLogo({super.key, this.size = 110});

  @override
  State<AnimatedSnapWalletLogo> createState() => _AnimatedSnapWalletLogoState();
}

class _AnimatedSnapWalletLogoState extends State<AnimatedSnapWalletLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Continuous smooth oscillation for 3D rotation simulation
        final double animValue = _controller.value;

        // Simulating 3D perspective tilt using Matrix4 rotation & scaling
        final double angleX = math.sin(animValue * 2 * math.pi) * 0.15;
        final double angleY = math.cos(animValue * 2 * math.pi) * 0.20;
        final double scale = 1.0 + (math.sin(animValue * math.pi) * 0.05);

        final Matrix4 transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(angleX)
          ..rotateY(angleY)
          ..scale(scale);

        return Center(
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size * 0.22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD32F2F).withOpacity(0.4),
                    blurRadius: 18 + (animValue * 10),
                    spreadRadius: 2,
                    offset: Offset(math.sin(animValue * math.pi) * 6, 10),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: SnapWallet3DLogoPainter(progress: animValue),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SnapWallet3DLogoPainter extends CustomPainter {
  final double progress;
  SnapWallet3DLogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw 3D Multi-Layer Shadow / Extrusion effect behind the base card
    final depthOffset = 4.0 + (math.sin(progress * math.pi) * 2.0);
    final shadowRect = Rect.fromLTWH(depthOffset, depthOffset + 4, w, h);
    final shadowRRect = RRect.fromRectAndRadius(shadowRect, Radius.circular(w * 0.22));
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF5A0000).withOpacity(0.6);
    canvas.drawRRect(shadowRRect, shadowPaint);

    // 2. Draw solid red rounded background card with gradient shading for 3D depth
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgRRect = RRect.fromRectAndRadius(bgRect, Radius.circular(w * 0.22));

    final Gradient bgGradient = LinearGradient(
      colors: const [Color(0xFFFF5252), Color(0xFFB71C1C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = bgGradient.createShader(bgRect);
    canvas.drawRRect(bgRRect, bgPaint);

    // 3. Draw crisp glowing white border frame
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..color = const Color(0xFFFFFFFF).withOpacity(0.9);
    canvas.drawRRect(bgRRect, borderPaint);

    // 4. Draw Inner 3D Motion Wallet Elements in Pure White
    final whitePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    // Top-middle streak with slight dynamic floating translation
    final floatOffset = math.sin(progress * math.pi * 2) * 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.17, (h * 0.44) + floatOffset, w * 0.22, h * 0.08),
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
  bool shouldRepaint(covariant SnapWallet3DLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
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
    final result = await DataService.login(email, password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isSuccess) {
      AppState.instance.currentUser = result.user!;
      final hasPin = await DataService.hasSecurityPin();
      if (!mounted) return;
      if (!hasPin) {
        final pinCreated = await Navigator.pushNamed(context, '/createPin');
        if (pinCreated != true || !mounted) return;
        Navigator.pushReplacementNamed(context, '/shell');
        return;
      }
      Navigator.pushReplacementNamed(context, '/enterPin');
    } else {
      _showSnack(_loginErrorMessage(result.errorCode));
    }
  }

  String _loginErrorMessage(String? code) {
    switch (code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'network-request-failed':
      case 'network-error':
      case 'unavailable':
        return 'Unable to reach Firebase. Check your internet connection, disable VPN/private DNS, then try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case 'profile-not-found':
        return 'Your account exists but its database profile is missing. Please contact support.';
      default:
        return 'Login failed. Please try again.';
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
                const SizedBox(height: 30),
                // Animated 3D Custom Logo Widget Integration
                const AnimatedSnapWalletLogo(size: 120),
                const SizedBox(height: 24),
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
                const SizedBox(height: 36),
                // Email Address
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
                const SizedBox(height: 4),
                // Forgot Password link
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
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => _showSnack('Sign in first to create or reset your security PIN.'),
                  child: const Text(
                    'Create or reset PIN',
                    style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
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

// ─── Create PIN Screen ──────────────────────────────────────────────────────

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key, this.returnToCaller = true});

  final bool returnToCaller;

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _loading = false;

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final pin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.isEmpty || confirmPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both PIN fields.')),
      );
      return;
    }

    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must contain 4 to 6 digits.')),
      );
      return;
    }

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match. Please try again.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await DataService.saveSecurityPin(pin);
      if (!mounted) return;
      setState(() => _loading = false);
      if (widget.returnToCaller) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, '/enterPin');
      }
    } on StateError {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before creating a PIN.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Create Security PIN', style: TextStyle(color: Colors.white)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff000000), Color(0xff1f0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Set Your PIN',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a secure PIN to protect your transactions and app access.',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _newPinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Enter 4-6 digit PIN',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Confirm PIN',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _savePin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SAVE PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Enter PIN Screen ───────────────────────────────────────────────────────

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final _pinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _obscurePin = true;
  bool _loading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your valid security PIN.')),
      );
      return;
    }

    setState(() => _loading = true);

    final isPinCorrect = await DataService.verifySecurityPin(pin);
    if (!mounted) return;
    setState(() => _loading = false);

    if (isPinCorrect) {
      Navigator.pushReplacementNamed(context, '/shell');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN. Please try again.')),
      );
    }
  }

  Future<void> _biometricUnlock() async {
    final enabled = await DataService.getBiometrics();
    if (!enabled) {
      _showBiometricMessage('Enable biometric login in Settings first.');
      return;
    }

    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      if (!supported || !canCheck || available.isEmpty) {
        _showBiometricMessage('Fingerprint or face unlock is not set up on this device.');
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Snap Wallet',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!mounted || !authenticated) return;
      Navigator.pushReplacementNamed(context, '/shell');
    } on LocalAuthException catch (error) {
      _showBiometricMessage('Biometric authentication unavailable: ${error.code.name}.');
    }
  }

  void _showBiometricMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                // Animated 3D Logo on Enter PIN screen
                const AnimatedSnapWalletLogo(size: 100),
                const SizedBox(height: 24),
                const Text(
                  'Enter Your PIN',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enter your security PIN to unlock your wallet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Security PIN',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgotPin'),
                    child: const Text(
                      'Forgot PIN?',
                      style: TextStyle(color: Color(0xFFD32F2F)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _biometricUnlock,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.fingerprint, color: Colors.white70),
                  label: const Text(
                    'Unlock with Biometrics',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('UNLOCK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Forgot PIN Screen ──────────────────────────────────────────────────────

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your registered email.')),
      );
      return;
    }

    if (!DataService.isCurrentUserEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the email of the signed-in account.')),
      );
      return;
    }

    setState(() => _loading = true);
    await DataService.clearSecurityPin();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/createPin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Forgot PIN', style: TextStyle(color: Colors.white)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff000000), Color(0xff1f0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Reset Your PIN',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your email address associated with Snap Wallet to receive PIN recovery instructions.',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _resetPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SUBMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
