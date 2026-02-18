import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reports_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_monthly_tasks_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'INSIGHTS',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.spaceMono(),
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'ATTENDANCE'),
              Tab(text: 'TASK REPORTS'),
              Tab(text: 'MONTHLY TASKS'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ReportsScreen(isEmbedded: true),
            AdminTasksScreen(),
            AdminMonthlyTasksScreen(),
          ],
        ),
      ),
    );
  }
}
