import 'package:flutter/material.dart';
import 'screen/onboarding_screen.dart';
import 'screen/login_screen.dart';
import 'screen/register_screen.dart';
import 'screen/forgot_password_screen.dart';
import 'screen/main_shell.dart';
import 'services/data_service.dart';
import 'services/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataService.init();
  final isDark = await DataService.getDarkMode();
  AppState.instance.themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  final seenOnboarding = await DataService.getOnboardingSeen();
  final savedUser = await DataService.restoreSession();
  AppState.instance.currentUser = savedUser;
  runApp(
    BankingApp(
      showOnboarding: !seenOnboarding,
      startLoggedIn: savedUser != null,
    ),
  );
}

class BankingApp extends StatelessWidget {
  final bool showOnboarding;
  final bool startLoggedIn;
  const BankingApp({
    super.key,
    this.showOnboarding = true,
    this.startLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Snap Wallet',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFD32F2F),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD32F2F),
              secondary: Color(0xFFD32F2F),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: Colors.white,
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFD32F2F),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD32F2F),
              secondary: Color(0xFFD32F2F),
              surface: Color(0xff1a1a1a),
            ),
            scaffoldBackgroundColor: const Color(0xff0b0b0b),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xff1a1a1a),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: const Color(0xff1e1e1e),
            fontFamily: 'Roboto',
          ),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/forgot': (_) => const ForgotPasswordScreen(),
            '/shell': (_) => const MainShell(),
          },
          home: showOnboarding
              ? const OnboardingScreen()
              : startLoggedIn
              ? const MainShell()
              : const LoginScreen(),
        );
      },
    );
  }
}
