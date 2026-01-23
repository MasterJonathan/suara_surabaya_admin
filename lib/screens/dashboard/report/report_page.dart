import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_model.dart';
import 'package:suara_surabaya_admin/screens/dashboard/report/report_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Future<void> _initFuture;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initFuture = Provider.of<ReportProvider>(context, listen: false).init();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _toBeginningOfSentenceCase(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Menginisialisasi Laporan..."),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Terjadi kesalahan saat inisialisasi: ${snapshot.error}"),
            );
          }

          _animationController.forward();
          return Consumer<ReportProvider>(
            builder: (context, reportProvider, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  key: const PageStorageKey('reportPage'),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                  children: [
                    _buildHeader(Theme.of(context).textTheme),
                    const SizedBox(height: 32),
                    _buildStatsGrid(reportProvider),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTopPosts(Theme.of(context).textTheme, reportProvider),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 2,
                          child: _buildAnalyticsCard(Theme.of(context).textTheme, reportProvider),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildTrafficChartCard(Theme.of(context).textTheme, reportProvider),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan & Analitik',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pantau performa dan statistik platform Anda secara komprehensif.',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ReportProvider provider) {
    if (provider.isStatsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.statsErrorMessage != null) {
      return Center(child: Text(provider.statsErrorMessage!));
    }

    final stats = provider.monthlyStats ??
        {'totalUsers': 0, 'newUsers': 0, 'newUsersChange': 0.0, 'totalPosts': 0, 'newPosts': 0};
    final numberFormat = NumberFormat.decimalPattern('id_ID');
    final double newUsersChange = (stats['newUsersChange'] as num).toDouble();

    final statsData = [
      {'icon': Icons.people_alt_rounded, 'title': 'Total Pengguna', 'value': numberFormat.format(stats['totalUsers']), 'change': null},
      {'icon': Icons.person_add_rounded, 'title': 'Pendaftar Baru (30 Hari)', 'value': numberFormat.format(stats['newUsers']), 'change': newUsersChange},
      {'icon': Icons.article_rounded, 'title': 'Total Postingan', 'value': numberFormat.format(stats['totalPosts']), 'change': null},
      {'icon': Icons.new_releases_rounded, 'title': 'Postingan Baru (30 Hari)', 'value': numberFormat.format(stats['newPosts']), 'change': null},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.6,
      ),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        final data = statsData[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 150)),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: _buildEnhancedStatCard(
                icon: data['icon'] as IconData,
                title: data['title'] as String,
                value: data['value'] as String,
                change: data['change'] as double?,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedStatCard({required IconData icon, required String title, required String value, double? change}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: CustomCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: change >= 0 ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          change >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: change >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${change.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: change >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPosts(TextTheme textTheme, ReportProvider provider) {
    if (provider.isStatsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '10 Postingan Info SS Terpopuler',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                Colors.grey.shade100,
              ),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
              dataRowMaxHeight: 60,
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Expanded(child: Text('Judul Postingan'))),
                DataColumn(label: Text('Views'), numeric: true),
              ],
              rows: provider.topPosts.asMap().entries.map((entry) {
                int index = entry.key;
                InfossModel post = entry.value;
                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return AppColors.primary.withValues(alpha: 0.05);
                      }
                      return null;
                    },
                  ),
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRankColor(index),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 250,
                        child: Text(
                          post.judul,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          NumberFormat.compact().format(post.jumlahView),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFD4AF37); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _buildAnalyticsCard(TextTheme textTheme, ReportProvider provider) {
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.integration_instructions_rounded,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Integrasi & Ekspor',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSheetsActionButton(context),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.analytics_outlined,
            label: 'Buka Google Analytics',
            colors: [const Color(0xFFF9AB00), const Color(0xFFF4B400)],
            onPressed: () {
              const analyticsUrl = 'https://analytics.google.com/';
              _launchURL(analyticsUrl);
              FirebaseAnalytics.instance.logEvent(name: 'open_google_analytics', parameters: {'url': analyticsUrl});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSheetsActionButton(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    const sheetUrl = 'https://docs.google.com/spreadsheets/d/1F2obOikLOn92ewLwLlPhmVdhAW19EO15CcOZG_rtOWc';

    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'open':
            _launchURL(sheetUrl);
            break;
          case 'export_posts':
            final success = await provider.exportPostsToSheet();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(provider.exportPostsMessage ?? "Terjadi kesalahan."),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ));
            }
            break;
          case 'export_users':
            final success = await provider.exportUsersToSheet();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(provider.exportUsersMessage ?? "Terjadi kesalahan."),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ));
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'open',
          child: ListTile(
            leading: Icon(Icons.open_in_new),
            title: Text('Buka di Sheets'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'export_posts',
          enabled: !provider.isExportingPosts,
          child: ListTile(
            leading: provider.isExportingPosts
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.article_outlined),
            title: const Text('Export Data Postingan'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'export_users',
          enabled: !provider.isExportingUsers,
          child: ListTile(
            leading: provider.isExportingUsers
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.people_alt_outlined),
            title: const Text('Export Data Pengguna'),
          ),
        ),
      ],
      child: _buildActionButton(
        icon: Icons.table_chart_outlined,
        label: 'Aksi Google Sheets',
        colors: [const Color(0xFF188038), const Color(0xFF34A853)],
        onPressed: null,
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak bisa membuka $url')),
        );
      }
    }
  }

  Widget _buildActionButton({required IconData icon, required String label, required List<Color> colors, VoidCallback? onPressed}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficChartCard(TextTheme textTheme, ReportProvider provider) {
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    Text(
                      provider.trafficChartTitle,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TrafficType>(
                          value: provider.selectedTrafficType,
                          items: const [
                            DropdownMenuItem(value: TrafficType.AllViews, child: Text("Semua Kunjungan")),
                            DropdownMenuItem(value: TrafficType.Posts, child: Text("Postingan")),
                            DropdownMenuItem(value: TrafficType.NewUsers, child: Text("Pengguna Baru")),
                          ],
                          onChanged: provider.isTrafficLoading
                              ? null
                              : (type) {
                            if (type != null) {
                              provider.fetchTrafficReport(provider.selectedTimeRange, type: type, startDate: _startDate, endDate: _endDate);
                            }
                          },
                          style: textTheme.bodyMedium,
                          focusColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTimeRangeFilters(provider),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: provider.isTrafficLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.trafficData.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.data_usage_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada data traffic untuk rentang ini.",
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildBarChart(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeFilters(ReportProvider provider) {
    return Wrap(
      spacing: 8.0,
      children: [
        ...TrafficTimeRange.values.where((range) => range != TrafficTimeRange.Custom).map((range) {
          final isSelected = provider.selectedTimeRange == range;
          return FilterChip(
            label: Text(
              _toBeginningOfSentenceCase(range.name),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: isSelected,
            onSelected: provider.isTrafficLoading
                ? null
                : (bool selected) {
              if (selected) {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                provider.fetchTrafficReport(range);
              }
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            showCheckmark: false,
          );
        }).toList(),
        _buildCustomDateRangePicker(provider),
      ],
    );
  }

  Widget _buildCustomDateRangePicker(ReportProvider provider) {
    final startDateStr = _startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : 'Pilih Tanggal Mulai';
    final endDateStr = _endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'Pilih Tanggal Akhir';
    final isCustomSelected = provider.selectedTimeRange == TrafficTimeRange.Custom;

    return ActionChip(
      avatar: Icon(Icons.calendar_today_rounded, size: 18, color: isCustomSelected ? Colors.white : AppColors.foreground),
      label: Text(
        isCustomSelected ? '$startDateStr - $endDateStr' : 'Rentang Kustom',
        style: TextStyle(
          color: isCustomSelected ? Colors.white : AppColors.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: provider.isTrafficLoading
          ? null
          : () async {
        final pickedRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
          builder: (context, child) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 800.0,
                  maxHeight: 600.0,
                ),
                child: Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              ),
            );
          },
        );
        if (pickedRange != null) {
          setState(() {
            _startDate = pickedRange.start;
            _endDate = pickedRange.end;
          });
          provider.fetchTrafficReport(TrafficTimeRange.Custom, startDate: _startDate, endDate: _endDate);
        }
      },
      backgroundColor: isCustomSelected ? AppColors.primary : Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isCustomSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildBarChart(ReportProvider provider) {
    double maxY = 0;
    if (provider.trafficData.isNotEmpty) {
      maxY = provider.trafficData.reduce((a, b) => a > b ? a : b) * 1.2;
    }
    if (maxY < 5) maxY = 5;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String tooltipText;
              switch (provider.selectedTrafficType) {
                case TrafficType.NewUsers:
                  tooltipText = '${rod.toY.toInt()} pengguna baru';
                  break;
                case TrafficType.Posts:
                  tooltipText = '${rod.toY.toInt()} postingan baru';
                  break;
                default:
                  tooltipText = '${rod.toY.toInt()} kunjungan';
              }
              return BarTooltipItem(
                tooltipText,
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= provider.trafficLabels.length) {
                  return const Text('');
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    provider.trafficLabels[index],
                    style: TextStyle(
                      color: AppColors.foreground.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              reservedSize: 28,
              interval: provider.selectedTimeRange == TrafficTimeRange.Bulanan ? 3 : 1,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: provider.trafficData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(150),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}