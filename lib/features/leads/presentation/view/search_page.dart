import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mini_crm_project/core/widgets/custom_loading.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';
import 'package:mini_crm_project/features/leads/presentation/provider/search_providers.dart';
import 'package:mini_crm_project/features/leads/presentation/view/widgets/lead_detail_card.dart';
import 'package:mini_crm_project/features/leads/repo/leads_repository.dart';

class SearchLeadPage extends ConsumerStatefulWidget {
  const SearchLeadPage({super.key});

  @override
  ConsumerState<SearchLeadPage> createState() => _SearchLeadPageState();
}

class _SearchLeadPageState extends ConsumerState<SearchLeadPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Lead>>>(
      leadSearchSuggestionsProvider,
      (previous, next) {
        if (!next.hasError || (previous?.hasError ?? false)) return;
        final error = next.asError?.error;
        if (!mounted || error == null) return;
        final message = error is LeadRepositoryException
            ? error.message
            : 'Unable to search leads right now. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );

    final query = ref.watch(searchQueryProvider);
    final suggestionsAsync = ref.watch(leadSearchSuggestionsProvider);
    final selectedLead = ref.watch(selectedLeadProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final suggestionsWidget = _SuggestionsList(
          suggestionsAsync: suggestionsAsync,
          onLeadSelected: (lead) async {
            ref.read(selectedLeadProvider.notifier).state = lead;
            if (!isWide) {
              await showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return Dialog(
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 420, maxHeight: 200),
                      child: LeadDetailCard(lead: lead),
                    ),
                  );
                },
              );
            }
          },
        );

        final detailWidget = selectedLead == null
            ? const _EmptyLeadDetails()
            : LeadDetailCard(lead: selectedLead);

        final minHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Search leads by name, mobile number, or project name.',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Gap(16),
                TextField(
                  controller: _controller,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                    if (value.trim().isEmpty) {
                      ref.read(selectedLeadProvider.notifier).state = null;
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Search leads',
                    hintText: 'Type a name, mobile, or project',
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _controller.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                              ref.read(selectedLeadProvider.notifier).state =
                                  null;
                            },
                          ),
                  ),
                ),
                const Gap(24),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: suggestionsWidget),
                      const Gap(24),
                      Expanded(child: detailWidget),
                    ],
                  )
                else ...[
                  suggestionsWidget,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionsList extends ConsumerWidget {
  const _SuggestionsList({
    required this.suggestionsAsync,
    required this.onLeadSelected,
  });

  final AsyncValue<List<Lead>> suggestionsAsync;
  final ValueChanged<Lead> onLeadSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: suggestionsAsync.when(
          loading: () => const Center(child: CustomLoading()),
          error: (error, _) => _SuggestionsPlaceholder(
            icon: Icons.error_outline,
            message: 'Unable to load suggestions.\nPlease try again.',
          ),
          data: (leads) {
            if (query.isEmpty) {
              return const _SuggestionsPlaceholder(
                icon: Icons.search,
                message: 'Start typing to see live suggestions.',
              );
            }

            if (leads.isEmpty) {
              return const _SuggestionsPlaceholder(
                icon: Icons.person_search,
                message: 'No matching leads found.',
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                itemCount: leads.length,
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      child: Text(
                        lead.leadName.isNotEmpty
                            ? lead.leadName.characters.first.toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                        lead.leadName.isEmpty ? 'Unnamed lead' : lead.leadName),
                    subtitle: Text(
                      [
                        if (lead.mobile.isNotEmpty) lead.mobile,
                        if (lead.projectName.isNotEmpty) lead.projectName,
                      ].join(' • '),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      onLeadSelected(lead);
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionsPlaceholder extends StatelessWidget {
  const _SuggestionsPlaceholder({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const Gap(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLeadDetails extends StatelessWidget {
  const _EmptyLeadDetails();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const Gap(16),
            Text(
              'Select a lead to see details.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
