import 'package:suara_surabaya_admin/core/services/firestore_service.dart';
import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/providers/dashboard/user_profile_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:suara_surabaya_admin/models/dashboard/user_activity/activity_model.dart';

class UserActivityPage extends StatelessWidget {
  final String kontributorId;

  const UserActivityPage({
    super.key,
    required this.kontributorId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProfileProvider(
        firestoreService: context.read<FirestoreService>(),
        kontributorId: kontributorId,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface, // Pastikan background konsisten
        appBar: AppBar(
          title: const Text('Detail Aktivitas Pengguna'),
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.foreground,
        ),
        body: Consumer<UserProfileProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.userProfile == null) {
              return _buildEmptyState(context, 'User tidak ditemukan.', Icons.person_off);
            }

            return _buildProfileLayout(context, provider);
          },
        ),
      ),
    );
  }

  Widget _buildProfileLayout(BuildContext context, UserProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Kiri: Sidebar Profil (Fixed Width)
          SizedBox(
            width: 320,
            child: _ProfileSidebar(provider: provider),
          ),
          const SizedBox(width: 24),
          // Kolom Kanan: Konten Tab (Flexible)
          Expanded(
            child: _MainContent(provider: provider),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}

// --- SIDEBAR PROFIL ---
class _ProfileSidebar extends StatelessWidget {
  final UserProfileProvider provider;
  const _ProfileSidebar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final profile = provider.userProfile!;
    
    return Column(
      children: [
        // Kartu Identitas Utama
        CustomCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 4),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: (profile.photoURL != null && profile.photoURL!.isNotEmpty)
                      ? NetworkImage(profile.photoURL!)
                      : null,
                  child: (profile.photoURL == null || profile.photoURL!.isEmpty)
                      ? Text(
                          profile.nama.isNotEmpty ? profile.nama[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile.nama,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                profile.role,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Statistik Grid
              Row(
                children: [
                  Expanded(child: _buildStatBox(context, 'Kontribusi', profile.jumlahKontributor.toString(), Icons.article_outlined)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatBox(context, 'Likes', profile.jumlahLike.toString(), Icons.thumb_up_outlined)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatBox(context, 'Comments', profile.jumlahComment.toString(), Icons.comment_outlined)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatBox(context, 'Shares', profile.jumlahShare.toString(), Icons.share_outlined)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Kartu Informasi Kontak
        CustomCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informasi Kontak', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 32),
              _buildContactTile(Icons.email_outlined, 'Email', profile.email),
              _buildContactTile(Icons.phone_outlined, 'Telepon', profile.nomorHp ?? '-'),
              _buildContactTile(Icons.location_on_outlined, 'Alamat', profile.alamat ?? '-'),
              _buildContactTile(Icons.calendar_today_outlined, 'Bergabung', DateFormat('dd MMM yyyy').format(profile.joinDate)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- KONTEN UTAMA (TABS) ---
class _MainContent extends StatelessWidget {
  final UserProfileProvider provider;
  const _MainContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Custom Tab Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(vertical: 12),
              tabs: const [
                Tab(text: 'Riwayat Posting', icon: Icon(Icons.article_outlined)),
                Tab(text: 'Log Aktivitas', icon: Icon(Icons.history)),
                Tab(text: 'Riwayat Panggilan', icon: Icon(Icons.phone_in_talk_outlined)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Tab Views
          SizedBox(
            height: 800, // Fixed height untuk scroll di dalam tab
            child: TabBarView(
              children: [
                _buildPostingTab(context),
                _buildAktivitasTab(context),
                _buildCallHistoryTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String message, IconData icon) {
    return CustomCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostingTab(BuildContext context) {
    if (provider.posts.isEmpty) return _buildEmptyTab('Belum ada postingan.', Icons.post_add);
    
    return ListView.builder(
      itemCount: provider.posts.length,
      itemBuilder: (context, index) {
        final post = provider.posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.gambar != null && post.gambar!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(post.gambar!, fit: BoxFit.cover),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text('Postingan', style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(post.uploadDate, locale: 'id'),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.deskripsi ?? post.title ?? 'Tanpa Judul',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${post.jumlahLike}'),
                        const SizedBox(width: 16),
                        Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${post.jumlahComment}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAktivitasTab(BuildContext context) {
    if (provider.activities.isEmpty) return _buildEmptyTab('Belum ada aktivitas.', Icons.history_toggle_off);
    
    return CustomCard(
      padding: const EdgeInsets.all(0),
      child: ListView.separated(
        itemCount: provider.activities.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = provider.activities[index];
          
          IconData icon;
          Color color;
          switch (activity.type) {
            case ActivityType.like: 
              icon = Icons.favorite; 
              color = Colors.pink; 
              break;
            case ActivityType.call: 
              icon = Icons.call; 
              color = Colors.green; 
              break;
            case ActivityType.posting: 
              icon = Icons.article; 
              color = Colors.blue; 
              break;
            default: 
              icon = Icons.circle; 
              color = Colors.grey;
          }

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(activity.description, style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              DateFormat('dd MMM yyyy, HH:mm').format(activity.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Text(
              timeago.format(activity.timestamp, locale: 'id'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallHistoryTab(BuildContext context) {
    if (provider.callHistory.isEmpty) return _buildEmptyTab('Belum ada riwayat panggilan.', Icons.phone_missed);
    
    final DateFormat timeFormatter = DateFormat('HH:mm');
    final DateFormat dateFormatter = DateFormat('dd MMM yyyy');

    return CustomCard(
      padding: const EdgeInsets.all(0),
      child: ListView.separated(
        itemCount: provider.callHistory.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final call = provider.callHistory[index];
          final isVideo = call.isVideoCall;
          final durationStr = '${call.duration.inMinutes}m ${call.duration.inSeconds % 60}s';

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isVideo ? Colors.blue : Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isVideo ? Icons.videocam : Icons.phone,
                color: isVideo ? Colors.blue : Colors.green,
              ),
            ),
            title: Text(
              isVideo ? 'Video Call' : 'Audio Call',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  timeFormatter.format(call.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  durationStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(dateFormatter.format(call.createdAt), style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(timeago.format(call.createdAt, locale: 'id'), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          );
        },
      ),
    );
  }
}