import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';

class LeadDetailCard extends StatelessWidget {
  const LeadDetailCard({
    required this.lead,
    super.key,
  });

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final createdAt = lead.createdAt != null
        ? DateFormat('d MMM yyyy • hh:mm a').format(lead.createdAt!)
        : 'Not available';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lead.leadName,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),
            _DetailRow(
              label: 'Mobile',
              value: lead.mobile.isEmpty ? '—' : lead.mobile,
            ),
            const Gap(8),
            _DetailRow(
              label: 'Project',
              value: lead.projectName.isEmpty ? '—' : lead.projectName,
            ),
            const Gap(8),
            _DetailRow(
              label: 'Status',
              value: lead.status.label,
            ),
            const Gap(8),
            _DetailRow(
              label: 'Created',
              value: createdAt,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
