import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';
import 'package:mini_crm_project/features/leads/presentation/provider/lead_repository_provider.dart';
import 'package:mini_crm_project/features/leads/repo/leads_repository.dart';

const leadsPageSize = 50;

class LeadsPaginationState {
  const LeadsPaginationState({
    required this.pages,
    required this.currentPageIndex,
    required this.isInitialLoading,
    required this.isPageLoading,
    required this.hasMore,
    required this.lastDocument,
    required this.filter,
    this.errorMessage,
    this.lastActionWasNext = true,
  });

  final List<List<Lead>> pages;
  final int currentPageIndex;
  final bool isInitialLoading;
  final bool isPageLoading;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final LeadStatus? filter;
  final String? errorMessage;
  final bool lastActionWasNext;

  List<Lead> get currentPageLeads =>
      pages.isEmpty ? const [] : pages[currentPageIndex];

  bool get canGoPrevious =>
      pages.isNotEmpty && currentPageIndex > 0 && !isInitialLoading;

  bool get canGoNext {
    if (isInitialLoading) return false;
    if (pages.isEmpty) return false;
    if (currentPageIndex < pages.length - 1) {
      return true;
    }
    return hasMore;
  }

  factory LeadsPaginationState.initial({LeadStatus? filter}) =>
      LeadsPaginationState(
        pages: const [],
        currentPageIndex: 0,
        isInitialLoading: false,
        isPageLoading: false,
        hasMore: true,
        lastDocument: null,
        filter: filter,
        errorMessage: null,
      );

  LeadsPaginationState copyWith({
    List<List<Lead>>? pages,
    int? currentPageIndex,
    bool? isInitialLoading,
    bool? isPageLoading,
    bool? hasMore,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool setLastDocument = false,
    LeadStatus? filter,
    bool setFilter = false,
    String? errorMessage,
    bool clearError = false,
    bool? lastActionWasNext,
  }) {
    return LeadsPaginationState(
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isPageLoading: isPageLoading ?? this.isPageLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: setLastDocument ? lastDocument : this.lastDocument,
      filter: setFilter ? filter : this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastActionWasNext: lastActionWasNext ?? this.lastActionWasNext,
    );
  }
}

class LeadsPaginationNotifier extends StateNotifier<LeadsPaginationState> {
  LeadsPaginationNotifier(this._repository)
      : super(LeadsPaginationState.initial());

  final LeadsRepository _repository;
  int _requestId = 0;

  Future<void> loadInitial({LeadStatus? filter}) async {
    state = LeadsPaginationState.initial(filter: filter).copyWith(
      isInitialLoading: true,
      clearError: true,
      lastActionWasNext: false,
      setLastDocument: true,
      lastDocument: null,
    );

    final requestId = ++_requestId;
    try {
      final result = await _repository.fetchLeadsPage(
        status: filter,
        startAfter: null,
        limit: leadsPageSize,
      );

      if (requestId != _requestId) {
        return;
      }

      final newPages = result.leads.isEmpty
          ? <List<Lead>>[]
          : <List<Lead>>[List<Lead>.unmodifiable(result.leads)];

      state = state.copyWith(
        pages: newPages,
        currentPageIndex: 0,
        isInitialLoading: false,
        isPageLoading: false,
        hasMore: result.leads.length == leadsPageSize,
        setLastDocument: true,
        lastDocument: result.lastDocument,
        clearError: true,
        lastActionWasNext: false,
        setFilter: true,
        filter: filter,
      );
    } on LeadRepositoryException catch (error) {
      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        isInitialLoading: false,
        isPageLoading: false,
        errorMessage: error.message,
        lastActionWasNext: false,
      );
    } catch (_) {
      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        isInitialLoading: false,
        isPageLoading: false,
        errorMessage: 'Unable to load leads right now. Please try again.',
        lastActionWasNext: false,
      );
    }
  }

  Future<void> goToPrevious() async {
    if (!state.canGoPrevious || state.isPageLoading) {
      return;
    }

    final newIndex = state.currentPageIndex - 1;
    state = state.copyWith(
      currentPageIndex: newIndex < 0 ? 0 : newIndex,
      clearError: true,
      lastActionWasNext: false,
    );
  }

  Future<void> goToNext() async {
    if (!state.canGoNext || state.isPageLoading) {
      return;
    }

    if (state.currentPageIndex < state.pages.length - 1) {
      state = state.copyWith(
        currentPageIndex: state.currentPageIndex + 1,
        clearError: true,
        lastActionWasNext: true,
      );
      return;
    }

    await _loadNextPageFromSource();
  }

  Future<void> retry() async {
    if (state.pages.isEmpty) {
      await loadInitial(filter: state.filter);
      return;
    }

    if (state.lastActionWasNext) {
      await _loadNextPageFromSource();
    } else {
      await loadInitial(filter: state.filter);
    }
  }

  Future<void> _loadNextPageFromSource() async {
    if (state.isInitialLoading || state.isPageLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(
      isPageLoading: true,
      clearError: true,
      lastActionWasNext: true,
    );

    final requestId = ++_requestId;
    try {
      final result = await _repository.fetchLeadsPage(
        status: state.filter,
        startAfter: state.lastDocument,
        limit: leadsPageSize,
      );

      if (requestId != _requestId) {
        return;
      }

      if (result.leads.isEmpty) {
        state = state.copyWith(
          isPageLoading: false,
          hasMore: false,
          setLastDocument: true,
          lastDocument: result.lastDocument ?? state.lastDocument,
          clearError: true,
        );
        return;
      }

      final newPages = [
        ...state.pages,
        List<Lead>.unmodifiable(result.leads),
      ];

      state = state.copyWith(
        pages: newPages,
        currentPageIndex: newPages.length - 1,
        isPageLoading: false,
        hasMore: result.leads.length == leadsPageSize,
        setLastDocument: true,
        lastDocument: result.lastDocument,
        clearError: true,
        lastActionWasNext: true,
      );
    } on LeadRepositoryException catch (error) {
      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        isPageLoading: false,
        errorMessage: error.message,
        lastActionWasNext: true,
      );
    } catch (_) {
      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        isPageLoading: false,
        errorMessage: 'Unable to load leads right now. Please try again.',
        lastActionWasNext: true,
      );
    }
  }
}

final leadsPaginationProvider = StateNotifierProvider.autoDispose<
    LeadsPaginationNotifier, LeadsPaginationState>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return LeadsPaginationNotifier(repository);
});

final statusFilterProvider = StateProvider.autoDispose<LeadStatus?>((ref) {
  return null;
});
