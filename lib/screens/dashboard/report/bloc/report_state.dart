import '../../../../models/report_model.dart';

abstract class ReportState {}

class ReportInitialState extends ReportState {}

class ReportLoadingState extends ReportState {}

class ReportLoadedState extends ReportState {
  final DashboardData? dashboardData;
  final AnalyticsData? analyticsData;
  final bool isAnalyticsLoading;

  ReportLoadedState({
    this.dashboardData,
    this.analyticsData,
    this.isAnalyticsLoading = false,
  });

  ReportLoadedState copyWith({
    DashboardData? dashboardData,
    AnalyticsData? analyticsData,
    bool? isAnalyticsLoading,
  }) {
    return ReportLoadedState(
      dashboardData: dashboardData ?? this.dashboardData,
      analyticsData: analyticsData ?? this.analyticsData,
      isAnalyticsLoading: isAnalyticsLoading ?? this.isAnalyticsLoading,
    );
  }
}

class ReportErrorState extends ReportState {
  final String message;
  ReportErrorState(this.message);
}

class ReportExportSuccessState extends ReportState {
  final String message;
  ReportExportSuccessState(this.message);
}
