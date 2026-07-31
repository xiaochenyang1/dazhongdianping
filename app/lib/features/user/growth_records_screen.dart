import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:flutter/material.dart';

String _localizedGrowthRecordsError(AppLocalizations strings, Object error) {
  return localizeAuthError(
    strings,
    error,
    overrides: {'用户登录状态不存在': strings.growthRecordsErrorSessionMissing},
  );
}

class GrowthRecordsScreen extends StatefulWidget {
  const GrowthRecordsScreen({super.key, required this.repository});

  final UserRepository repository;

  @override
  State<GrowthRecordsScreen> createState() => _GrowthRecordsScreenState();
}

class _GrowthRecordsScreenState extends State<GrowthRecordsScreen> {
  late Future<UserGrowthRecordPage> _pageFuture;
  UserProfile? _profile;
  final List<UserGrowthRecord> _items = <UserGrowthRecord>[];
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _reloading = false;
  int _pageRevision = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageFuture = _load(reset: true, revision: _pageRevision);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.repository.loadProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      // Profile is optional decoration for the page header.
    }
  }

  Future<UserGrowthRecordPage> _load({
    required bool reset,
    required int revision,
  }) async {
    final nextPage = reset ? 1 : _page + 1;
    final page = await widget.repository.loadGrowthRecords(
      page: nextPage,
      pageSize: 20,
    );
    if (!mounted || revision != _pageRevision) return page;
    setState(() {
      if (reset) {
        _items
          ..clear()
          ..addAll(page.items);
      } else {
        final knownIds = _items.map((item) => item.id).toSet();
        _items.addAll(page.items.where((item) => knownIds.add(item.id)));
      }
      _page = page.page;
      _hasMore = page.hasMore;
      _error = null;
      _loadingMore = false;
      _pageFuture = Future.value(page);
    });
    return page;
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final revision = ++_pageRevision;
    setState(() {
      _loadingMore = false;
      _reloading = true;
    });
    try {
      await _load(reset: true, revision: revision);
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        setState(
          () =>
              _error = AppLocalizations.of(context).refreshGrowthRecordsFailed(
                _localizedGrowthRecordsError(
                  AppLocalizations.of(context),
                  error,
                ),
              ),
        );
      }
    } finally {
      if (mounted && revision == _pageRevision) {
        setState(() => _reloading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final revision = _pageRevision;
    setState(() => _loadingMore = true);
    try {
      await _load(reset: false, revision: revision);
    } catch (error) {
      if (!mounted || revision != _pageRevision) return;
      setState(() {
        _loadingMore = false;
        _error = AppLocalizations.of(context).loadMoreFailed(
          _localizedGrowthRecordsError(AppLocalizations.of(context), error),
        );
      });
    }
  }

  String _amountText(int value) => '${value >= 0 ? '+' : ''}$value';

  Color _typeColor(int type) {
    if (type == 1) return const Color(0xFF0F766E);
    if (type == 2) return const Color(0xFFB45309);
    return const Color(0xFF4B5563);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.growthRecords)),
      body: FutureBuilder<UserGrowthRecordPage>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              _items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && _items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.growthRecordsLoadFailed(
                      _localizedGrowthRecordsError(strings, snapshot.error!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('growth-records-retry'),
                    onPressed: _reloading ? null : _reload,
                    child: Text(
                      _reloading ? strings.processing : strings.retry,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_profile != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile!.nickname,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.growthRecordsSubtitle(
                              level: _profile!.level,
                              growth: _profile!.growthValue,
                              points: _profile!.points,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_profile != null) const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                  ),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text(strings.noGrowthRecords)),
                  )
                else
                  ..._items.map((item) {
                    final typeText = strings.growthRecordTypeLabel(
                      item.type,
                      fallback: item.typeText,
                    );
                    final actionText = strings.growthRecordActionLabel(
                      item.action,
                      fallback: item.actionText,
                    );
                    final remarkText = item.remark.isNotEmpty
                        ? strings.growthRecordRemarkLabel(
                            item.action,
                            fallback: item.remark,
                          )
                        : '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(actionText),
                        subtitle: Text(
                          [
                            if (typeText.isNotEmpty) typeText,
                            if (remarkText.isNotEmpty) remarkText,
                            if (item.createdAt.isNotEmpty)
                              formatDisplayDateTime(
                                item.createdAt,
                                locale: strings.tag,
                              ),
                            strings.balanceAfterLabel(item.balanceAfter),
                          ].where((part) => part.isNotEmpty).join(' · '),
                        ),
                        trailing: Text(
                          _amountText(item.changeAmount),
                          style: TextStyle(
                            color: _typeColor(item.type),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: Center(
                      child: FilledButton.tonal(
                        onPressed: _loadingMore ? null : _loadMore,
                        child: Text(
                          _loadingMore ? strings.loading : strings.loadMore,
                        ),
                      ),
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
