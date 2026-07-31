import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/topic/topic_detail_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_error_localizer.dart';
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
  final List<bool> retrying = [false, false, false];
  int selected = 0;
  final List<int> requestIds = [0, 0, 0];
  final Set<int> _openingTopicIds = <int>{};

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

  Future<void> reload() async {
    final tab = selected;
    if (retrying[tab]) return;
    final future = switch (tab) {
      0 => widget.repository.loadRecommendedPage(),
      1 => widget.repository.loadHotPage(),
      _ => widget.repository.loadFollowingPage(),
    };
    requestIds[tab]++;
    setState(() {
      loadingMore[tab] = false;
      retrying[tab] = true;
      if (tab == 0) recommended = future;
      if (tab == 1) hot = future;
      if (tab == 2) following = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => retrying[tab] = false);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreTopicsFailed(
                localizeTopicError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted && requestId == requestIds[tab]) {
        setState(() => loadingMore[tab] = false);
      }
    }
  }

  Future<void> _openTopic(TopicSummary topic) async {
    if (_openingTopicIds.contains(topic.id)) return;
    setState(() => _openingTopicIds.add(topic.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TopicDetailScreen(
            repository: widget.repository,
            initial: topic,
            canInteract: widget.canInteract,
            onLoginRequired: widget.onLoginRequired,
            onUserTap: widget.onUserTap,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingTopicIds.remove(topic.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.topicPlaza),
          bottom: TabBar(
            onTap: select,
            tabs: [
              Tab(text: strings.recommendedTab),
              Tab(text: strings.hotTab),
              Tab(text: strings.followingTopicsTab),
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
                          Text(
                            strings.topicsLoadFailed(
                              localizeTopicError(strings, snapshot.error!),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            key: const Key('topic-plaza-retry'),
                            onPressed: retrying[selected] ? null : reload,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              retrying[selected]
                                  ? strings.processing
                                  : strings.retry,
                            ),
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
                              loadingMore[selected]
                                  ? strings.loading
                                  : strings.loadMore,
                            ),
                          ),
                        );
                      }
                      final topic = page.items[index];
                      return _TopicCard(
                        topic: topic,
                        rank: selected == 1 ? index + 1 : null,
                        onTap: _openingTopicIds.contains(topic.id)
                            ? null
                            : () => _openTopic(topic),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _LoginGuide extends StatelessWidget {
  const _LoginGuide({this.onLoginRequired});
  final VoidCallback? onLoginRequired;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_add_outlined, size: 46),
            const SizedBox(height: 14),
            Text(strings.followingTopicsLoginRequired),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onLoginRequired,
              child: Text(strings.goLogin),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.rank,
    required this.onTap,
  });
  final TopicSummary topic;
  final int? rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      key: Key('topic-card-${topic.id}'),
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
                strings.hotScore(topic.hotScore),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (topic.calculatedAt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  strings.hotCalculatedAt(
                    formatDisplayDateTime(
                      topic.calculatedAt,
                      locale: strings.tag,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 5),
              Text(
                strings.topicSevenDayStats(
                  posts: topic.postCount7d,
                  likes: topic.likeCount7d,
                  comments: topic.commentCount7d,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.topicFollowMeta(
                  followers: topic.followerCount,
                  posts: topic.postCount,
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
