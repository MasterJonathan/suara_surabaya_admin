import 'package:flutter_bloc/flutter_bloc.dart';
import 'report_event.dart';
import 'report_state.dart';
import '../data/report_service.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportService reportService;

  ReportBloc({required this.reportService}) : super(ReportInitialState()) {
    on<LoadReportEvent>(_onLoadReport);
    on<RefreshReportEvent>(_onLoadReport);
  }

  Future<void> _onLoadReport(
    ReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoadingState());

    try {
      final data = await reportService.fetchReports();
      emit(ReportLoadedState(data));
    } catch (e) {
      final message = e.toString().replaceAll("Exception: ", "");
      emit(ReportErrorState(message));
    }
  }
}
