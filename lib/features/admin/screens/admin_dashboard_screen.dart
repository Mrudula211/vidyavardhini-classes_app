import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../students/providers/student_providers.dart';
import '../../auth/providers/auth_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCountAsync = ref.watch(pendingStudentsCountProvider);
    final pendingCount = pendingCountAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.maroon,
        elevation: 0,
        title: Text(
          'Admin Portal',
          style: AppTypography.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.parchment,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Announcements',
            icon: const Icon(Icons.campaign_outlined, color: AppColors.gold),
            onPressed: () => context.push(Routes.announcementList),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppColors.gold),
            onPressed: () {
              ref.read(adminAuthenticatedProvider.notifier).state = false;
              context.go(Routes.roleSelect);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.maroon, AppColors.brown],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brown.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold, width: 2),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.gold,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mrs. Siddhi Gharat',
                                style: AppTypography.cinzel(
                                  color: AppColors.parchment,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vidyavardhini Classes • Owner & Admin',
                                style: AppTypography.poppins(
                                  color: AppColors.goldLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Section Title
                  Text(
                    'Management Modules',
                    style: AppTypography.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroon,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Responsive Grid with Fixed Height & Max Width Cards
                  GridView.extent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 130,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardCard(
                        context,
                        title: 'Student Desk',
                        subtitle: 'Approve & List',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF1E88E5),
                        badgeCount: pendingCount,
                        onTap: () => context.push(Routes.adminStudents),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Teacher Desk',
                        subtitle: 'Staff & Payroll',
                        icon: Icons.school_rounded,
                        color: const Color(0xFF8E24AA),
                        onTap: () => context.push(Routes.adminTeachers),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Fee Overview',
                        subtitle: 'Collect & Track',
                        icon: Icons.payments_rounded,
                        color: const Color(0xFF43A047),
                        onTap: () => context.push(Routes.adminFees),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Revenue Analytics',
                        subtitle: 'Annual Reports',
                        icon: Icons.insights_rounded,
                        color: const Color(0xFFD81B60),
                        onTap: () => context.push(Routes.adminRevenue),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Attendance',
                        subtitle: 'Daily Register',
                        icon: Icons.fact_check_rounded,
                        color: const Color(0xFFFB8C00),
                        onTap: () => context.push(Routes.adminAttendance),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Timetable',
                        subtitle: 'Class Schedules',
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFF00ACC1),
                        onTap: () => context.push(Routes.adminTimetable),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Announcements',
                        subtitle: 'Notices & Alerts',
                        icon: Icons.campaign_rounded,
                        color: const Color(0xFF5E35B1),
                        onTap: () => context.push(Routes.announcementList),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Geofence Settings',
                        subtitle: 'GPS Boundary',
                        icon: Icons.location_on_rounded,
                        color: const Color(0xFFE53935),
                        onTap: () => context.push(Routes.adminGeofence),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Private Chat',
                        subtitle: 'Doubt Clearing',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF00897B),
                        onTap: () => context.push(Routes.chatList),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: AppColors.brown.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$badgeCount Pending',
                        style: AppTypography.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.cinzel(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroon,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.poppins(
                      fontSize: 11,
                      color: AppColors.brown.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
