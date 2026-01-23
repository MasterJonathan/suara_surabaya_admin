import 'package:suara_surabaya_admin/providers/auth/authentication_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/kawanss/kawanss_provider.dart';
import 'package:suara_surabaya_admin/providers/kawanss_report_provider.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_management/user_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000), 
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: ListView(
              key: const PageStorageKey('overviewPage'),
              padding: const EdgeInsets.all(16), 
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildStatsSection(context),
                const SizedBox(height: 24),
                _buildChartsSection(context),
                const SizedBox(height: 24),
                
                
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authProvider = context.watch<AuthenticationProvider>();
    
    final userName = authProvider.user?.nama ?? 'Admin';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back! 👋', 
                  style: textTheme.titleMedium?.copyWith(color: AppColors.surface.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: textTheme.headlineMedium?.copyWith(color: AppColors.surface, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor your business performance and track key metrics',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.surface.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.dashboard_rounded, size: 32, color: AppColors.surface),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    
    final totalUsers = context.watch<UserProvider>().users.length;
    final totalKawanss = context.watch<KawanssProvider>().kawanssList.length;
    final totalKontributor = context.watch<KawanSSReportProvider>().kontributors.length;
    
    
    final numberFormat = NumberFormat.decimalPattern('id_ID');

    final stats = [
      {
        'icon': Icons.people_alt_rounded,
        'title': 'Total Users',
        'value': numberFormat.format(totalUsers),
        'change': '', 
        'color': const Color(0xFF6366F1), 
      },
      {
        'icon': Icons.rss_feed,
        'title': 'Total Kawan SS',
        'value': numberFormat.format(totalKawanss),
        'change': '',
        'color': const Color(0xFF10B981), 
      },
      {
        'icon': Icons.edit_note_rounded,
        'title': 'Total Kontributor',
        'value': numberFormat.format(totalKontributor),
        'change': '',
        'color': const Color(0xFFF59E0B), 
      },
      {
        'icon': Icons.article_rounded,
        'title': 'Total Berita',
        'value': '1,234', 
        'change': '',
        'color': const Color(0xFFEF4444), 
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            
            childAspectRatio: crossAxisCount > 1 ? 2.8 : 3.2, 
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(opacity: value, child: _buildStatCard(stats[index])),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: BoxDecoration(
        color: stat['color'],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: stat['color'].withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stat['icon'], color: Colors.white, size: 20),
                ),
                if (stat['change'] != '')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(stat['change'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['value'],
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'],
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildChartsSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: CustomCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue Analytics', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(height: 300, child: _buildEnhancedLineChart()),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: CustomCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Distribution', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(height: 300, child: _buildEnhancedPieChart()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
            return value.toInt() < months.length ? Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(months[value.toInt()])) : const Text('');
          })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 3), FlSpot(1, 4.5), FlSpot(2, 3.2), FlSpot(3, 5), FlSpot(4, 3.8), FlSpot(5, 4.2), FlSpot(6, 5.5)],
            isCurved: true,
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF6366F1).withValues(alpha: 0.3), const Color(0xFF8B5CF6).withValues(alpha: 0.0)])),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPieChart() {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(color: const Color(0xFF6366F1), value: 35, title: '35%', radius: 55, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: const Color(0xFF10B981), value: 25, title: '25%', radius: 55, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: const Color(0xFFF59E0B), value: 25, title: '25%', radius: 55, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: const Color(0xFFEF4444), value: 15, title: '15%', radius: 55, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}