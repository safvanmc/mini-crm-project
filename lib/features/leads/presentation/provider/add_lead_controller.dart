import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';
import 'package:mini_crm_project/features/leads/presentation/provider/lead_repository_provider.dart';
import 'package:mini_crm_project/features/leads/repo/leads_repository.dart';

class AddLeadController extends StateNotifier<AsyncValue<void>> {
  AddLeadController(this._repository) : super(const AsyncData<void>(null));

  final LeadsRepository _repository;

  Future<void> submit({
    required String leadName,
    required String mobile,
    required String projectName,
    required LeadStatus status,
  }) async {
    state = const AsyncLoading();
    try {
      final lead = Lead(
        id: '',
        leadName: leadName,
        mobile: mobile,
        projectName: projectName,
        status: status,
        createdAt: DateTime.now(),
      );
      await _repository.addLead(lead);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final addLeadControllerProvider =
    StateNotifierProvider.autoDispose<AddLeadController, AsyncValue<void>>(
  (ref) {
    final repository = ref.watch(leadsRepositoryProvider);
    return AddLeadController(repository);
  },
);
