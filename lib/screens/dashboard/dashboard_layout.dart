import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/screens/dashboard/call/call_history_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/infoss/infoss_comment_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/kawanss/kawanss_comment_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/report_data/call_activity_report_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/report_data/infoss_post_report_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/report_data/kawanss_post_report_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/user_management/admin_access_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/call/admin_call_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/berita/berita_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/chat_management_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/infoss/banner_top_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/infoss/infoss_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/infoss/popup_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/infoss/tema_siaran_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/kategori_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/kawanss/kawanss_management_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/kawanss/kawanss_post_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/report/report_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/report_data/kawanss_registration_report_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/overview_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/profile_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/user_management/change_password_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/user_management/settings_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/user_management/general_users_page.dart';
import 'package:suara_surabaya_admin/screens/dashboard/call/call_simulator_page.dart';
import 'package:suara_surabaya_admin/widgets/dashboard/app_bar_actions.dart';
import 'package:suara_surabaya_admin/widgets/dashboard/sidebar.dart';
import 'package:suara_surabaya_admin/core/navigation/navigation_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({super.key});

  Widget _getPage(DashboardPage page) {
    switch (page) {
      case DashboardPage.overview:
        return const OverviewPage();
      case DashboardPage.profile:
        return const ProfilePage();

      case DashboardPage.videoCall:
        return const AdminCallPage();
      case DashboardPage.callHistory:
        return const CallHistoryPage();
      case DashboardPage.callSimulator:
        return const CallSimulatorPage();

      case DashboardPage.temaSiaran:
        return const TemaSiaranPage();
      case DashboardPage.bannerTop:
        return const BannerTopPage();
      case DashboardPage.popUp:
        return const PopUpPage();
      case DashboardPage.infoSS:
        return const InfossPage();
      case DashboardPage.infoSSComment:
        return const InfossCommentPage();


      case DashboardPage.kawanssPost:
        return const KawanssPostPage();
      case DashboardPage.kawanssComment:
        return const KawanssCommentPage();

      case DashboardPage.berita:
        return const BeritaPage();

      case DashboardPage.changePassword:
        return const ChangePasswordPage();
      case DashboardPage.settings:
        return const SettingsPage();
      case DashboardPage.usersAccountManagement:
        return const GeneralUserPage();
      case DashboardPage.adminManagement:
        return const AdminAccessPage();


      case DashboardPage.reportCall:
        return const CallActivityReportPage();
      case DashboardPage.reportUserRegistration:
        return const KawanSSRegistrationReportPage();
      case DashboardPage.reportInfoSSPost:
        return const InfossPostReportPage();
      case DashboardPage.reportKawanSSPost:
        return const KawanssPostReportPage();


      // case DashboardPage.chatManagement:
      //   return const ChatManagementPage();
      case DashboardPage.kategoriss:
        return const KategoriPage();


      default:
        return const OverviewPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<NavigationService>(context);
    final authProvider = context.watch<AuthenticationProvider>();
    final hakAkses = authProvider.user?.hakAkses ?? {};

    DashboardPage pageToDisplay = navigationService.currentPage;
    String pageNameToDisplay = pageToDisplay.toString().split('.').last;

    // Cek apakah pengguna punya akses ke halaman yang sedang dipilih
    final accessLevel = hakAkses[pageNameToDisplay];
    if (accessLevel != 'read' && accessLevel != 'write') {
      // Jika tidak punya akses, cari halaman pertama yang BISA diakses
      final accessiblePages = DashboardPage.values.where((page) {
        final pageName = page.toString().split('.').last;
        final access = hakAkses[pageName];
        return access == 'read' || access == 'write';
      });

      if (accessiblePages.isNotEmpty) {
        // Jika ada halaman yang bisa diakses, arahkan ke sana
        pageToDisplay = accessiblePages.first;
      } else {
        // Jika tidak ada halaman yang bisa diakses sama sekali
        // Tampilkan halaman "Tidak Punya Akses"
        return Scaffold(
          appBar: AppBar(title: const Text('Akses Ditolak')),
          body: const Center(
            child: Text(
              'Anda tidak memiliki izin untuk mengakses halaman mana pun.',
            ),
          ),
        );
      }
    }

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(_getPageTitle(pageToDisplay)),
                  actions: const [AppBarActions()],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _getPage(navigationService.currentPage),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(DashboardPage page) {
    switch (page) {
      // Halaman-halaman baru berdasarkan daftar Anda
      case DashboardPage.overview:
        return 'Overview';

      // Di dalam _getPageTitle
      case DashboardPage.videoCall:
        return 'Audio / Video Call';
      case DashboardPage.callHistory:
        return 'Audio / Video Call History';


      case DashboardPage.temaSiaran:
        return 'Tema Siaran Management';
      case DashboardPage.bannerTop:
        return 'Banner Top Management';
      case DashboardPage.popUp:
        return 'PopUp';
      case DashboardPage.infoSS:
        return 'Info SS Management';
      case DashboardPage.infoSSComment:
        return 'Info SS Comment';

    
      case DashboardPage.kawanssPost:
        return 'Post Kawan SS'; // Atau 'Kontributor Post' jika itu halamannya
      case DashboardPage.kawanssComment:
        return 'Kawan SS Comment';


      case DashboardPage.berita:
        return 'Berita Web Management';


      case DashboardPage.changePassword:
        return 'Ganti Password'; 
      case DashboardPage.settings:
        return 'Website Settings';
      case DashboardPage.usersAccountManagement:
        return 'User Account Management';
      case DashboardPage.adminManagement:
        return 'Admin Management';
      

      case DashboardPage.socialnetworkanalysis:
        return 'Laporan & Analitik';
      case DashboardPage.reportCall:
        return 'Report Audio / Video Call';
      case DashboardPage.reportUserRegistration:
        return 'Report User Registration';
      case DashboardPage.reportInfoSSPost:
        return 'Report Post Info SS';
      case DashboardPage.reportKawanSSPost:
        return 'Report Post Kawan SS';


      case DashboardPage.chatManagement:
        return 'Chat Management';


      case DashboardPage.kategoriss:
        return 'Kategori Management';


      // Default jika ada case yang terlewat
      default:
        return 'Dashboard';
    }
  }
}
