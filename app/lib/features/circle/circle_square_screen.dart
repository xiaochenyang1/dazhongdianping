import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:flutter/material.dart';

class CircleSquareScreen extends StatelessWidget {
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('同城圈子')),
    body: FutureBuilder<List<AppCircle>>(
      future: showJoinedOnly
          ? repository.loadMyCircles()
          : repository.loadCircles(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('圈子加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, index) => _CircleCard(
            circle: snapshot.data![index],
            colors: _colors(index),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CircleDetailScreen(
                  repository: repository,
                  initial: snapshot.data![index],
                  canInteract: canInteract,
                  onLoginRequired: onLoginRequired,
                  onCreatePost: onCreatePost,
                ),
              ),
            ),
          ),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
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
                '${circle.memberCount} 位成员 · ${circle.postCount} 篇帖子',
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
  late Future<List<CommunityPost>> posts;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    posts = widget.repository.loadPosts(circle.id);
  }

  Future<void> toggle() async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('圈子状态更新失败：$error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
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
                '${circle.memberCount} 位成员 · ${circle.postCount} 篇帖子',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : toggle,
                      child: Text(circle.joined ? '已加入' : '加入圈子'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CircleMembersScreen(
                          repository: widget.repository,
                          circle: circle,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.group_outlined),
                    tooltip: '查看成员',
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
            label: const Text('在圈子发帖'),
          )
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('加入圈子后即可发布内容，历史帖子公开可见。'),
            ),
          ),
        const SizedBox(height: 22),
        const Text(
          '圈子新帖',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<CommunityPost>>(
          future: posts,
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? Text('帖子加载失败：${snapshot.error}')
                  : const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('这里还没有公开帖子。'),
                ),
              );
            }
            return Column(
              children: snapshot.data!
                  .map(
                    (post) => Card(
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
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(
                              repository: CommunityRepository(
                                widget.repository.api,
                              ),
                              postId: post.id,
                              canInteract: widget.canInteract,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class CircleMembersScreen extends StatelessWidget {
  const CircleMembersScreen({
    super.key,
    required this.repository,
    required this.circle,
  });
  final CircleRepository repository;
  final AppCircle circle;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${circle.name}成员')),
    body: FutureBuilder<List<CircleMember>>(
      future: repository.loadMembers(circle.id),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return snapshot.hasError
              ? Center(child: Text('成员加载失败：${snapshot.error}'))
              : const Center(child: CircularProgressIndicator());
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final member = snapshot.data![i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(member.nickname.characters.first),
                ),
                title: Text(member.nickname),
                subtitle: Text(
                  member.signature.isEmpty
                      ? 'Lv.${member.level}'
                      : member.signature,
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
