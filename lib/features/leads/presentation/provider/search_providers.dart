import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';
import 'package:mini_crm_project/features/leads/presentation/provider/lead_repository_provider.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final selectedLeadProvider = StateProvider.autoDispose<Lead?>((ref) => null);

final leadSearchSuggestionsProvider =
    StreamProvider.autoDispose<List<Lead>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final repository = ref.watch(leadsRepositoryProvider);
  final normalized = query.trim();

  if (normalized.isEmpty) {
    return Stream.value(const []);
  }

  return repository.searchLeads(normalized);
});
