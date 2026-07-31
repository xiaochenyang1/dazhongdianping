import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/circle/circle_error_localizer.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:flutter/material.dart';

class CircleSquareScreen extends StatefulWidget {
  const CircleSquareScreen({
    super.key,
    required this.repository,
    required this.canInteract,
    this.onLoginRequired,
    this.onCreatePost,
    this.showJoinedOnly = false,
  });

  final CircleRepository repository;
  final bool canInteract;
  final VoidCallback? onLoginRequired;
  final ValueChanged<AppCircle>? onCreatePost;
  final bool showJoinedOnly;

  @override
  State<CircleSquareScreen> createState() => _CircleSquareScreenState();
}

class _CircleSquareScreenState extends State<CircleSquareScreen> {
  late Future<CirclePage> page;
  bool loadingMore = false;
  bool reloading = false;
  int requestId = 0;
  final Set<int> _openingCircleIds = <int>{};

  @override
  void initState() {
    super.initState();
    page = widget.repository.loadCirclePage(joinedOnly: widget.showJoinedOnly);
  }

  Future<void> reload() async {
    if (reloading) return;
    final future = widget.repository.loadCirclePage(
      joinedOnly: widget.showJoinedOnly,
    );
    requestId++;
    setState(() {
      page = future;
      loadingMore = false;
      reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => reloading = false);
    }
  }

