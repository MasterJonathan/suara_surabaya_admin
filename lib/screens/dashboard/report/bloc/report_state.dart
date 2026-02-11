import '../../../../models/report_model.dart';

abstract class ReportState {}

class ReportInitialState extends ReportState {}

class ReportLoadingState extends ReportState {}

class ReportLoadedState extends ReportState {
  final DashboardData? dashboardData;
  final AnalyticsData? analyticsData;
  final bool isAnalyticsLoading;
  final InstagramProfile? instagramProfile;

  ReportLoadedState({
    this.dashboardData,
    this.analyticsData,
    this.isAnalyticsLoading = false,
    this.instagramProfile,
  });

  ReportLoadedState copyWith({
    DashboardData? dashboardData,
    AnalyticsData? analyticsData,
    InstagramProfile? instagramProfile,
    bool? isAnalyticsLoading,
  }) {
    return ReportLoadedState(
      dashboardData: dashboardData ?? this.dashboardData,
      analyticsData: analyticsData ?? this.analyticsData,
      isAnalyticsLoading: isAnalyticsLoading ?? this.isAnalyticsLoading,
      instagramProfile: instagramProfile ?? this.instagramProfile,
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
