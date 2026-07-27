import 'package:dazhongdianping_app/features/topic/topic_detail_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:flutter/material.dart';

class TopicPlazaScreen extends StatefulWidget {
  const TopicPlazaScreen({
    super.key,
    required this.repository,
    required this.canInteract,
    this.onLoginRequired,
    this.onUserTap,
  });

  final TopicRepository repository;
  final bool canInteract;
  final VoidCallback? onLoginRequired;
  final void Function(BuildContext, int)? onUserTap;

  @override
  State<TopicPlazaScreen> createState() => _TopicPlazaScreenState();
}

class _TopicPlazaScreenState extends State<TopicPlazaScreen> {
  late Future<TopicPage> recommended;
  Future<TopicPage>? hot;
  Future<TopicPage>? following;
  final List<bool> loadingMore = [false, false, false];
  int selected = 0;
  final List<int> requestIds = [0, 0, 0];

  @override
  void initState() {
    super.initState();
    recommended = widget.repository.loadRecommendedPage();
  }

  void select(int index) {
    setState(() {
      selected = index;
      if (index == 1) hot ??= widget.repository.loadHotPage();
      if (index == 2 && widget.canInteract) {
        following ??= widget.repository.loadFollowingPage();
      }
    });
  }

  void reload() {
    final tab = selected;
    final future = switch (tab) {
      0 => widget.repository.loadRecommendedPage(),
      1 => widget.repository.loadHotPage(),
      _ => widget.repository.loadFollowingPage(),
    };
    requestIds[tab]++;
    setState(() {
      loadingMore[tab] = false;
      if (tab == 0) recommended = future;
      if (tab == 1) hot = future;
      if (tab == 2) following = future;
    });
  }

  Future<void> loadMore(TopicPage current) async {
    final tab = selected;
    if (loadingMore[tab] || !current.hasMore) return;
    final requestId = requestIds[tab];
    setState(() => loadingMore[tab] = true);
    try {
      final next = switch (tab) {
        0 => await widget.repository.loadRecommendedPage(
          page: current.page + 1,
          pageSize: current.pageSize,
        ),
        1 => await widget.repository.loadHotPage(
          page: current.page + 1,
          pageSize: current.pageSize,
        ),
        _ => await widget.repository.loadFollowingPage(
          page: current.page + 1,
          pageSize: current.pageSize,
        ),
      };
      if (!mounted || requestId != requestIds[tab]) return;
      final knownIds = current.items.map((topic) => topic.id).toSet();
      final merged = TopicPage(
        items: [
          ...current.items,
          ...next.items.where((topic) => knownIds.add(topic.id)),
        ],
        total: next.total,
        page: next.page,
        pageSize: current.pageSize,
      );
      setState(() {
        if (tab == 0) recommended = Future.value(merged);
        if (tab == 1) hot = Future.value(merged);
        if (tab == 2) following = Future.value(merged);
      });
    } catch (error) {
      if (mounted && requestId == requestIds[tab]) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多话题失败：$error')));
      }
    } finally {
      if (mounted && requestId == requestIds[tab]) {
        setState(() => loadingMore[tab] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('话题广场'),
        bottom: TabBar(
          onTap: select,
          tabs: const [
            Tab(text: '推荐'),
            Tab(text: '热榜'),
            Tab(text: '已关注'),
          ],
        ),
      ),
      body: selected == 2 && !widget.canInteract
          ? _LoginGuide(onLoginRequired: widget.onLoginRequired)
          : FutureBuilder<TopicPage>(
              future: selected == 0
                  ? recommended
                  : selected == 1
                  ? hot
                  : following,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('话题加载失败：${snapshot.error}'),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const Key('topic-plaza-retry'),
                          onPressed: reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final page = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: page.items.length + (page.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    if (index == page.items.length) {
                      return Center(
                        child: OutlinedButton.icon(
                          key: const Key('topic-plaza-load-more'),
                          onPressed: loadingMore[selected]
                              ? null
                              : () => loadMore(page),
                          icon: loadingMore[selected]
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            loadingMore[selected] ? '加载中...' : '加载更多',
                          ),
                        ),
                      );
                    }
                    return _TopicCard(
                      topic: page.items[index],
                      rank: selected == 1 ? index + 1 : null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TopicDetailScreen(
                            repository: widget.repository,
                            initial: page.items[index],
                            canInteract: widget.canInteract,
                            onLoginRequired: widget.onLoginRequired,
                            onUserTap: widget.onUserTap,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    ),
  );
}

class _LoginGuide extends StatelessWidget {
  const _LoginGuide({this.onLoginRequired});
  final VoidCallback? onLoginRequired;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_add_outlined, size: 46),
          const SizedBox(height: 14),
          const Text('登录后查看关注的话题，不会额外生成独立动态流。'),
          const SizedBox(height: 14),
          FilledButton(onPressed: onLoginRequired, child: const Text('去登录')),
        ],
      ),
    ),
  );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.rank,
    required this.onTap,
  });
  final TopicSummary topic;
  final int? rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (rank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFE85D2A)
                          : const Color(0xFF25352F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'TOP $rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (rank != null) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    topic.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (topic.recommended)
                  const Icon(
                    Icons.workspace_premium_outlined,
                    color: Color(0xFFE85D2A),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '热度 ${topic.hotScore}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              '7 天：${topic.postCount7d} 帖 · ${topic.likeCount7d} 赞 · ${topic.commentCount7d} 评论',
            ),
            const SizedBox(height: 10),
            Text(
              '${topic.followerCount} 人关注 · ${topic.postCount} 篇公开帖子',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    ),
  );
}
