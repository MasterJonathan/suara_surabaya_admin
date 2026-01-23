// lib/screens/dashboard/infoss/infoss_detail_page.dart

import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_comment_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/infoss_provider.dart';
import 'package:suara_surabaya_admin/widgets/comment_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InfossDetailPage extends StatelessWidget {
  final InfossModel infoss;

  const InfossDetailPage({super.key, required this.infoss});

  @override
  Widget build(BuildContext context) {
    final infossProvider = context.read<InfossProvider>();
    final DateFormat dateFormatter = DateFormat('dd MMMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text('Detail Info SS: ${infoss.judul}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN DETAIL POST ---
            _buildPostDetails(context),
            const SizedBox(height: 24),

            // --- BAGIAN KOMENTAR ---
            Text('Komentar', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            StreamBuilder<List<InfossCommentModel>>(
              stream: infossProvider.fetchCommentsForInfoss(infoss.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("ERORROR ${snapshot.error}");
                  return const Center(child: Text("Error memuat komentar"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada komentar."));
                }

                final comments = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    // Gunakan widget baru untuk setiap item komentar
                    return CommentItem(infossId: infoss.id, comment: comment);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostDetails(BuildContext context) {
    final DateFormat dateFormatter = DateFormat('dd MMMM yyyy, HH:mm');
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (infoss.gambar != null && infoss.gambar!.isNotEmpty)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Image.network(infoss.gambar!, fit: BoxFit.contain),
                ),
              ),
            const SizedBox(height: 16),
            Chip(label: Text(infoss.kategori)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  infoss.judul,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const Spacer(),
                const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(infoss.jumlahView.toString()),
                const SizedBox(width: 16),
                const Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(infoss.jumlahLike.toString()),
              ],
            ),
            const Divider(height: 24),
            Text(
              "Diposting pada: ${dateFormatter.format(infoss.uploadDate)}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (infoss.location != null && infoss.location!.isNotEmpty)
              Text(
                "Lokasi: ${infoss.location}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            Text(infoss.detail ?? "Tidak ada detail."),
          ],
        ),
      ),
    );
  }
}
