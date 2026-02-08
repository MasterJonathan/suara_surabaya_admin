import 'package:suara_surabaya_admin/core/auth/auth_service.dart';
import 'package:suara_surabaya_admin/core/navigation/app_routes.dart';
import 'package:suara_surabaya_admin/core/navigation/navigation_service.dart';
import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/core/theme/app_theme.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/call/call_history_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/call/call_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/banner_provider.dart';
import 'package:suara_surabaya_admin/providers/chat_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/report/call_activity_report_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/report/infoss_post_report_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/infoss_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/popup_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/tema_siaran_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/report/kawanss_post_report_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/report/kawanss_registration_report_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_management/admin_provider.dart';
import 'package:suara_surabaya_admin/providers/kategori_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/kawanss/kawanss_post_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/kawanss/kawanss_provider.dart';
import 'package:suara_surabaya_admin/providers/kawanss_report_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/berita/berita_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_management/settings_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_management/user_provider.dart';
import 'package:suara_surabaya_admin/screens/auth/login_screen.dart';
import 'package:suara_surabaya_admin/screens/auth/register_screen.dart';
import 'package:suara_surabaya_admin/screens/dashboard/dashboard_layout.dart';
import 'package:suara_surabaya_admin/screens/dashboard/report/report_provider.dart';
import 'package:suara_surabaya_admin/screens/unknown_screen.dart';
import 'package:suara_surabaya_admin/core/services/call_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<CallService>(create: (_) => CallService()),

        ChangeNotifierProvider<NavigationService>(
          create: (_) => NavigationService(),
        ),

        ChangeNotifierProvider<AuthenticationProvider>(
          create:
              (context) => AuthenticationProvider(
                authService: context.read<AuthService>(),
                firestoreService: context.read<FirestoreService>(),
              ),
        ),

        // 2. Audio / Video Call & History
        ChangeNotifierProvider<CallProvider>(
          create: (context) {
            // Ambil ID admin yang sedang login untuk mendengarkan panggilan
            final authProvider = context.read<AuthenticationProvider>();
            final adminId = authProvider.user?.id ?? '';
            return CallProvider(
              callService: context.read<CallService>(),
              currentUserId:
                  adminId, // 'currentUserId' adalah nama parameter di provider kita
            );
          },
        ),
        ChangeNotifierProvider<CallHistoryProvider>(
          create:
              (context) => CallHistoryProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),

        // 3. Management Tampilan (Tema, Banner, PopUp)
        ChangeNotifierProvider<TemaSiaranProvider>(
          create:
              (context) => TemaSiaranProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<BannerProvider>(
          create:
              (context) => BannerProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<PopUpProvider>(
          create:
              (context) => PopUpProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),

        // 4. Info SS Management & Comment
        ChangeNotifierProvider<InfossProvider>(
          create:
              (context) => InfossProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),

        // 5. Post Kawan SS & Comment
        ChangeNotifierProvider<KawanssPostProvider>(
          create:
              (context) => KawanssPostProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<KawanssProvider>(
          create:
              (context) => KawanssProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),

        // 6. Berita Web Management
        ChangeNotifierProvider<BeritaProvider>(
          create:
              (context) => BeritaProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),

        // 7. Settings & Account Management (Ganti Pass, Settings, Users, Admin)
        ChangeNotifierProvider<SettingsProvider>(
          create:
              (context) => SettingsProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<UserProvider>(
          create:
              (context) => UserProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create:
              (context) => AdminProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),

        // 8. Laporan & Analitik (Reports)
        // --- TAMBAHKAN PROVIDER BARU DI SINI ---
        ChangeNotifierProvider<ReportProvider>(
          create:
              (context) => ReportProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<CallActivityReportProvider>(
          create:
              (context) => CallActivityReportProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<KawanSSRegistrationReportProvider>(
          create:
              (context) => KawanSSRegistrationReportProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<InfossPostReportProvider>(
          create:
              (context) => InfossPostReportProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<KawanssPostReportProvider>(
          create:
              (context) => KawanssPostReportProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
        ChangeNotifierProvider<KawanSSReportProvider>(
          create:
              (context) => KawanSSReportProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),

        // 9. Chat Management
        // ChangeNotifierProvider<ChatProvider>(
        //   create:
        //       (context) => ChatProvider(
        //         firestoreService: context.read<FirestoreService>(),
        //       ),
        // ),

        // 10. Kategori Management
        ChangeNotifierProvider<KategoriProvider>(
          create:
              (context) => KategoriProvider(
                firestoreService: context.read<FirestoreService>(),
              ),
        ),
      ],

      builder: (context, child) {
        final authStatus = context.select(
          (AuthenticationProvider p) => p.status,
        );

        return MaterialApp(
          title: 'Admin Dashboard',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,

          home: _buildHome(authStatus),

          routes: {
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.register: (context) => const RegisterScreen(),
          },
          onUnknownRoute:
              (settings) =>
                  MaterialPageRoute(builder: (_) => const UnknownScreen()),
        );
      },
    );
  }

  Widget _buildHome(AuthStatus status) {
    switch (status) {
      case AuthStatus.Authenticated:
        return const DashboardLayout();
      case AuthStatus.Unauthenticated:
        return const LoginScreen();
      case AuthStatus.Uninitialized:
      case AuthStatus.Authenticating:
      default:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
