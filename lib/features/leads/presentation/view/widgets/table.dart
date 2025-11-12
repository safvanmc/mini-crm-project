import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';

class LeadsDataTable extends StatelessWidget {
  const LeadsDataTable({super.key, required this.leads});

  final List<Lead> leads;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, hh:mm a');

    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurface,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 32,
              headingTextStyle: headingStyle,
              columns: const [
                DataColumn(label: Text('Lead Name')),
                DataColumn(label: Text('Mobile')),
                DataColumn(label: Text('Project')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Created At')),
              ],
              rows: leads.map((lead) {
                final createdAt = lead.createdAt != null
                    ? dateFormat.format(lead.createdAt!)
                    : '—';

                return DataRow(
                  cells: [
                    DataCell(Text(lead.leadName.isEmpty
                        ? 'Unnamed lead'
                        : lead.leadName)),
                    DataCell(Text(lead.mobile.isEmpty ? '—' : lead.mobile)),
                    DataCell(Text(
                        lead.projectName.isEmpty ? '—' : lead.projectName)),
                    DataCell(_StatusChip(status: lead.status)),
                    DataCell(Text(createdAt)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LeadStatus status;

  Color _backgroundColor(BuildContext context) {
    switch (status) {
      case LeadStatus.newLead:
        return Theme.of(context).colorScheme.primary.withOpacity(0.12);
      case LeadStatus.followUp:
        return Colors.orange.withOpacity(0.12);
      case LeadStatus.closed:
        return Colors.green.withOpacity(0.12);
    }
  }

  Color _textColor(BuildContext context) {
    switch (status) {
      case LeadStatus.newLead:
        return Theme.of(context).colorScheme.primary;
      case LeadStatus.followUp:
        return Colors.orange.shade700;
      case LeadStatus.closed:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: _textColor(context), fontWeight: FontWeight.w600),
      ),
    );
  }
}
