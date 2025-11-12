import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mini_crm_project/core/widgets/custom_material_button.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';
import 'package:mini_crm_project/features/leads/presentation/provider/add_lead_controller.dart';
import 'package:mini_crm_project/features/leads/repo/leads_repository.dart';

class AddLeadPage extends ConsumerStatefulWidget {
  const AddLeadPage({super.key});

  @override
  ConsumerState<AddLeadPage> createState() => _AddLeadPageState();
}

class _AddLeadPageState extends ConsumerState<AddLeadPage> {
  final _formKey = GlobalKey<FormState>();
  final _leadNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _projectController = TextEditingController();
  LeadStatus _selectedStatus = LeadStatus.newLead;

  @override
  void dispose() {
    _leadNameController.dispose();
    _mobileController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _leadNameController.clear();
    _mobileController.clear();
    _projectController.clear();
    setState(() => _selectedStatus = LeadStatus.newLead);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(addLeadControllerProvider.notifier);
    try {
      await controller.submit(
        leadName: _leadNameController.text.trim(),
        mobile: _mobileController.text.trim(),
        projectName: _projectController.text.trim(),
        status: _selectedStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead saved successfully.')),
      );
      _clearForm();
    } catch (error) {
      if (!mounted) return;
      final message = error is LeadRepositoryException
          ? error.message
          : 'Unable to save lead: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(addLeadControllerProvider);
    final isLoading = submitState.isLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter lead details.',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Gap(24),
                if (isWide)
                  Row(
                    children: [
                      Expanded(
                          child:
                              _LeadNameField(controller: _leadNameController)),
                      const Gap(16),
                      Expanded(
                          child: _MobileField(controller: _mobileController)),
                    ],
                  )
                else ...[
                  _LeadNameField(controller: _leadNameController),
                  const Gap(16),
                  _MobileField(controller: _mobileController),
                ],
                const Gap(16),
                _ProjectNameField(controller: _projectController),
                const Gap(16),
                DropdownButtonFormField<LeadStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                  ),
                  items: LeadStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const Gap(32),
                Row(
                  children: [
                    Expanded(
                      child: CustomMaterialButton(
                        text: 'Save Lead',
                        expanded: true,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _submitForm,
                        // icon: Icons.save_outlined,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: CustomMaterialButton(
                        text: 'Reset',
                        expanded: true,
                        onPressed: isLoading ? null : _clearForm,
                        // icon: Icons.refresh,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeadNameField extends StatelessWidget {
  const _LeadNameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Lead Name',
        hintText: 'Enter lead name',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Lead name is required';
        }
        return null;
      },
    );
  }
}

class _MobileField extends StatelessWidget {
  const _MobileField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*')),
      ],
      decoration: const InputDecoration(
        labelText: 'Mobile Number',
        hintText: '+91 0000000000',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Mobile number is required';
        }
        if (value.trim().length < 8) {
          return 'Enter a valid mobile number';
        }
        return null;
      },
    );
  }
}

class _ProjectNameField extends StatelessWidget {
  const _ProjectNameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Project Name',
        hintText: 'Enter project name',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Project name is required';
        }
        return null;
      },
    );
  }
}
