import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'data/providers.dart';
import 'data/services/firebase_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/admin/admin_reports_screen.dart';
import 'views/customer/customer_home_screen.dart';
import 'views/staff/staff_bookings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await FirebaseService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SportsBookApp(),
    ),
  );
}

class SportsBookApp extends StatelessWidget {
  const SportsBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ thống đặt sân SportsBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    if (!authState.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = authState.user;
    if (user == null) {
      return const CustomerHomeScreen();
    }

    switch (user.role) {
      case UserRole.admin:
      case UserRole.superAdmin:
        return const AdminReportsScreen();
      case UserRole.owner:
      case UserRole.staff:
        return const StaffBookingsScreen();
      case UserRole.customer:
      default:
        return const CustomerHomeScreen();
    }
  }
}