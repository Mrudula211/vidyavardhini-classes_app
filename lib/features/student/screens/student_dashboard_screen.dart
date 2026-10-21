import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../../l10n/l10n_context.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.studentDashboardTitle),
        actions: [
          const NotificationBellButton(iconColor: AppColors.primary),
          IconButton(
            tooltip: context.l10n.announcements,
            icon: const Icon(Icons.campaign_outlined, color: AppColors.primary),
            onPressed: () => context.push(Routes.announcementList),
          ),
          IconButton(
            tooltip: context.l10n.logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(Routes.roleSelect);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.school_outlined,
                        color: AppColors.primary, size: 32,),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.welcomeStudent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Vidyavardhini Classes App',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              context.l10n.myStudentHub,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildCard(
                  context,
                  title: context.l10n.tileAttendance,
                  subtitle: context.l10n.tileAttendanceSub,
                  icon: Icons.event_available,
                  color: Colors.green,
                  onTap: () => context.push(Routes.studentAttendance),
                ),
                _buildCard(
                  context,
                  title: context.l10n.tileHomework,
                  subtitle: context.l10n.tileHomeworkSub,
                  icon: Icons.menu_book,
                  color: Colors.orange,
                  onTap: () => context.push(Routes.studentHomework),
                ),
                _buildCard(
                  context,
                  title: context.l10n.tileClasswork,
                  subtitle: context.l10n.tileClassworkSub,
                  icon: Icons.folder_open,
                  color: Colors.blue,
                  onTap: () => context.push(Routes.studentClasswork),
                ),
                _buildCard(
                  context,
                  title: context.l10n.tileFees,
                  subtitle: context.l10n.tileFeesSub,
                  icon: Icons.payment,
                  color: Colors.purple,
                  onTap: () => context.push(Routes.studentFees),
                ),
                _buildCard(
                  context,
                  title: context.l10n.tileChat,
                  subtitle: context.l10n.tileChatSub,
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.teal,
                  onTap: () => context.push(Routes.chatList),
                ),
                _buildCard(
                  context,
                  title: context.l10n.tileTimetable,
                  subtitle: context.l10n.tileTimetableSub,
                  icon: Icons.calendar_month,
                  color: Colors.indigo,
                  onTap: () => context.push(Routes.userTimetable),
                ),
                _buildCard(
                  context,
                  title: context.l10n.tileAnnouncements,
                  subtitle: context.l10n.tileAnnouncementsSub,
                  icon: Icons.campaign,
                  color: Colors.deepPurple,
                  onTap: () => context.push(Routes.announcementList),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: title,
      hint: context.l10n.navigateTo(title),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
