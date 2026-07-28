import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/circle/circle_square_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/post_editor_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_plaza_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:flutter/material.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({
    super.key,
    required this.repository,
    required this.canInteract,
    this.onUserTap,
    this.circleRepository,
    this.topicRepository,
    this.onLoginRequired,
  });
  final CommunityRepository repository;
  final bool canInteract;
  final void Function(BuildContext, int)? onUserTap;
  final CircleRepository? circleRepository;
  final TopicRepository? topicRepository;
  final ValueChanged<BuildContext>? onLoginRequired;

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  late Future<CommunityPostPage> _posts;
  Future<CommunityPostPage>? _followingPosts;
  final List<bool> _loadingMore = [false, false];
  final List<bool> _reloading = [false, false];
  bool _openingEditor = false;
  final Set<int> _openingPostIds = <int>{};
  int _selectedTab = 0;
  final List<int> _requestIds = [0, 0];
  @override
  void initState() {
    super.initState();
    _posts = widget.repository.loadFeedPage();
  }

  Future<void> _reload() async {
    final tab = _selectedTab;
    if (_reloading[tab]) return;
    _requestIds[tab]++;
    final future = tab == 0
        ? widget.repository.loadFeedPage()
        : widget.repository.loadFollowingFeedPage();
    setState(() {
      _loadingMore[tab] = false;
      _reloading[tab] = true;
      if (tab == 0) {
        _posts = future;
      } else if (widget.canInteract) {
        _followingPosts = future;
      }
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloading[tab] = false);
    }
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTab = index;
      if (index == 1 && widget.canInteract && _followingPosts == null) {
        _followingPosts = widget.repository.loadFollowingFeedPage();
      }
    });
  }

  Future<void> _loadMore(CommunityPostPage current) async {
    final following = _selectedTab == 1;
    final tab = following ? 1 : 0;
    if (_loadingMore[tab] || !current.hasMore) return;
    final requestId = _requestIds[tab];
    setState(() => _loadingMore[tab] = true);
    try {
      final next = following
          ? await widget.repository.loadFollowingFeedPage(
              page: current.page + 1,
              pageSize: current.pageSize,
            )
          : await widget.repository.loadFeedPage(
              page: current.page + 1,
              pageSize: current.pageSize,
            );
      if (!mounted || requestId != _requestIds[tab]) return;
      final knownIds = current.items.map((post) => post.id).toSet();
      final merged = CommunityPostPage(
        items: [
          ...current.items,
          ...next.items.where((post) => knownIds.add(post.id)),
        ],
        total: next.total,
        page: next.page,
        pageSize: current.pageSize,
      );
      setState(() {
        if (following) {
          _followingPosts = Future.value(merged);
        } else {
          _posts = Future.value(merged);
        }
      });
    } catch (error) {
      if (mounted && requestId == _requestIds[tab]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMorePostsFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted && requestId == _requestIds[tab]) {
        setState(() => _loadingMore[tab] = false);
      }
    }
  }

  Future<void> _openEditor() async {
    if (_openingEditor) return;
    setState(() => _openingEditor = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostEditorScreen(repository: widget.repository),
        ),
      );
      if (mounted) _reload();
    } finally {
      if (mounted) setState(() => _openingEditor = false);
    }
  }

  Future<void> _openPost(CommunityPost post) async {
    if (_openingPostIds.contains(post.id)) return;
    setState(() => _openingPostIds.add(post.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            repository: widget.repository,
            postId: post.id,
            canInteract: widget.canInteract,
            onUserTap: widget.onUserTap,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingPostIds.remove(post.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.communityTitle),
          actions: [
            if (widget.topicRepository != null)
              IconButton(
                tooltip: strings.topicPlaza,
                icon: const Icon(Icons.tag_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TopicPlazaScreen(
                      repository: widget.topicRepository!,
                      canInteract: widget.canInteract,
                      onLoginRequired: () =>
                          widget.onLoginRequired?.call(context),
                      onUserTap: widget.onUserTap,
                    ),
                  ),
                ),
              ),
            if (widget.circleRepository != null)
              IconButton(
                tooltip: strings.localCircles,
                icon: const Icon(Icons.groups_2_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CircleSquareScreen(
                      repository: widget.circleRepository!,
                      canInteract: widget.canInteract,
                      onLoginRequired: () =>
                          widget.onLoginRequired?.call(context),
                      onCreatePost: (circle) => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostEditorScreen(
                            repository: widget.repository,
                            circleId: circle.id,
                            circleName: circle.name,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
          bottom: TabBar(
            onTap: _selectTab,
            tabs: [
              Tab(text: strings.recommendedTab),
              Tab(text: strings.followingTab),
            ],
          ),
        ),
        floatingActionButton: widget.canInteract
            ? FloatingActionButton.extended(
                key: const Key('community-create-post'),
                onPressed: _openingEditor ? null : _openEditor,
                icon: const Icon(Icons.edit_outlined),
                label: Text(strings.createPost),
              )
            : null,
        body: _selectedTab == 1 && !widget.canInteract
            ? Center(child: Text(strings.followingFeedLoginRequired))
            : RefreshIndicator(
                onRefresh: _reload,
                child: FutureBuilder<CommunityPostPage>(
                  future: _selectedTab == 0 ? _posts : _followingPosts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(strings.communityLoadFailed(snapshot.error!)),
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              key: const Key('community-feed-retry'),
                              onPressed: _reloading[_selectedTab]
                                  ? null
                                  : _reload,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                _reloading[_selectedTab]
                                    ? strings.processing
                                    : strings.retry,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final page = snapshot.data!;
                    final posts = page.items;
                    if (posts.isEmpty && !page.hasMore) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.4,
                            child: Center(child: Text(strings.noCommunityPosts)),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: posts.length + (page.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == posts.length) {
                          return Center(
                            child: OutlinedButton.icon(
                              key: const Key('community-feed-load-more'),
                              onPressed: _loadingMore[_selectedTab]
                                  ? null
                                  : () => _loadMore(page),
                              icon: _loadingMore[_selectedTab]
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.expand_more),
                              label: Text(
                                _loadingMore[_selectedTab]
                                    ? strings.loading
                                    : strings.loadMore,
                              ),
                            ),
                          );
                        }
                        final post = posts[index];
                        return Card(
                          key: Key('community-post-card-${post.id}'),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _openingPostIds.contains(post.id)
                                ? null
                                : () => _openPost(post),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    post.content,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    children: post.topics
                                        .map(
                                          (topic) => Text(
                                            '#$topic',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: widget.onUserTap == null
                                            ? null
                                            : () => widget.onUserTap!(
                                                context,
                                                post.userId,
                                              ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            post.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        strings.postMetaStats(
                                          likes: post.likeCount,
                                          comments: post.commentCount,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}
