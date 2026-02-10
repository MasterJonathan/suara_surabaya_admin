import 'package:flutter_bloc/flutter_bloc.dart';
import 'report_event.dart';
import 'report_state.dart';
import '../data/report_service.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportService reportService;

  ReportBloc({required this.reportService}) : super(ReportInitialState()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<LoadAnalyticsEvent>(_onLoadAnalytics);
    on<TriggerExportEvent>(_onExport);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoadingState());
    try {
      final dashboardData = await reportService.fetchMainDashboard();

      emit(
        ReportLoadedState(
          dashboardData: dashboardData,
          isAnalyticsLoading: true,
        ),
      );

      add(LoadAnalyticsEvent());
    } catch (e) {
      emit(ReportErrorState(e.toString()));
    }
  }

  Future<void> _onLoadAnalytics(
    LoadAnalyticsEvent event,
    Emitter<ReportState> emit,
  ) async {
    if (state is ReportLoadedState) {
      final currentState = state as ReportLoadedState;

      try {
        final analyticsData = await reportService.fetchAnalytics();

        emit(
          currentState.copyWith(
            analyticsData: analyticsData,
            isAnalyticsLoading: false,
          ),
        );
      } catch (e) {
        emit(currentState.copyWith(isAnalyticsLoading: false));
      }
    }
  }

  Future<void> _onExport(
    TriggerExportEvent event,
    Emitter<ReportState> emit,
  ) async {
    final lastState = state;

    try {
      final message = await reportService.exportToSheets();
      emit(ReportExportSuccessState(message));

      if (lastState is ReportLoadedState) {
        emit(lastState);
      }
    } catch (e) {
      emit(ReportErrorState("Export Gagal: ${e.toString()}"));
    }
  }
}
