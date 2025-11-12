import 'package:flutter/material.dart';
import 'package:mini_crm_project/core/theme/app_theme.dart';
import 'package:mini_crm_project/features/home/presentation/view/home_page.dart';

class MiniCrmApp extends StatelessWidget {
  const MiniCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
