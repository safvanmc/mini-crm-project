import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mini_crm_project/core/widgets/custom_loading.dart';
import 'package:mini_crm_project/core/widgets/custom_material_button.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';
import 'package:mini_crm_project/features/leads/presentation/provider/leads_list_providers.dart';
import 'package:mini_crm_project/features/leads/presentation/view/widgets/empty_widget.dart';
import 'package:mini_crm_project/features/leads/presentation/view/widgets/error_widget.dart';
import 'package:mini_crm_project/features/leads/presentation/view/widgets/table.dart';

class AllLeadsPage extends ConsumerStatefulWidget {
  const AllLeadsPage({super.key});

  @override
  ConsumerState<AllLeadsPage> createState() => _AllLeadsPageState();
}

class _AllLeadsPageState extends ConsumerState<AllLeadsPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final filter = ref.read(statusFilterProvider);
      ref.read(leadsPaginationProvider.notifier).loadInitial(filter: filter);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LeadStatus?>(
      statusFilterProvider,
      (_, next) {
        ref.read(leadsPaginationProvider.notifier).loadInitial(filter: next);
        _scrollToTop();
      },
    );

    ref.listen<LeadsPaginationState>(
      leadsPaginationProvider,
      (previous, next) {
        if (!mounted) return;
        if (previous?.currentPageIndex != next.currentPageIndex) {
          _scrollToTop();
        }

        final newError = next.errorMessage;
        final previousError = previous?.errorMessage;
        final shouldShowError = newError != null &&
            newError != previousError &&
            next.pages.isNotEmpty;

        if (shouldShowError) {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(newError)));
        }
      },
    );

    final paginationState = ref.watch(leadsPaginationProvider);
    final statusFilter = ref.watch(statusFilterProvider);

    final hasLoadedPages = paginationState.pages.isNotEmpty;
    final leads = paginationState.currentPageLeads;

    final isInitialLoading =
        paginationState.isInitialLoading && !hasLoadedPages;
    if (isInitialLoading) {
      return const Center(child: CustomLoading());
    }

    final hasInitialError = paginationState.errorMessage != null &&
        !hasLoadedPages &&
        !paginationState.isInitialLoading;
    if (hasInitialError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LeadsErrorWidget(message: paginationState.errorMessage!),
              const Gap(16),
              CustomMaterialButton(
                text: 'Retry',
                icon: Icons.refresh,
                isLoading: paginationState.isInitialLoading,
                onPressed: paginationState.isInitialLoading
                    ? null
                    : () => ref.read(leadsPaginationProvider.notifier).retry(),
              ),
            ],
          ),
        ),
      );
    }

    final footer = _buildFooter(context, paginationState);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverGap(8),
        SliverToBoxAdapter(
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Filter by status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LeadStatus?>(
                      value: statusFilter,
                      isDense: true,
                      onChanged: (value) =>
                          ref.read(statusFilterProvider.notifier).state = value,
                      items: [
                        const DropdownMenuItem<LeadStatus?>(
                          value: null,
                          child: Text('All statuses'),
                        ),
                        ...LeadStatus.values.map(
                          (status) => DropdownMenuItem<LeadStatus?>(
                            value: status,
                            child: Text(status.label),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Gap(24)),
        SliverToBoxAdapter(
          child: leads.isEmpty
              ? const EmptyWidget()
              : LeadsDataTable(leads: leads),
        ),
        const SliverToBoxAdapter(child: Gap(24)),
        SliverToBoxAdapter(child: footer),
        const SliverToBoxAdapter(child: Gap(32)),
      ],
    );
  }

  Widget _buildFooter(
    BuildContext context,
    LeadsPaginationState state,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(leadsPaginationProvider.notifier);

    if (state.pages.isEmpty) {
      if (state.errorMessage != null) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(12),
            CustomMaterialButton(
              text: 'Retry',
              icon: Icons.refresh,
              isLoading: state.isInitialLoading || state.isPageLoading,
              onPressed: state.isInitialLoading || state.isPageLoading
                  ? null
                  : () => notifier.retry(),
            ),
          ],
        );
      }

      return const SizedBox.shrink();
    }

    final isCompact = MediaQuery.of(context).size.width < 600;
    final currentPage = state.currentPageIndex + 1;
    final totalPages = state.pages.length;
    final isOnLastLoadedPage = state.currentPageIndex == state.pages.length - 1;
    final isLastPage = isOnLastLoadedPage && !state.hasMore;

    final prevButton = CustomMaterialButton(
      text: 'Previous',
      icon: Icons.chevron_left,
      isLeft: false,
      onPressed: (!state.isPageLoading && state.canGoPrevious)
          ? () => notifier.goToPrevious()
          : null,
    );

    final nextButton = CustomMaterialButton(
      text: 'Next',
      icon: Icons.chevron_right,
      isLeft: true,
      isLoading: state.isPageLoading,
      onPressed: (state.isPageLoading || !state.canGoNext)
          ? null
          : () => notifier.goToNext(),
    );

    final List<Widget> children = [
      Text(
        'Page $currentPage of $totalPages${isLastPage ? ' (last page)' : ''}',
        style: theme.textTheme.bodyMedium,
      ),
      const Gap(12),
    ];

    if (state.errorMessage != null) {
      children.addAll([
        Text(
          state.errorMessage!,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const Gap(12),
        CustomMaterialButton(
          text: 'Try again',
          icon: Icons.refresh,
          isLoading: state.isPageLoading,
          onPressed: state.isPageLoading ? null : () => notifier.retry(),
        ),
        const Gap(12),
      ]);
    }

    if (isCompact) {
      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: prevButton),
                const Gap(12),
                Expanded(child: nextButton),
              ],
            ),
          ],
        ),
      );
    } else {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            prevButton,
            const Gap(16),
            nextButton,
          ],
        ),
      );
    }

    if (isLastPage) {
      children.addAll([
        const Gap(12),
        Text(
          'You\'re all caught up.',
          style: theme.textTheme.bodyMedium,
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
