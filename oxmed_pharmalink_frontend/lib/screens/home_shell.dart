import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/patients_tab.dart';
import 'tabs/referrals_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/more_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  _HomeShellState createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _tabs = [
    const DashboardTab(),
    const PatientsTab(),
    const ReferralsTab(),
    const ReportsTab(),
    const MoreTab(),
  ];

  final _titles = [
    'Dashboard',
    'Patients',
    'Referrals',
    'Reports',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
