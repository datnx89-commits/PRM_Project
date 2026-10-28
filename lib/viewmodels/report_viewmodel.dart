import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../data/models/report_summary_model.dart';
import '../data/providers.dart';
import '../data/repositories/report_repository.dart';
import 'auth_viewmodel.dart';

class ReportState {
  final DateTime fromDate;
  final DateTime toDate;
  final ReportSummary? summary;
  final bool isLoading;
  final String? errorMessage;
  final String? ownerId;
  final bool isOwnerView;

  ReportState({
    required this.fromDate,
    required this.toDate,
    this.summary,
    this.isLoading = false,
    this.errorMessage,
    this.ownerId,
    this.isOwnerView = false,
  });

  ReportState copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    ReportSummary? summary,
    bool? isLoading,
    String? errorMessage,
    String? ownerId,
    bool? isOwnerView,
  }) {
    return ReportState(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      ownerId: ownerId ?? this.ownerId,
      isOwnerView: isOwnerView ?? this.isOwnerView,
    );
  }
}

class ReportViewModel extends StateNotifier<ReportState> {
  final ReportRepository _reportRepository;

  ReportViewModel(this._reportRepository, {String? initialOwnerId, bool isOwner = false})
      : super(ReportState(
          fromDate: DateTime.now().subtract(const Duration(days: 30)),
          toDate: DateTime.now(),
          ownerId: initialOwnerId,
          isOwnerView: isOwner,
        )) {
    loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = await _reportRepository.getSummary(
        state.fromDate,
        state.toDate,
        ownerId: state.ownerId,
      );
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

  void setOwnerFilter({String? ownerId, bool isOwner = false}) {
    state = state.copyWith(ownerId: ownerId, isOwnerView: isOwner);
    loadReport();
  }
}

final reportViewModelProvider =
    StateNotifierProvider<ReportViewModel, ReportState>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  final user = ref.watch(authViewModelProvider).user;

  final isOwner = user != null && (user.role == UserRole.owner || user.role == UserRole.staff);
  final ownerId = isOwner ? user.id : null;

  return ReportViewModel(repo, initialOwnerId: ownerId, isOwner: isOwner);
});
