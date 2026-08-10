import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../model/cash_collection_model.dart';

class CashCollectionState extends Equatable {
  final ApiStatus fetchStatus;
  final ApiStatus statsFetchStatus;

  final CashCollectionResponse? response;
  final CashCollectionResponse? statsResponse;

  final String selectedDateRange;
  final String? submissionStatus;
  final bool isFetchingMore;
  final bool hasReachedMax;
  final int currentPage;
  final String message;

  const CashCollectionState({
    this.fetchStatus = ApiStatus.initial,
    this.statsFetchStatus = ApiStatus.initial,
    this.response,
    this.statsResponse,
    this.selectedDateRange = 'all',
    this.submissionStatus,
    this.isFetchingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.message = '',
  });

  CashCollectionState copyWith({
    ApiStatus? fetchStatus,
    ApiStatus? statsFetchStatus,
    CashCollectionResponse? response,
    CashCollectionResponse? statsResponse,
    String? selectedDateRange,
    String? submissionStatus,
    bool? isFetchingMore,
    bool? hasReachedMax,
    int? currentPage,
    String? message,
    bool clearMessage = false,
  }) {
    return CashCollectionState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      statsFetchStatus: statsFetchStatus ?? this.statsFetchStatus,
      response: response ?? this.response,
      statsResponse: statsResponse ?? this.statsResponse,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      message: clearMessage ? '' : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    fetchStatus,
    statsFetchStatus,
    response,
    statsResponse,
    selectedDateRange,
    submissionStatus,
    isFetchingMore,
    hasReachedMax,
    currentPage,
    message,
  ];
}
