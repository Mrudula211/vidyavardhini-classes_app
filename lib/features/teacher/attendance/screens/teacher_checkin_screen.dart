import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/geofence_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/attendance_model.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../attendance/providers/attendance_providers.dart';
import '../../../auth/providers/auth_providers.dart';

/// Teacher's own attendance: checks the phone's GPS position against the
/// admin-configured geofence. The server decides whether it is in range.
class TeacherCheckInScreen extends ConsumerStatefulWidget {
  const TeacherCheckInScreen({super.key});

  @override
  ConsumerState<TeacherCheckInScreen> createState() =>
      _TeacherCheckInScreenState();
}

class _TeacherCheckInScreenState extends ConsumerState<TeacherCheckInScreen> {
  bool _busy = false;
  String? _error;
  TeacherCheckInResult? _result;

  @override
  void initState() {
    super.initState();
    // Try once automatically on open (prompts for permission if needed).
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIn(auto: true));
  }

  Future<void> _checkIn({bool auto = false}) async {
    final user = ref.read(currentUserProvider);
    if (user == null || _busy) return;
    if (!auto && !guardOnline(context, ref)) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pos = await ref.read(geofenceServiceProvider).currentPosition();
      if (pos == null) return;
      final result = await ref
          .read(attendanceRepositoryProvider)
          .teacherCheckIn(lat: pos.latitude, lng: pos.longitude);
      ref.invalidate(todayTeacherAttendanceProvider(user.id));
      if (mounted) setState(() => _result = result);
    } on LocationUnavailableException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Check-in failed: ${_clean(e)}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _clean(Object e) =>
      e.toString().replaceAll('PostgrestException(message: ', '').split(',').first;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final today = user == null
        ? const AsyncValue<TeacherAttendanceModel?>.data(null)
        : ref.watch(todayTeacherAttendanceProvider(user.id));
    final present = today.valueOrNull?.status == 'present';

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              present ? Icons.check_circle : Icons.location_searching,
              size: 88,
              color: present ? Colors.green : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              present ? 'Marked present today' : 'Not marked yet today',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (present && today.value?.checkInTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Checked in at ${_time(today.value!.checkInTime!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            if (_result != null && !_result!.inRange)
              _Note(
                color: Colors.orange,
                text:
                    'You are ${_result!.distanceMeters.round()} m from the class '
                    '(limit ${_result!.radiusMeters} m). Move closer and try again.',
              ),
            if (_result != null && _result!.inRange && !present)
              _Note(
                color: Colors.orange,
                text: 'You are in range, but today is already recorded as '
                    '"${_result!.status}". Ask the admin to correct it.',
              ),
            if (_error != null) _Note(color: AppColors.maroon, text: _error!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _checkIn,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(present ? 'Check again' : 'Check in with GPS'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Attendance is marked automatically when you are inside the '
              'class geofence and open the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.lightOutline),
            ),
          ],
        ),
      ),
    );
  }

  String _time(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '--';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
