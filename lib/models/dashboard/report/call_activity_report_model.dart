class CallHourlyReport {
  final DateTime date;
  // Map<Jam (0-23), Jumlah Panggilan>
  final Map<int, int> hourlyCounts; 
  final int totalVoiceCalls;
  final int totalVideoCalls;

  CallHourlyReport({
    required this.date,
    required this.hourlyCounts,
    required this.totalVoiceCalls,
    required this.totalVideoCalls,
  });

  int get dailyTotal => hourlyCounts.values.fold(0, (sum, count) => sum + count);
}