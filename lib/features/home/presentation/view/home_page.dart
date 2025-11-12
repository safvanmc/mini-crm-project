import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mini_crm_project/features/leads/presentation/view/add_lead_page.dart';
import 'package:mini_crm_project/features/leads/presentation/view/all_leads_page.dart';
import 'package:mini_crm_project/features/leads/presentation/view/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final _navigationItems = const [
    _NavigationItem(
      label: 'Search',
      icon: Icons.search,
      page: SearchLeadPage(),
    ),
    _NavigationItem(
      label: 'Add Lead',
      icon: Icons.person_add_alt_1,
      page: AddLeadPage(),
    ),
    _NavigationItem(
      label: 'All Leads',
      icon: Icons.table_rows,
      page: AllLeadsPage(),
    ),
  ];

  void _onItemSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 900;

    if (isCompact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_navigationItems[_selectedIndex].label),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _navigationItems[_selectedIndex].page,
              ),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemSelected,
          destinations: _navigationItems
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_selectedIndex].label),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemSelected,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 72,
                  destinations: _navigationItems
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth < 1280 ? 24 : 48,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _navigationItems[_selectedIndex].label,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Gap(24),
                            Expanded(
                              child: _navigationItems[_selectedIndex].page,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}
