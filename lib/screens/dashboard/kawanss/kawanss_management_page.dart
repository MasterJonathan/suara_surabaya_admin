// import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
// import 'package:suara_surabaya_admin/models/dashboard/kawanss/kawanss_model.dart';
// import 'package:suara_surabaya_admin/providers/dashboard/kawanss/kawanss_provider.dart';
// import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class KawanssManagementPage extends StatefulWidget {
//   const KawanssManagementPage({super.key});

//   @override
//   State<KawanssManagementPage> createState() =>
//       _KawanssManagementPageState();
// }

// class _KawanssManagementPageState extends State<KawanssManagementPage> {
//   late List<KawanssModel> _filteredData;
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     final provider = Provider.of<KawanssProvider>(context, listen: false);
//     _filteredData = provider.kawanssList;

//     _searchController.addListener(() {
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _performFilter(String query, List<KawanssModel> allData) {
//     if (query.isEmpty) {
//       _filteredData = allData;
//     } else {
//       _filteredData =
//           allData
//               .where(
//                 (item) =>
//                     (item.accountName?.toLowerCase() ?? '').contains(
//                       query.toLowerCase(),
//                     ) ||
//                     (item.title?.toLowerCase() ?? '').contains(
//                       query.toLowerCase(),
//                     ) ||
//                     (item.lokasi?.toLowerCase() ?? '').contains(
//                       query.toLowerCase(),
//                     ),
//               )
//               .toList();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<KawanssProvider>(
//       builder: (context, provider, child) {
//         _performFilter(_searchController.text, provider.kawanssList);

//         // --- STRUKTUR BUILD DIPERBAIKI UNTUK MENGATASI OVERFLOW ---
//         return Column(
//           key: const PageStorageKey('kontributorManagementPage'),
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Expanded membuat area konten mengisi sisa ruang vertikal
//             Expanded(
//               // SingleChildScrollView memungkinkan seluruh konten di dalamnya untuk di-scroll
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: CustomCard(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Align(
//                             alignment: Alignment.centerRight,
//                             child: _buildSearchField(),
//                           ),
//                           _buildActionButtons(),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       if (provider.state == KawanssViewState.Busy &&
//                           provider.kawanssList.isEmpty)
//                         const Center(child: CircularProgressIndicator())
//                       else if (provider.errorMessage != null)
//                         Center(
//                           child: Text(
//                             'Error: ${provider.errorMessage}',
//                             style: const TextStyle(color: AppColors.error),
//                           ),
//                         )
//                       else
//                         SizedBox(
//                           width: double.infinity,
//                           child: SingleChildScrollView(
//                             scrollDirection: Axis.horizontal,
//                             child: _buildDataTable(provider),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//         // -----------------------------------------------------------
//       },
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         ElevatedButton.icon(
//           icon: const Icon(Icons.add, size: 16),
//           label: const Text('Tambah Kontributor'),
//           onPressed: () {
//             /* TODO: Implement Add/Edit Dialog */
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchField() {
//     return SizedBox(
//       width: 250,
//       child: TextField(
//         controller: _searchController,
//         decoration: const InputDecoration(
//           labelText: 'Search',
//           contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         ),
//       ),
//     );
//   }

//   Widget _buildDataTable(KawanssProvider provider) {
//     return DataTable(
//       columns: const [
//         DataColumn(label: Text('Nama\nKontributor')),
//         // DataColumn(label: Text('Email')),
//         // DataColumn(label: Text('Alamat')),
//         // DataColumn(label: Text('Telepon')),
//         // DataColumn(label: Text('Status')),
//         // DataColumn(label: Text('Jenis\nStatus')),
//         // DataColumn(label: Text('Tanggal\nPosting')),
//         DataColumn(label: Text('Aksi')),
//       ],
//       rows:
//           _filteredData.map((item) {
//             return DataRow(
//               cells: [
//                 DataCell(Text(item.accountName ?? '-')),
//                 // DataCell(Text(item.email ?? '-')),
//                 // DataCell(
//                 //   SizedBox(
//                 //     width: 200,
//                 //     child: Text(
//                 //       item.lokasi?? '-',
//                 //       maxLines: 3,
//                 //       overflow: TextOverflow.ellipsis,
//                 //     ),
//                 //   ),
//                 // ),
//                 // DataCell(Text(item.telepon ?? '-')),
//                 // DataCell(
//                 //   Icon(
//                 //     isActive
//                 //         ? Icons.check_circle
//                 //         : Icons.radio_button_unchecked,
//                 //     color:
//                 //         isActive
//                 //             ? AppColors.success
//                 //             : AppColors.foreground.withOpacity(0.5),
//                 //   ),
//                 // ),
//                 // DataCell(Text(isActive ? 'Aktif' : 'Belum Diaktifkan')),
//                 // DataCell(Text(_dateFormatter.format(item.uploadDate))),
//                 DataCell(
//                   Row(
//                     children: [
//                       _actionButton(
//                         icon: Icons.edit,
//                         color: AppColors.primary,
//                         tooltip: 'Edit',
//                       ),
//                       const SizedBox(width: 4),
//                       _actionButton(
//                         icon: Icons.search,
//                         color: AppColors.primary,
//                         tooltip: 'View',
//                       ),
//                       const SizedBox(width: 4),
//                       _actionButton(
//                         icon: Icons.email,
//                         color: AppColors.primary,
//                         tooltip: 'Send Email',
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           }).toList(),
//     );
//   }

//   Widget _actionButton({
//     required IconData icon,
//     required Color color,
//     required String tooltip,
//     VoidCallback? onPressed,
//   }) {
//     return SizedBox(
//       width: 32,
//       height: 32,
//       child: ElevatedButton(
//         onPressed: onPressed ?? () {},
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           foregroundColor: AppColors.surface,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//           padding: EdgeInsets.zero,
//         ),
//         child: Tooltip(message: tooltip, child: Icon(icon, size: 16)),
//       ),
//     );
//   }
// }
