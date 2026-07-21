import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/post_editor_screen.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/circle/circle_square_screen.dart';
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
  late Future<List<CommunityPost>> _posts;
  Future<List<CommunityPost>>? _followingPosts;
  int _selectedTab = 0;
  @override
  void initState() {
    super.initState();
    _posts = widget.repository.loadFeed();
  }

  void _reload() => setState(() {
    if (_selectedTab == 0) {
      _posts = widget.repository.loadFeed();
    } else if (widget.canInteract) {
      _followingPosts = widget.repository.loadFollowingFeed();
    }
  });

  void _selectTab(int index) {
    setState(() {
      _selectedTab = index;
      if (index == 1 && widget.canInteract && _followingPosts == null) {
        _followingPosts = widget.repository.loadFollowingFeed();
      }
    });
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('华人社区'),
        actions: [
          if (widget.topicRepository != null)
            IconButton(
              tooltip: '话题广场',
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
              tooltip: '同城圈子',
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
          tabs: const [
            Tab(text: '推荐'),
            Tab(text: '关注'),
          ],
        ),
      ),
      floatingActionButton: widget.canInteract
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PostEditorScreen(repository: widget.repository),
                  ),
                );
                if (!mounted) return;
                _reload();
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('发帖'),
            )
          : null,
      body: _selectedTab == 1 && !widget.canInteract
          ? const Center(child: Text('登录后查看关注流，关注的人更新时会出现在这里。'))
          : RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<CommunityPost>>(
                future: _selectedTab == 0 ? _posts : _followingPosts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('社区加载失败：${snapshot.error}'));
                  }
                  final posts = snapshot.data ?? const [];
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                repository: widget.repository,
                                postId: post.id,
                                canInteract: widget.canInteract,
                                onUserTap: widget.onUserTap,
                              ),
                            ),
                          ),
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
                                  crossAxisAlignment: WrapCrossAlignment.center,
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
                                      ' · ❤ ${post.likeCount} · 评论 ${post.commentCount}',
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
