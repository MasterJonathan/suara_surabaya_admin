import 'package:suara_surabaya_admin/core/theme/app_colors.dart';
import 'package:suara_surabaya_admin/core/utils/constants.dart';
import 'package:suara_surabaya_admin/providers/kategori_provider.dart';
import 'package:suara_surabaya_admin/widgets/common/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KategoriPage extends StatefulWidget {
  // Diubah menjadi StatefulWidget
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Memicu rebuild untuk filter
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String selectedCollection = KATEGORI_INFOSS_COLLECTION;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Kategori Baru'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCollection,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kategori',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: KATEGORI_INFOSS_COLLECTION,
                          child: Text('Info SS'),
                        ),
                        DropdownMenuItem(
                          value: KATEGORI_KAWANSS_COLLECTION,
                          child: Text('Kawan SS'),
                        ),
                        DropdownMenuItem(
                          value: KATEGORI_NEWS_COLLECTION,
                          child: Text('News'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCollection = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final provider = context.read<KategoriProvider>();
                      await provider.addKategori(
                        selectedCollection,
                        nameController.text,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getCollectionDisplayName(String collectionName) {
    switch (collectionName) {
      case KATEGORI_INFOSS_COLLECTION:
        return 'Info SS';
      case KATEGORI_KAWANSS_COLLECTION:
        return 'Kawan SS';
      case KATEGORI_NEWS_COLLECTION:
        return 'News';
      default:
        return 'Tidak Diketahui';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomCard(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            child: Consumer<KategoriProvider>(
              builder: (context, provider, child) {
                if (provider.state == KategoriViewState.Busy &&
                    provider.allKategori.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return Center(child: Text('Error: ${provider.errorMessage}'));
                }

                final query = _searchController.text.toLowerCase();
                final filteredData =
                    query.isEmpty
                        ? provider.allKategori
                        : provider.allKategori
                            .where(
                              (k) =>
                                  k.namaKategori.toLowerCase().contains(query) ||
                                  k.jenis.toLowerCase().contains(query)
                                  ,
                            ) 
                            .toList();

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 250,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Search',
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Tambah Kategori'),
                          onPressed: () => _showAddDialog(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Expanded(
                      // --- PERUBAHAN DARI LISTVIEW KE DATATABLE ---
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Nama Kategori')),
                              DataColumn(label: Text('Jenis')),
                              DataColumn(label: Text('Aksi')),
                            ],
                            rows:
                                filteredData.map((kategori) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(kategori.namaKategori)),
                                      DataCell(
                                        Chip(
                                          label: Text(
                                            _getCollectionDisplayName(
                                              kategori.jenis,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          labelStyle: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                          ),
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                        ),
                                      ),
                                      DataCell(
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.error,
                                            ),
                                            onPressed: () async {
                                              // Tambahkan dialog konfirmasi
                                              final confirm = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                builder:
                                                    (ctx) => AlertDialog(
                                                      title: const Text(
                                                        'Konfirmasi Hapus',
                                                      ),
                                                      content: Text(
                                                        'Anda yakin ingin menghapus kategori "${kategori.namaKategori}" dari jenis "${_getCollectionDisplayName(kategori.jenis)}"?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop(false),
                                                          child: const Text(
                                                            'Batal',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop(true),
                                                          child: const Text(
                                                            'Hapus',
                                                            style: TextStyle(
                                                              color:
                                                                  AppColors
                                                                      .error,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                              if (confirm ?? false) {
                                                await context
                                                    .read<KategoriProvider>()
                                                    .deleteKategori(
                                                      kategori.jenis,
                                                      kategori.id,
                                                    );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
