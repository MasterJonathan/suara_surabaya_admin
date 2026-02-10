class DashboardData {
  final UserStats userStats;
  final PostStats postStats;
  final List<TopContent> topContent;
  final IntegrationStatus integrations; // Tambahan untuk status integrasi
  final InstagramProfile? instagramProfile; // Opsional, jika ada data IG

  DashboardData({
    required this.userStats,
    required this.postStats,
    required this.topContent,
    required this.integrations,
    required this.instagramProfile,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      userStats: UserStats.fromJson(json['users'] ?? {}),
      postStats: PostStats.fromJson(json['posts'] ?? {}),
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
      // Handle jika data dikirim sebagai int atau double
      growthPercentage: (json['growth_percentage'] ?? 0).toDouble(),
      comparisonText: json['comparison_text'] ?? "",
    );
  }
}

class PostStats {
  final int total;
  final int new30Days;

  PostStats({required this.total, required this.new30Days});

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      total: json['total'] ?? 0,
      new30Days: json['new_30_days'] ?? 0,
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
      id: json['id'] ?? '',
      // Backend Python bisa mengirim 'judul' atau 'title'
      title: json['judul'] ?? json['title'] ?? "No Title",
      // Backend Python mengirim 'jumlahView' atau 'views'
      views: json['jumlahView'] ?? json['views'] ?? 0,
      category: json['kategori'] ?? json['category'] ?? "Umum",
      author: json['author'] ?? "Admin", // Default jika null
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

// Model tambahan untuk status Integrasi (Sheets & Analytics)
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

// Model terpisah untuk Data Analytics Detail (jika dipanggil via endpoint /analytics)
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
    final data = json['data'] ?? json;

    return AnalyticsData(
      activeUsersNow: data['active_users_now'] ?? 0,
      pageViewsToday: data['page_views_today'] ?? 0,
      connected: json['status'] == 'success' || data['status'] == 'connected',
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
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      biography: json['biography'] ?? '',
      followersCount: json['followers_count'] ?? 0,
      followsCount: json['follows_count'] ?? 0,
      mediaCount: json['media_count'] ?? 0,
      profilePictureUrl: json['profile_picture_url'] ?? '',
    );
  }
}
