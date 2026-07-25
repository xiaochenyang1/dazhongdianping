import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageFuture = _load(reset: true);
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

  Future<UserGrowthRecordPage> _load({required bool reset}) async {
    final nextPage = reset ? 1 : _page + 1;
    final page = await widget.repository.loadGrowthRecords(
      page: nextPage,
      pageSize: 20,
    );
    if (!mounted) return page;
    setState(() {
      if (reset) {
        _items
          ..clear()
          ..addAll(page.items);
      } else {
        _items.addAll(page.items);
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
    setState(() {
      _error = null;
      _pageFuture = _load(reset: true);
    });
    await _pageFuture;
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      await _load(reset: false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = '$error';
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
    return Scaffold(
      appBar: AppBar(title: const Text('成长值流水')),
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
                  Text('流水加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('重试')),
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
                            'Lv.${_profile!.level} · 成长值 ${_profile!.growthValue} · 积分 ${_profile!.points}',
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
                      '加载更多失败：$_error',
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                  ),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('还没有成长值 / 积分流水')),
                  )
                else
                  ..._items.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          item.actionText.isNotEmpty
                              ? item.actionText
                              : item.action,
                        ),
                        subtitle: Text(
                          [
                            if (item.typeText.isNotEmpty) item.typeText,
                            if (item.remark.isNotEmpty) item.remark,
                            if (item.createdAt.isNotEmpty) item.createdAt,
                            '余额 ${item.balanceAfter}',
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
                    ),
                  ),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: Center(
                      child: FilledButton.tonal(
                        onPressed: _loadingMore ? null : _loadMore,
                        child: Text(_loadingMore ? '加载中...' : '加载更多'),
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
