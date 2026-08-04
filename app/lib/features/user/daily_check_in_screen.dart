import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({
    super.key,
    required this.repository,
    this.onCheckedIn,
  });

  final UserRepository repository;

  /// Lets the caller refresh cached points/growth after a successful check-in.
  final ValueChanged<UserCheckInStatus>? onCheckedIn;

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  late Future<UserCheckInStatus> _statusFuture;
  UserCheckInStatus? _status;
  bool _reloading = false;
  bool _submitting = false;
  int _revision = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _statusFuture = widget.repository.loadCheckInStatus();
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final revision = ++_revision;
    final future = widget.repository.loadCheckInStatus();
    setState(() {
      _statusFuture = future;
      _status = null;
      _error = null;
      _reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted && revision == _revision) {
        setState(() => _reloading = false);
      }
    }
  }

  Future<void> _checkIn() async {
    if (_submitting) return;
    final strings = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final status = await widget.repository.checkIn();
      if (!mounted) return;
      setState(() => _status = status);
      widget.onCheckedIn?.call(status);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.checkInSuccess)));
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = strings.checkInFailed(
          localizeAuthError(strings, error),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.dailyCheckIn)),
      body: FutureBuilder<UserCheckInStatus>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              _status == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && _status == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.checkInStatusLoadFailed(
                      localizeAuthError(strings, snapshot.error!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('check-in-retry'),
                    onPressed: _reloading ? null : _reload,
                    child: Text(
                      _reloading ? strings.processing : strings.retry,
                    ),
                  ),
                ],
              ),
            );
          }

          final status = _status ?? snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.dailyCheckInSubtitle(
                            streak: status.streakDays,
                            total: status.totalCount,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          status.checkedInToday
                              ? strings.checkInRewardEarned(
                                  growth: status.todayGrowthReward,
                                  points: status.todayPointsReward,
                                )
                              : strings.checkInRewardHint(
                                  growth: status.todayGrowthReward,
                                  points: status.todayPointsReward,
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          status.lastCheckInAt.isEmpty
                              ? strings.noCheckInYet
                              : strings.lastCheckInAtLabel(
                                  formatDisplayDateTime(
                                    status.lastCheckInAt,
                                    locale: strings.tag,
                                  ),
                                ),
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                  ),
                FilledButton(
                  key: const Key('check-in-submit'),
                  onPressed: status.checkedInToday || _submitting
                      ? null
                      : _checkIn,
                  child: Text(
                    _submitting
                        ? strings.processing
                        : status.checkedInToday
                        ? strings.checkedInTodayLabel
                        : strings.checkInAction,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
