import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:flutter/material.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({
    super.key,
    required this.repository,
    required this.initial,
    required this.canInteract,
    this.onLoginRequired,
    this.onUserTap,
  });

  final TopicRepository repository;
  final TopicSummary initial;
  final bool canInteract;
  final VoidCallback? onLoginRequired;
  final void Function(BuildContext, int)? onUserTap;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late TopicSummary topic = widget.initial;
  late Future<CommunityPostPage> posts;
  bool saving = false;
  bool loadingMore = false;
  bool reloading = false;
  int postsRequestId = 0;
  final Set<int> _openingPostIds = <int>{};

  @override
  void initState() {
    super.initState();
    posts = widget.repository.loadPostPage(topic.id);
  }

  Future<void> reloadPosts() async {
    if (reloading) return;
    final future = widget.repository.loadPostPage(topic.id);
    postsRequestId++;
    setState(() {
      posts = future;
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

  Future<void> loadMore(CommunityPostPage current) async {
    if (loadingMore || !current.hasMore) return;
    final requestId = postsRequestId;
    setState(() => loadingMore = true);
    try {
      final next = await widget.repository.loadPostPage(
        topic.id,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多帖子失败：$error')));
      }
    } finally {
      if (mounted && requestId == postsRequestId) {
        setState(() => loadingMore = false);
      }
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

  Future<void> toggleFollow() async {
    if (saving) return;
    if (!widget.canInteract) {
      widget.onLoginRequired?.call();
      return;
    }
    final before = topic;
    setState(() {
      saving = true;
      topic = topic.withFollow(
        !topic.followed,
        topic.followerCount + (topic.followed ? -1 : 1),
      );
    });
    try {
      final result = before.followed
          ? await widget.repository.unfollow(topic.id)
          : await widget.repository.follow(topic.id);
      if (mounted) {
        setState(
          () => topic = topic.withFollow(result.followed, result.followerCount),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => topic = before);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('关注状态更新失败：$error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('#${topic.name}')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE7DA),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.name,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '热度 ${topic.hotScore}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '7 天：${topic.postCount7d} 帖 · ${topic.likeCount7d} 赞 · ${topic.commentCount7d} 评论',
              ),
              const SizedBox(height: 14),
              Text('${topic.followerCount} 人关注'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('topic-follow-toggle'),
                  onPressed: saving ? null : toggleFollow,
                  icon: Icon(
                    topic.followed
                        ? Icons.bookmark_added
                        : Icons.bookmark_add_outlined,
                  ),
                  label: Text(topic.followed ? '已关注' : '关注话题'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '公开帖子',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        FutureBuilder<CommunityPostPage>(
          future: posts,
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('帖子加载失败：${snapshot.error}'),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    key: const Key('topic-posts-retry'),
                    onPressed: reloading ? null : reloadPosts,
                    icon: const Icon(Icons.refresh),
                    label: Text(reloading ? '处理中...' : '重试'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final page = snapshot.data!;
            if (page.items.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('这里还没有公开帖子。'),
                ),
              );
            }
            return Column(
              children: [
                ...page.items.map(
                  (post) => Card(
                    key: Key('topic-post-card-${post.id}'),
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
                    key: const Key('topic-posts-load-more'),
                    onPressed: loadingMore ? null : () => loadMore(page),
                    icon: loadingMore
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(loadingMore ? '加载中...' : '加载更多'),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
