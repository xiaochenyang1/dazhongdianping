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
  late Future<List<CommunityPost>> posts;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    posts = widget.repository.loadPosts(topic.id);
  }

  Future<void> toggleFollow() async {
    if (!widget.canInteract) {
      widget.onLoginRequired?.call();
      return;
    }
    final before = topic;
    setState(() {
      saving = true;
      topic = topic.withFollow(!topic.followed, topic.followerCount + (topic.followed ? -1 : 1));
    });
    try {
      final result = before.followed
          ? await widget.repository.unfollow(topic.id)
          : await widget.repository.follow(topic.id);
      if (mounted) setState(() => topic = topic.withFollow(result.followed, result.followerCount));
    } catch (error) {
      if (mounted) {
        setState(() => topic = before);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('关注状态更新失败：$error')));
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
            boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text('热度 ${topic.hotScore}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text('7 天：${topic.postCount7d} 帖 · ${topic.likeCount7d} 赞 · ${topic.commentCount7d} 评论'),
              const SizedBox(height: 14),
              Text('${topic.followerCount} 人关注'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : toggleFollow,
                  icon: Icon(topic.followed ? Icons.bookmark_added : Icons.bookmark_add_outlined),
                  label: Text(topic.followed ? '已关注' : '关注话题'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('公开帖子', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        FutureBuilder<List<CommunityPost>>(
          future: posts,
          builder: (_, snapshot) {
            if (snapshot.hasError) return Text('帖子加载失败：${snapshot.error}');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('这里还没有公开帖子。')));
            return Column(
              children: snapshot.data!.map((post) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text('❤ ${post.likeCount}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        repository: CommunityRepository(widget.repository.api),
                        postId: post.id,
                        canInteract: widget.canInteract,
                        onUserTap: widget.onUserTap,
                      ),
                    ),
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    ),
  );
}
