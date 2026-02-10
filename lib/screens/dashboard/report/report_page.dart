import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/report_bloc.dart';
import 'bloc/report_event.dart';
import 'bloc/report_state.dart';
import 'data/report_service.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Inisialisasi Bloc & Service
    // Service di-instansiasi di sini (Dependency Injection root untuk UI ini)
    return BlocProvider(
      create:
          (context) => ReportBloc(reportService: ReportService())
            ..add(LoadReportEvent()), // Langsung load data saat halaman dibuka
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Laporan SNA"),
          actions: [
            // Tombol Refresh manual
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      context.read<ReportBloc>().add(RefreshReportEvent());
                    },
                  ),
            ),
          ],
        ),
        body: const ReportView(),
      ),
    );
  }
}

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. BlocBuilder mendengarkan perubahan State
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state is ReportLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ReportLoadedState) {
          final data = state.data;

          // Contoh menampilkan data JSON mentah atau List
          // Sesuaikan dengan UI Report Anda yang sebenarnya
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReportBloc>().add(RefreshReportEvent());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Data Laporan:",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                // Tampilkan data debug dulu untuk memastikan koneksi
                Text(data.toString()),
              ],
            ),
          );
        } else if (state is ReportErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 10),
                Text(
                  "Terjadi Kesalahan",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<ReportBloc>().add(RefreshReportEvent());
                  },
                  child: const Text("Coba Lagi"),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text("Tidak ada data"));
      },
    );
  }
}
