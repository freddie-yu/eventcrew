import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/time_entry_model.dart';
import '../attendance_providers.dart';

class AttendancePanel extends ConsumerStatefulWidget {
  const AttendancePanel({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<AttendancePanel> createState() => _AttendancePanelState();
}

class _AttendancePanelState extends ConsumerState<AttendancePanel> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  // Server state (the persisted clock_in) is authoritative; this timer
  // only recomputes a display value from it every second. It never
  // stores or invents attendance state of its own.
  void _startTicker(DateTime clockIn) {
    _ticker?.cancel();
    setState(() => _elapsed = DateTime.now().difference(clockIn));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(clockIn));
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(activeTimeEntryProvider(widget.eventId));
    final controllerState = ref.watch(attendanceControllerProvider);

    // Side effects (starting/stopping the ticker, showing errors) live in
    // ref.listen rather than the build/data callback below, so they never
    // run during a build phase.
    ref.listen<AsyncValue<TimeEntry?>>(
      activeTimeEntryProvider(widget.eventId),
      (previous, next) {
        final entry = next.valueOrNull;
        if (entry != null) {
          _startTicker(entry.clockIn);
        } else if (next.hasValue) {
          _stopTicker();
          setState(() => _elapsed = Duration.zero);
        }
      },
    );

    ref.listen(attendanceControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(next.error!))),
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: AsyncValueView(
        value: entryAsync,
        loading: const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        onRetry: () => ref.invalidate(activeTimeEntryProvider(widget.eventId)),
        data: (entry) {
          final isActive = entry != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Attendance',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  StatusBadge(
                    label: isActive ? 'Clocked In' : 'Not Clocked In',
                    tone: isActive ? BadgeTone.positive : BadgeTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isActive) ...[
                Text(
                  'Since ${DateFormat('h:mm a').format(entry.clockIn)}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatElapsed(_elapsed),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: isActive
                    ? OutlinedButton(
                        onPressed: controllerState.isLoading
                            ? null
                            : () => ref
                                .read(attendanceControllerProvider.notifier)
                                .clockOut(eventId: widget.eventId, entryId: entry.id),
                        child: Text(
                          controllerState.isLoading ? 'Clocking out…' : 'Clock Out',
                        ),
                      )
                    : ElevatedButton(
                        onPressed: controllerState.isLoading
                            ? null
                            : () => ref
                                .read(attendanceControllerProvider.notifier)
                                .clockIn(widget.eventId),
                        child: Text(
                          controllerState.isLoading ? 'Clocking in…' : 'Clock In',
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
