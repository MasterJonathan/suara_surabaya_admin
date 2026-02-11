// lib\models\report_model.dart

class DashboardData {
  final UserStats userStats;
  final PostStats postStats;
  final List<TopContent> topContent;
  final IntegrationStatus integrations;
  final InstagramProfile? instagramProfile;

  DashboardData({
    required this.userStats,
    required this.postStats,
    required this.topContent,
    required this.integrations,
    this.instagramProfile,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Ambil data users dari json['users']
    final usersJson = json['users'] ?? {};
    // Ambil data posts dari json['posts']
    final postsJson = json['posts'] ?? {};

    return DashboardData(
      userStats: UserStats.fromJson(usersJson),
      postStats: PostStats(
        total: usersJson['total_post'] ?? postsJson['total'] ?? 0,
        new30Days: postsJson['new_30_days'] ?? 0,
        totalKawanSS:
            usersJson['total_post_kawanss'] ?? postsJson['total_kawn_ss'] ?? 0,
        new30DaysKawanSS: postsJson['new_30_days_kawanss'] ?? 0,
      ),
      topContent:
          (json['top_content'] as List? ?? [])
              .map((e) => TopContent.fromJson(e))
              .toList(),
      integrations: IntegrationStatus.fromJson(json['integrations'] ?? {}),
      instagramProfile:
          json['instagram_profile'] != null
              ? InstagramProfile.fromJson(json['instagram_profile'])
              : null,
    );
  }
}

class InstagramProfile {
  final String id;
  final String username;
  final String name;
  final String biography;
  final int followersCount;
  final int followsCount;
  final int mediaCount;
  final String profilePictureUrl;

  InstagramProfile({
    required this.id,
    required this.username,
    required this.name,
    required this.biography,
    required this.followersCount,
    required this.followsCount,
    required this.mediaCount,
    required this.profilePictureUrl,
  });

  factory InstagramProfile.fromJson(Map<String, dynamic> json) {
    return InstagramProfile(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      biography: json['biography'] ?? '',
      followersCount: json['followers_count'] ?? "Data tidak bisa di ambil",
      followsCount: json['follows_count'] ?? "Data tidak bisa di ambil",
      mediaCount: json['media_count'] ?? "Data tidak bisa di ambil",
      profilePictureUrl: json['profile_picture_url'] ?? '',
    );
  }
}

class UserStats {
  final int total;
  final int newThisMonth;
  final double growthPercentage;
  final String comparisonText;

  UserStats({
    required this.total,
    required this.newThisMonth,
    required this.growthPercentage,
    required this.comparisonText,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: json['total'] ?? 0,
      newThisMonth: json['new_this_month'] ?? 0,
      growthPercentage: (json['growth_percentage'] ?? 0).toDouble(),
      comparisonText: json['comparison_text'] ?? "",
    );
  }
}

class PostStats {
  final int total;
  final int new30Days;
  final int totalKawanSS;
  final int new30DaysKawanSS;

  PostStats({
    required this.total,
    required this.new30Days,
    required this.totalKawanSS,
    required this.new30DaysKawanSS,
  });

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      total: json['total'] ?? "Tidak ada Data",
      new30Days: json['new_30_days'] ?? "Tidak ada Data",
      totalKawanSS: json['total_kawan_ss'] ?? "Tidak ada Data",
      new30DaysKawanSS: json['new_30_days_kawan_ss'] ?? "Tidak ada Data",
    );
  }
}

class TopContent {
  final String id;
  final String title;
  final int views;
  final String category;
  final String author;
  final String image;
  final int likes;
  final int comments;
  final DateTime? uploadDate;

  TopContent({
    required this.id,
    required this.title,
    required this.views,
    required this.category,
    required this.author,
    required this.image,
    required this.likes,
    required this.comments,
    this.uploadDate,
  });

  factory TopContent.fromJson(Map<String, dynamic> json) {
    return TopContent(
      id: json['id']?.toString() ?? '',
      title: json['judul'] ?? json['title'] ?? "No Title",
      views: json['jumlahView'] ?? json['views'] ?? 0,
      category: json['kategori'] ?? json['category'] ?? "Umum",
      author: json['author'] ?? "Admin",
      image: json['gambar'] ?? '',
      likes: json['jumlahLike'] ?? 0,
      comments: json['jumlahComment'] ?? 0,
      uploadDate:
          json['uploadDate'] != null
              ? DateTime.tryParse(json['uploadDate'])
              : null,
    );
  }
}

class IntegrationStatus {
  final bool sheetsConnected;
  final bool analyticsConnected;
  final int activeUsersNow;

  IntegrationStatus({
    required this.sheetsConnected,
    required this.analyticsConnected,
    required this.activeUsersNow,
  });

  factory IntegrationStatus.fromJson(Map<String, dynamic> json) {
    final sheets = json['google_sheets'] ?? {};
    final analytics = json['google_analytics'] ?? {};

    return IntegrationStatus(
      sheetsConnected: sheets['status'] == 'connected',
      analyticsConnected: analytics['status'] == 'connected',
      activeUsersNow: analytics['active_users_now'] ?? 0,
    );
  }
}

class AnalyticsData {
  final int activeUsersNow;
  final int pageViewsToday;
  final bool connected;

  AnalyticsData({
    required this.activeUsersNow,
    required this.pageViewsToday,
    required this.connected,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    // Menangani struktur nested 'data' atau flat
    final data = json['data'] ?? json;

    return AnalyticsData(
      activeUsersNow: data['active_users_now'] ?? 0,
      pageViewsToday: data['page_views_today'] ?? 0,
      connected:
          json['status'] == 'success' ||
          data['status'] == 'connected' ||
          json['status'] == 'connected',
    );
  }
}
