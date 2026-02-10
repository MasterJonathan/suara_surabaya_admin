abstract class ReportState {}

class ReportInitialState extends ReportState {}

class ReportLoadingState extends ReportState {}

class ReportLoadedState extends ReportState {
  final dynamic data;

  ReportLoadedState(this.data);
}

class ReportErrorState extends ReportState {
  final String errorMessage;

  ReportErrorState(this.errorMessage);
}
