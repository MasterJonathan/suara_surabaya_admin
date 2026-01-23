// import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
// import 'package:suara_surabaya_admin/models/dashboard/infoss/infoss_comment_model.dart';
// import 'package:suara_surabaya_admin/providers/chat_provider.dart';
// import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:timeago/timeago.dart' as timeago;

// class ChatManagementPage extends StatefulWidget {
//   const ChatManagementPage({super.key});

//   @override
//   State<ChatManagementPage> createState() => _ChatManagementPageState();
// }

// class _ChatManagementPageState extends State<ChatManagementPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd\nHH:mm:ss');

//   @override
//   void initState() {
//     super.initState();
//     timeago.setLocaleMessages('id', timeago.IdMessages());
//     _searchController.addListener(() {
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ChatProvider>(
//       builder: (context, provider, child) {
//         List<InfossCommentModel> filteredData;
//         final query = _searchController.text.toLowerCase();
//         final allData = provider.infossComments;

//         if (query.isEmpty) {
//           filteredData = allData;
//         } else {
//           filteredData = allData
//               .where((item) =>
//                   item.username.toLowerCase().contains(query) ||
//                   item.comment.toLowerCase().contains(query))
//               .toList();
//         }

        
//         return CustomCard(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
              
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: _buildSearchField(),
//               ),
//               const SizedBox(height: 20),
//               if (provider.state == ChatViewState.Busy && provider.infossComments.isEmpty)
//                 const Expanded(child: Center(child: CircularProgressIndicator()))
//               else if (provider.errorMessage != null)
//                 Expanded(child: Center(child: Text('Error: ${provider.errorMessage}', style: const TextStyle(color: AppColors.error))))
//               else
                
//                 Expanded(
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.vertical,
//                     child: SizedBox(
//                       width: double.infinity,
//                       child: SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: _buildDataTable(provider, filteredData),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSearchField() {
//     return SizedBox(
//       width: 250,
//       child: TextField(
//         controller: _searchController,
//         decoration: const InputDecoration(labelText: 'Search:', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
//       ),
//     );
//   }

//   Widget _buildDataTable(ChatProvider provider, List<InfossCommentModel> data) {
//     return DataTable(
//       columnSpacing: 20,
//       columns: const [
//         DataColumn(label: Text('Kontributor')),
//         DataColumn(label: Text('Chat')),
//         DataColumn(label: Text('Status')),
//         DataColumn(label: Text('Jenis\nStatus')),
//         DataColumn(label: Text('Waktu')),
//         DataColumn(label: Text('Tanggal\nPosting')),
//         DataColumn(label: Text('Aksi')),
//       ],
//       rows: data.map((item) {
//         final String timeAgo = timeago.format(item.uploadDate, locale: 'id');
//         bool isActive = !item.deleted;
//         String jenisStatus = isActive ? 'Aktif' : 'Dihapus';

//         return DataRow(cells: [
//           DataCell(
//             Text(item.username, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
//           ),
//           DataCell(
//             SizedBox(
//               width: 450,
//               child: Text(item.comment, maxLines: 3, overflow: TextOverflow.ellipsis),
//             ),
//           ),
//           DataCell(
//             Icon(
//               isActive ? Icons.check_circle : Icons.radio_button_unchecked,
//               color: isActive ? AppColors.success : AppColors.foreground.withOpacity(0.5),
//             ),
//           ),
//           DataCell(Text(jenisStatus)),
//           DataCell(Text(timeAgo)),
//           DataCell(Text(_dateFormatter.format(item.uploadDate))),
//           DataCell(
//             Row(
//               children: [
//                 _actionButton(
//                   icon: Icons.delete,
//                   color: AppColors.error,
//                   tooltip: 'Hapus Komentar',
//                   onPressed: () async {
//                     await provider.deleteComment(item.id);
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ]);
//       }).toList(),
//     );
//   }

//   Widget _actionButton({required IconData icon, required Color color, required String tooltip, VoidCallback? onPressed}) {
//     return SizedBox(
//       width: 32,
//       height: 32,
//       child: ElevatedButton(
//         onPressed: onPressed ?? () {},
//         style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), padding: EdgeInsets.zero),
//         child: Tooltip(message: tooltip, child: Icon(icon, size: 16)),
//       ),
//     );
//   }
// }