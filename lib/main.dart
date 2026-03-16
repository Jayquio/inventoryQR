import 'package:flutter/material.dart';
import 'data/notification_service.dart';
import 'screens/common/login_screen.dart';
import 'screens/common/qr_scanner_screen.dart';
import 'screens/common/qr_generator_screen.dart';
import 'screens/common/settings_screen.dart';
import 'screens/common/user_qr_screen.dart';
import 'screens/staff/manage_requests_screen.dart';
import 'screens/admin/manage_instruments_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'data/app_config_service.dart';
import 'screens/admin/transaction_logs_screen.dart';
import 'screens/admin/notification_center_screen.dart';
import 'screens/staff/staff_dashboard.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/student/submit_request_screen.dart';
import 'screens/student/view_instruments_screen.dart';
import 'screens/staff/log_maintenance_screen.dart';
import 'screens/staff/handle_returns_screen.dart';
import 'screens/admin/generate_reports_screen.dart';
import 'screens/student/track_status_screen.dart';
import 'screens/common/layout_preview_screen.dart';
import 'data/theme_service.dart';
import 'core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfigService.instance.loadAndApplyBaseUrl();
  await NotificationService.instance.loadFromStorage();
  NotificationService.instance.connectWebSocket();
  final prefs = await SharedPreferences.getInstance();
  final autoRefresh = prefs.getBool('notifications_auto_refresh') ?? true;
  if (autoRefresh) {
    NotificationService.instance.startAutoRefresh();
  } else {
    NotificationService.instance.stopAutoRefresh();
  }
  await ThemeService.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'MedLab Inventory',
          theme: () {
            final scheme = ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              brightness: Brightness.light,
            ).copyWith(
              secondary: AppTheme.secondaryColor,
              primary: AppTheme.primaryColor,
              background: AppTheme.backgroundLight,
              surface: Colors.white,
            );
            return ThemeData(
              useMaterial3: true,
              colorScheme: scheme,
              scaffoldBackgroundColor: AppTheme.backgroundLight,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
              ),
              chipTheme: ChipThemeData(
                backgroundColor: AppTheme.wisteria.withValues(alpha: 0.2),
                selectedColor: AppTheme.secondaryColor.withValues(alpha: 0.2),
                side: BorderSide.none,
                labelStyle: const TextStyle(color: Colors.black87),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }(),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: ThemeService.instance.mode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/login',
          routes: {
            '/login': (context) => LoginScreen(),
            '/admin_dashboard': (context) => const AdminDashboard(),
            '/staff_dashboard': (context) => const StaffDashboard(),
            '/student_dashboard': (context) => const StudentDashboard(),
            '/manage_requests': (context) => const ManageRequestsScreen(),
            '/manage_instruments': (context) => const ManageInstrumentsScreen(),
            '/user_management': (context) => const UserManagementScreen(),
            '/transaction_logs': (context) => const TransactionLogsScreen(),
            '/notification_center': (context) => const NotificationCenterScreen(),
            '/submit_request': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String?;
              return SubmitRequestScreen(preSelectedInstrument: args);
            },
            '/view_instruments': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String?;
              return ViewInstrumentsScreen(userRole: args ?? 'Student');
            },
            '/log_maintenance': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String?;
              return LogMaintenanceScreen(preSelectedInstrument: args);
            },
            '/handle_returns': (context) => const HandleReturnsScreen(),
            '/generate_reports': (context) => const GenerateReportsScreen(),
            '/track_status': (context) => const TrackStatusScreen(),
            '/layout_preview': (context) => const LayoutPreviewScreen(),
            '/qr_scanner': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String?;
              return QrScannerScreen(userRole: args ?? 'Student');
            },
            '/qr_generator': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              String role = 'Student';
              String? pre;
              if (args is String) {
                role = args;
              } else if (args is Map) {
                role = (args['userRole'] as String?) ?? role;
                pre = args['preSelectedInstrument'] as String?;
              }
              return QrGeneratorScreen(userRole: role, preSelectedInstrument: pre);
            },
            '/user_qr': (context) {
              return const UserQrScreen();
            },
            '/settings': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String?;
              return SettingsScreen(userRole: args ?? 'Student');
            },
          },
        );
      },
    );
  }
}
