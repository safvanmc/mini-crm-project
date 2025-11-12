import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const Gap(16),
            Text(
              'No leads available.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Text(
              'Add a lead to see it appear here in real-time.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
