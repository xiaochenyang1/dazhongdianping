import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:flutter/material.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.repository,
    required this.postId,
    required this.canInteract,
    this.onUserTap,
  });
  final CommunityRepository repository;
  final int postId;
  final bool canInteract;
  final void Function(BuildContext, int)? onUserTap;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<CommunityPost> _post;
  late Future<List<CommunityComment>> _comments;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.repository.loadPost(widget.postId);
    _comments = widget.repository.loadComments(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _like() async {
    final result = await widget.repository.toggleLike(widget.postId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.liked ? '已点赞' : '已取消点赞')));
    }
    setState(() => _post = widget.repository.loadPost(widget.postId));
  }

  Future<void> _comment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    await widget.repository.createComment(widget.postId, content);
    _commentController.clear();
    setState(() => _comments = widget.repository.loadComments(widget.postId));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('帖子详情')),
    body: FutureBuilder<CommunityPost>(
      future: _post,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('帖子加载失败：${snapshot.error}'));
        }
        final post = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              post.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: widget.onUserTap == null
                      ? null
                      : () => widget.onUserTap!(context, post.userId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      post.userName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Text(' · ${post.createdAt}'),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: post.topics
                  .map((topic) => Chip(label: Text('#$topic')))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Text(
              post.content,
              style: const TextStyle(fontSize: 17, height: 1.65),
            ),
            const SizedBox(height: 16),
            if (widget.canInteract)
              OutlinedButton.icon(
                onPressed: _like,
                icon: const Icon(Icons.favorite_border),
                label: Text('点赞 ${post.likeCount}'),
              ),
            const Divider(height: 32),
            const Text(
              '评论',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            if (widget.canInteract) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(hintText: '说点有用的'),
                    ),
                  ),
                  IconButton(onPressed: _comment, icon: const Icon(Icons.send)),
                ],
              ),
            ],
            FutureBuilder<List<CommunityComment>>(
              future: _comments,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Column(
                  children: snapshot.data!
                      .map(
                        (item) => ListTile(
                          title: Text(item.userName),
                          subtitle: Text(item.content),
                          trailing: Text(item.createdAt),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
