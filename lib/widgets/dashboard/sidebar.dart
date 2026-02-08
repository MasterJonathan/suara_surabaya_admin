import 'package:suara_surabaya_admin/core/navigation/navigation_service.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/sidebar_menu_item.dart';
import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/widgets/dashboard/sidebar_clickable_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late final List<SidebarMenuItem> _menuItems;
  String? _currentlyExpandedParentKey;

  @override
  void initState() {
    super.initState();
    _menuItems = _buildMenuItems();
  }

  List<SidebarMenuItem> _buildMenuItems() {
    return [
      SidebarMenuItem(
        title: 'Overview',
        icon: Icons.dashboard_outlined,
        page: DashboardPage.overview,
      ),

      SidebarMenuItem(
        title: 'Manajemen Panggilan',
        icon: Icons.call,
        page: DashboardPage.videoCall,
      ),
      SidebarMenuItem(
        title: 'Simulator Panggilan (Dev)',
        icon: Icons.bug_report,
        page: DashboardPage.callSimulator,
      ),

      SidebarMenuItem(
        title: 'Info SS Management',
        icon: Icons.folder_shared_outlined,
        isExpanded: false,
        subItems: [
          SidebarMenuItem(
            title: '[BELUM] Tema Siaran',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.temaSiaran,
          ),
          SidebarMenuItem(
            title: '[OK] Banner Top',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.bannerTop,
          ),
          SidebarMenuItem(
            title: '[BELUM] Pop Up',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.popUp,
          ),
          SidebarMenuItem(
            title: '[BELUM] Info SS',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.infoSS,
          ),
          SidebarMenuItem(
            title: '[BELUM] Info SS Comment',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.infoSSComment,
          ),
        ],
      ),

      SidebarMenuItem(
        title: 'Kawan SS',
        icon: Icons.folder_open_outlined,
        isExpanded: false,
        subItems: [
          SidebarMenuItem(
            title: '[VIA USER] Kawan SS Management',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.kawanssManagement,
          ),
          SidebarMenuItem(
            title: '[OK] Kawan SS Post',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.kawanssPost,
          ),
          SidebarMenuItem(
            title: '[BELUM] Kawan SS Comment',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.kawanssComment,
          ),
          SidebarMenuItem(
            title: '[XX] Postingan Terlapor',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.postinganTerlapor,
          ),
        ],
      ),

      SidebarMenuItem(
        title: 'Berita',
        icon: Icons.article_outlined,
        isExpanded: false,
        subItems: [
          SidebarMenuItem(
            title: '[BELUM] Berita',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.berita,
          ),
          SidebarMenuItem(
            title: '[XX] Potret Netter',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.berita,
          ),
          SidebarMenuItem(
            title: '[XX] Video',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.berita,
          ),
          SidebarMenuItem(
            title: '[XX] Potret Kelana Kota',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.berita,
          ),
          SidebarMenuItem(
            title: '[XX] Podcast',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.berita,
          ),
        ],
      ),

      SidebarMenuItem(
        title: 'User Management',
        icon: Icons.people_alt_outlined,
        isExpanded: false,
        subItems: [
          SidebarMenuItem(
            title: '[OK] Change Password',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.changePassword,
          ),
          SidebarMenuItem(
            title: '[OK] Settings',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.settings,
          ),
          SidebarMenuItem(
            title: '[BELUM] User Account Management',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.usersAccountManagement,
          ),
          SidebarMenuItem(
            title: '[BELUM] Admin Management',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.adminManagement,
          ),
        ],
      ),

      SidebarMenuItem(
        title: 'Laporan & Analitik',
        icon: Icons.insights_outlined,
        page: DashboardPage.report,
      ),

      SidebarMenuItem(
        title: '[XX] Report Management',
        icon: Icons.flag_outlined,
        isExpanded: false,
        subItems: [
          SidebarMenuItem(
            title: 'Report SNA',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.report,
          ),
          SidebarMenuItem(
            title: 'Video Call',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.reportManagement,
          ),
          SidebarMenuItem(
            title: 'Audio Call',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.reportManagement,
          ),

          SidebarMenuItem(
            title: '[BELUM] Registrasi Kontributor',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.reportUserRegistration,
          ),
          SidebarMenuItem(
            title: '[BELUM] Posting Info SS',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.reportInfoSSPost,
          ),
          SidebarMenuItem(
            title: '[BELUM] Posting Kawan SS',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.reportKawanSSPost,
          ),
          SidebarMenuItem(
            title: 'Like Posting',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.reportManagement,
          ),
          SidebarMenuItem(
            title: 'View Posting',
            icon: Icons.radio_button_unchecked_outlined,
            page: DashboardPage.reportManagement,
          ),
        ],
      ),

      SidebarMenuItem(
        title: '[XX] Chat Management',
        icon: Icons.chat_bubble_outline,
        page: DashboardPage.chatManagement,
      ),
      SidebarMenuItem(
        title: '[OK] Kategori SS',
        icon: Icons.radio_button_unchecked_outlined,
        page: DashboardPage.kategoriss,
      ),

    ];
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<NavigationService>(context);

    // --- DAPATKAN HAK AKSES DARI AUTHPROVIDER ---
    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );
    final hakAkses = authProvider.user?.hakAkses ?? {};
    // -------------------------------------------

    final currentPage = navigationService.currentPage;

    bool isAnySubItemSelected(SidebarMenuItem parentItem) {
      if (parentItem.subItems == null) return false;
      return parentItem.subItems!.any((subItem) => subItem.page == currentPage);
    }

    return Container(
      width: 260,
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              // Menggunakan padding dari kode kedua untuk tampilan yang lebih rapi
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 8.0,
              ),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];

                // --- BAGIAN 1: LOGIKA UNTUK MENU DENGAN SUB-MENU ---
                // Logika ini berasal dari kode kedua untuk memfilter menu berdasarkan hak akses
                if (item.subItems != null && item.subItems!.isNotEmpty) {
                  // Filter sub-menu yang bisa diakses (hak akses 'read' atau 'write')
                  final accessibleSubItems =
                      item.subItems!.where((subItem) {
                        final pageName =
                            subItem.page.toString().split('.').last;
                        final accessLevel = hakAkses[pageName];
                        return accessLevel == 'read' || accessLevel == 'write';
                      }).toList();

                  // Jika tidak ada satupun sub-menu yang bisa diakses, sembunyikan menu utamanya
                  if (accessibleSubItems.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Buat objek menu baru dengan sub-menu yang sudah difilter untuk ditampilkan
                  final filteredParentItem = SidebarMenuItem(
                    title: item.title,
                    icon: item.icon,
                    subItems: accessibleSubItems,
                    isExpanded: item.isExpanded,
                  );

                  // Logika pengecekan status aktif/terpilih dari kode pertama
                  bool isParentOfSelectedChild = isAnySubItemSelected(
                    filteredParentItem,
                  );
                  bool isParentEffectivelyActive =
                      filteredParentItem.isExpanded || isParentOfSelectedChild;

                  // Container dan Theme diambil dari kode kedua (dengan margin & border radius)
                  // namun properti ExpansionTile di dalamnya diambil dari kode pertama yang lebih lengkap
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2.0),
                    decoration: BoxDecoration(
                      color:
                          isParentEffectivelyActive
                              ? AppColors.primary
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          vertical: 0.0,
                          horizontal: 16.0,
                        ),
                        key: PageStorageKey<String>(filteredParentItem.title),
                        iconColor: AppColors.surface,
                        collapsedIconColor:
                            isParentOfSelectedChild
                                ? AppColors.surface
                                : AppColors.foreground,
                        initiallyExpanded: isParentEffectivelyActive,
                        // Logika onExpansionChanged lengkap dari kode pertama
                        onExpansionChanged: (bool expanding) {
                          setState(() {
                            if (expanding) {
                              for (var menuItem in _menuItems) {
                                if (menuItem.title != item.title &&
                                    menuItem.subItems != null) {
                                  menuItem.isExpanded = false;
                                }
                              }
                              // State diubah pada 'item' asli, bukan 'filteredParentItem'
                              item.isExpanded = true;
                              _currentlyExpandedParentKey = item.title;
                            } else {
                              item.isExpanded = false;
                              if (_currentlyExpandedParentKey == item.title) {
                                _currentlyExpandedParentKey = null;
                              }
                            }
                          });
                        },
                        // Tampilan leading dan title dari kode pertama
                        leading: Icon(
                          filteredParentItem.icon,
                          color:
                              isParentEffectivelyActive
                                  ? AppColors.surface
                                  : AppColors.foreground,
                          size: 20,
                        ),
                        title: Text(
                          filteredParentItem.title,
                          style: TextStyle(
                            color:
                                isParentEffectivelyActive
                                    ? AppColors.surface
                                    : AppColors.foreground,
                            fontWeight:
                                isParentEffectivelyActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        // Render children (sub-menu) menggunakan item yang sudah difilter
                        children:
                            filteredParentItem.subItems!
                                .map(
                                  (subItem) => SidebarClickableItem(
                                    icon: subItem.icon,
                                    title: subItem.title,
                                    isSelected: subItem.page == currentPage,
                                    onTap: () {
                                      if (subItem.page != null) {
                                        navigationService.navigateTo(
                                          subItem.page!,
                                        );
                                      }
                                    },
                                    level: 1,
                                    sidebarBackgroundColor: AppColors.surface,
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  );
                }
                // --- BAGIAN 2: LOGIKA UNTUK MENU TUNGGAL (TANPA SUB-MENU) ---
                else {
                  // Cek hak akses untuk menu tunggal dari kode kedua
                  final pageName = item.page.toString().split('.').last;
                  final accessLevel = hakAkses[pageName];

                  // Tampilkan hanya jika punya hak akses
                  if (accessLevel == 'read' || accessLevel == 'write') {
                    bool isDirectlySelected = item.page == currentPage;
                    // Menggunakan Container dari kode kedua untuk konsistensi margin
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2.0),
                      // Widget SidebarClickableItem lengkap dari kode pertama
                      child: SidebarClickableItem(
                        icon: item.icon,
                        title: item.title,
                        isSelected: isDirectlySelected,
                        onTap: () {
                          if (item.page != null) {
                            navigationService.navigateTo(item.page!);
                          }
                        },
                        level: 0,
                        sidebarBackgroundColor: AppColors.surface,
                      ),
                    );
                  }
                }

                // Jika tidak ada kondisi yang terpenuhi (misal, menu tunggal tanpa hak akses)
                // maka jangan tampilkan apa-apa.
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
