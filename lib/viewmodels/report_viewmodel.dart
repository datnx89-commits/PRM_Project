import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/report_summary_model.dart';
import '../data/providers.dart';
import '../data/repositories/report_repository.dart';

class ReportState {
  final DateTime fromDate;
  final DateTime toDate;
  final ReportSummary? summary;
  final bool isLoading;
  final String? errorMessage;

  ReportState({
    required this.fromDate,
    required this.toDate,
    this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  ReportState copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    ReportSummary? summary,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReportState(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ReportViewModel extends StateNotifier<ReportState> {
  final ReportRepository _reportRepository;

  ReportViewModel(this._reportRepository)
      : super(ReportState(
          fromDate: DateTime.now().subtract(const Duration(days: 30)),
          toDate: DateTime.now(),
        )) {
    loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true);
    try {
      final summary = await _reportRepository.getSummary(state.fromDate, state.toDate);
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tải báo cáo thống kê.',
      );
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    loadReport();
  }
}

final reportViewModelProvider =
    StateNotifierProvider<ReportViewModel, ReportState>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  return ReportViewModel(repo);
});
