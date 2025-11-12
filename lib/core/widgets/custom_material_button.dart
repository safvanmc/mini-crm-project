import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mini_crm_project/core/widgets/custom_loading.dart';

class CustomMaterialButton extends StatelessWidget {
  const CustomMaterialButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    this.isLeft,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final bool? isLeft;

  @override
  Widget build(BuildContext context) {
    final buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const CustomLoading(size: 20, strokeWidth: 2),
          const Gap(12),
        ] else if (icon != null && isLeft == false) ...[
          Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
          const Gap(12),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        if (icon != null && isLeft == true) ...[
          const Gap(12),
          Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ],
      ],
    );

    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        alignment: isLeft == true
            ? Alignment.centerRight
            : isLeft == false
                ? Alignment.centerLeft
                : Alignment.center,
      ),
      onPressed: isLoading ? null : onPressed,
      child: buttonContent,
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