  Future<void> loadMore(CirclePage current) async {
    if (loadingMore || !current.hasMore) return;
    final currentRequestId = requestId;
    setState(() => loadingMore = true);
    try {
      final next = await widget.repository.loadCirclePage(
        joinedOnly: widget.showJoinedOnly,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || currentRequestId != requestId) return;
      final knownIds = current.items.map((circle) => circle.id).toSet();
      setState(() {
        page = Future.value(
          CirclePage(
            items: [
              ...current.items,
              ...next.items.where((circle) => knownIds.add(circle.id)),
            ],
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && currentRequestId == requestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreCirclesFailed(
                localizeCircleError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted && currentRequestId == requestId) {
        setState(() => loadingMore = false);
      }
    }
  }

  Future<void> _openCircle(AppCircle circle) async {
    if (_openingCircleIds.contains(circle.id)) return;
    setState(() => _openingCircleIds.add(circle.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CircleDetailScreen(
            repository: widget.repository,
            initial: circle,
            canInteract: widget.canInteract,
            onLoginRequired: widget.onLoginRequired,
            onCreatePost: widget.onCreatePost,
          ),
        ),
      );
      if (mounted && widget.showJoinedOnly) {
        await reload();
      }
    } finally {
      if (mounted) {
        setState(() => _openingCircleIds.remove(circle.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).localCircles)),
    body: FutureBuilder<CirclePage>(
      future: page,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).circlesLoadFailed(
                    localizeCircleError(
                      AppLocalizations.of(context),
                      snapshot.error!,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('circle-square-retry'),
                  onPressed: reloading ? null : reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    reloading
                        ? AppLocalizations.of(context).processing
                        : AppLocalizations.of(context).retry,
                  ),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final current = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: current.items.length + (current.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, index) {
            if (index == current.items.length) {
              return Center(
                child: OutlinedButton.icon(
                  key: const Key('circle-square-load-more'),
                  onPressed: loadingMore ? null : () => loadMore(current),
                  icon: loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(
                    loadingMore
                        ? AppLocalizations.of(context).loading
                        : AppLocalizations.of(context).loadMore,
                  ),
                ),
              );
            }
            final circle = current.items[index];
            return _CircleCard(
              circle: circle,
              colors: _colors(index),
              onTap: _openingCircleIds.contains(circle.id)
                  ? null
                  : () => _openCircle(circle),
            );
          },
        );
      },
    ),
  );

  List<Color> _colors(int index) => const [
    [Color(0xFFE85D2A), Color(0xFFB83A22)],
    [Color(0xFF166A63), Color(0xFF0C4543)],
    [Color(0xFFB7791F), Color(0xFF7B4B12)],
  ][index % 3];
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({
    required this.circle,
    required this.colors,
    required this.onTap,
  });
  final AppCircle circle;
  final List<Color> colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    key: Key('circle-card-${circle.id}'),
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Text(
                  circle.name.characters.first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                circle.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                circle.description,
                style: const TextStyle(color: Color(0xE6FFFFFF)),
              ),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(context).circleMeta(
                  members: circle.memberCount,
                  posts: circle.postCount,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CircleDetailScreen extends StatefulWidget {
  const CircleDetailScreen({
    super.key,
    required this.repository,
    required this.initial,
    required this.canInteract,
    this.onLoginRequired,
    this.onCreatePost,
  });
  final CircleRepository repository;
  final AppCircle initial;
  final bool canInteract;
  final VoidCallback? onLoginRequired;
  final ValueChanged<AppCircle>? onCreatePost;
  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  late AppCircle circle = widget.initial;
  late Future<CommunityPostPage> posts;
  bool saving = false;
  bool loadingMorePosts = false;
  bool reloadingPosts = false;
  bool _openingMembers = false;
  int postsRequestId = 0;
  final Set<int> _openingPostIds = <int>{};

  @override
  void initState() {
    super.initState();
    posts = widget.repository.loadPostPage(circle.id);
  }

  Future<void> reloadPosts() async {
    if (reloadingPosts) return;
    final future = widget.repository.loadPostPage(circle.id);
    postsRequestId++;
    setState(() {
      posts = future;
      loadingMorePosts = false;
      reloadingPosts = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => reloadingPosts = false);
    }
  }

  Future<void> loadMorePosts(CommunityPostPage current) async {
    if (loadingMorePosts || !current.hasMore) return;
    final requestId = postsRequestId;
    setState(() => loadingMorePosts = true);
    try {
      final next = await widget.repository.loadPostPage(
        circle.id,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || requestId != postsRequestId) return;
      final knownIds = current.items.map((post) => post.id).toSet();
      setState(() {
        posts = Future.value(
          CommunityPostPage(
            items: [
              ...current.items,
              ...next.items.where((post) => knownIds.add(post.id)),
            ],
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && requestId == postsRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMorePostsFailed(
                localizeCircleError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted && requestId == postsRequestId) {
        setState(() => loadingMorePosts = false);
      }
    }
  }

  Future<void> toggle() async {
    if (saving) return;
    if (!widget.canInteract) {
      widget.onLoginRequired?.call();
      return;
    }
    final before = circle;
    setState(() {
      saving = true;
      circle = circle.withMembership(
        !circle.joined,
        circle.memberCount + (circle.joined ? -1 : 1),
      );
    });
    try {
      final result = before.joined
          ? await widget.repository.leave(circle.id)
          : await widget.repository.join(circle.id);
      if (mounted) {
        setState(
          () =>
              circle = circle.withMembership(result.joined, result.memberCount),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => circle = before);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).circleStatusUpdateFailed(
                localizeCircleError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _openPost(CommunityPost post) async {
    if (_openingPostIds.contains(post.id)) return;
    setState(() => _openingPostIds.add(post.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            repository: CommunityRepository(widget.repository.api),
            postId: post.id,
            canInteract: widget.canInteract,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingPostIds.remove(post.id));
      }
    }
  }

  Future<void> _openMembers() async {
    if (_openingMembers) return;
    setState(() => _openingMembers = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CircleMembersScreen(
            repository: widget.repository,
            circle: circle,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingMembers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(circle.name)),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5D8),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                circle.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(circle.description),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(context).circleMeta(
                  members: circle.memberCount,
                  posts: circle.postCount,
                ),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('circle-membership-toggle'),
                      onPressed: saving ? null : toggle,
                      child: Text(
                        circle.joined
                            ? AppLocalizations.of(context).joined
                            : AppLocalizations.of(context).joinCircle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    key: const Key('circle-members-open'),
                    onPressed: _openingMembers ? null : _openMembers,
                    icon: const Icon(Icons.group_outlined),
                    tooltip: AppLocalizations.of(context).viewMembers,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (circle.joined)
          FilledButton.icon(
            onPressed: () => widget.onCreatePost?.call(circle),
            icon: const Icon(Icons.edit_outlined),
            label: Text(AppLocalizations.of(context).postInCircle),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(context).joinCircleToPost),
            ),
          ),
        const SizedBox(height: 22),
        Text(
          AppLocalizations.of(context).circleNewPosts,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        FutureBuilder<CommunityPostPage>(
          future: posts,
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).postsLoadFailed(
                            localizeCircleError(
                              AppLocalizations.of(context),
                              snapshot.error!,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          key: const Key('circle-posts-retry'),
                          onPressed: reloadingPosts ? null : reloadPosts,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            reloadingPosts
                                ? AppLocalizations.of(context).processing
                                : AppLocalizations.of(context).retry,
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator());
            }
            final page = snapshot.data!;
            if (page.items.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(AppLocalizations.of(context).noPublicPostsHere),
                ),
              );
            }
            return Column(
              children: [
                ...page.items.map(
                  (post) => Card(
                    key: Key('circle-post-card-${post.id}'),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        post.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        post.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text('❤ ${post.likeCount}'),
                      onTap: _openingPostIds.contains(post.id)
                          ? null
                          : () => _openPost(post),
                    ),
                  ),
                ),
                if (page.hasMore)
                  OutlinedButton.icon(
                    key: const Key('circle-posts-load-more'),
                    onPressed: loadingMorePosts
                        ? null
                        : () => loadMorePosts(page),
                    icon: loadingMorePosts
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(
                      loadingMorePosts
                          ? AppLocalizations.of(context).loading
                          : AppLocalizations.of(context).loadMore,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class CircleMembersScreen extends StatefulWidget {
  const CircleMembersScreen({
    super.key,
    required this.repository,
    required this.circle,
  });
  final CircleRepository repository;
  final AppCircle circle;

  @override
  State<CircleMembersScreen> createState() => _CircleMembersScreenState();
}

class _CircleMembersScreenState extends State<CircleMembersScreen> {
  late Future<CircleMemberPage> page;
  bool loadingMore = false;
  bool reloading = false;
  int requestId = 0;

  @override
  void initState() {
    super.initState();
    page = widget.repository.loadMemberPage(widget.circle.id);
  }

  Future<void> reload() async {
    if (reloading) return;
    final future = widget.repository.loadMemberPage(widget.circle.id);
    requestId++;
    setState(() {
      page = future;
      loadingMore = false;
      reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => reloading = false);
    }
  }

  Future<void> loadMore(CircleMemberPage current) async {
    if (loadingMore || !current.hasMore) return;
    final currentRequestId = requestId;
    setState(() => loadingMore = true);
    try {
      final next = await widget.repository.loadMemberPage(
        widget.circle.id,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || currentRequestId != requestId) return;
      final knownIds = current.items.map((member) => member.id).toSet();
      setState(() {
        page = Future.value(
          CircleMemberPage(
            items: [
              ...current.items,
              ...next.items.where((member) => knownIds.add(member.id)),
            ],
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && currentRequestId == requestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreMembersFailed(
                localizeCircleError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted && currentRequestId == requestId) {
        setState(() => loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        AppLocalizations.of(context).circleMembersTitle(widget.circle.name),
      ),
    ),
    body: FutureBuilder<CircleMemberPage>(
      future: page,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return snapshot.hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context).membersLoadFailed(
                          localizeCircleError(
                            AppLocalizations.of(context),
                            snapshot.error!,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        key: const Key('circle-members-retry'),
                        onPressed: reloading ? null : reload,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          reloading
                              ? AppLocalizations.of(context).processing
                              : AppLocalizations.of(context).retry,
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator());
        }
        final current = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: current.items.length + (current.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            if (i == current.items.length) {
              return Center(
                child: OutlinedButton.icon(
                  key: const Key('circle-members-load-more'),
                  onPressed: loadingMore ? null : () => loadMore(current),
                  icon: loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(
                    loadingMore
                        ? AppLocalizations.of(context).loading
                        : AppLocalizations.of(context).loadMore,
                  ),
                ),
              );
            }
            final member = current.items[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(member.nickname.characters.first),
                ),
                title: Text(member.nickname),
                subtitle: Text(
                  [
                    member.signature.isEmpty
                        ? 'Lv.${member.level}'
                        : member.signature,
                    if (member.joinedAt.isNotEmpty)
                      AppLocalizations.of(context).joinedAtLabel(
                        formatDisplayDateTime(
                          member.joinedAt,
                          locale: AppLocalizations.of(context).tag,
                        ),
                      ),
                  ].join('\n'),
                ),
                isThreeLine: member.joinedAt.isNotEmpty,
              ),
            );
          },
        );
      },
    ),
  );
}
