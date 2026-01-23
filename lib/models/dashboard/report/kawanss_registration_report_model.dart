// lib/models/report_model.dart

class HourlyRegistrationReport {
  final DateTime date;
  // Map di mana key adalah jam (0-23), dan value adalah jumlah registrasi
  final Map<int, int> hourlyCounts;

  HourlyRegistrationReport({
    required this.date,
    required this.hourlyCounts,
  });
}