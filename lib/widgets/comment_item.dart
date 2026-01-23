import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_comment_model.dart';
import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_reply_model.dart';
import 'package:suara_surabaya_admin/providers/dashboard/infoss/infoss_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class CommentItem extends StatelessWidget {
  final String infossId;
  final InfossCommentModel comment;

  const CommentItem({required this.infossId, required this.comment});

  @override
  Widget build(BuildContext context) {
    final infossProvider = context.read<InfossProvider>();
    final DateFormat dateFormatter = DateFormat('dd MMMM yyyy, HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tampilkan Komentar Induk
          ListTile(
            leading: CircleAvatar(
              backgroundImage: comment.photoURL != null && comment.photoURL!.isNotEmpty
                  ? NetworkImage(comment.photoURL!)
                  : null,
              child: comment.photoURL == null || comment.photoURL!.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(comment.comment),
            trailing: Text(
              dateFormatter.format(comment.uploadDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // Tampilkan Balasan di bawahnya
          if (comment.jumlahReplies > 0)
            Padding(
              padding: const EdgeInsets.only(left: 56.0, top: 8.0), // Indentasi untuk balasan
              child: StreamBuilder<List<InfossReplyModel>>(
                stream: infossProvider.fetchRepliesForComment(infossId, comment.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 20, child: LinearProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("Gagal memuat balasan.", style: TextStyle(color: Colors.red));
                  }
                  final replies = snapshot.data!;
                  return Column(
                    children: replies.map((reply) {
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16, // Lebih kecil
                          backgroundImage: reply.photoURL != null && reply.photoURL!.isNotEmpty
                              ? NetworkImage(reply.photoURL!)
                              : null,
                          child: reply.photoURL == null || reply.photoURL!.isEmpty
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                        title: Text(reply.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(reply.comment),
                        trailing: Text(
                          dateFormatter.format(reply.uploadDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}