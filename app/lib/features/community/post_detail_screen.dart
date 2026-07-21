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
  final _reportController = TextEditingController();
  CommunityComment? _replyTarget;
  bool _favoriteSaving = false;
  bool _favorited = false;
  bool _repostSaving = false;

  @override
  void initState() {
    super.initState();
    _post = widget.repository.loadPost(widget.postId);
    _comments = widget.repository.loadComments(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _like() async {
    final result = await widget.repository.toggleLike(widget.postId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.liked ? '已点赞' : '已取消点赞')));
    final refreshedPost = widget.repository.loadPost(widget.postId);
    setState(() {
      _post = refreshedPost;
    });
  }

  Future<void> _comment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    await widget.repository.createComment(
      widget.postId,
      content,
      replyTo: _replyTarget?.id,
    );
    if (!mounted) return;
    _commentController.clear();
    final refreshedComments = widget.repository.loadComments(widget.postId);
    final refreshedPost = widget.repository.loadPost(widget.postId);
    setState(() {
      _post = refreshedPost;
      _comments = refreshedComments;
      _replyTarget = null;
    });
  }

  void _selectReply(CommunityComment comment) {
    setState(() => _replyTarget = comment);
  }

  void _clearReply() {
    setState(() => _replyTarget = null);
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteSaving) return;
    setState(() => _favoriteSaving = true);
    try {
      if (_favorited) {
        await widget.repository.unfavoritePost(widget.postId);
      } else {
        await widget.repository.favoritePost(widget.postId);
      }
      if (mounted) setState(() => _favorited = !_favorited);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('收藏操作失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _favoriteSaving = false);
    }
  }

  Future<void> _toggleRepost(CommunityPost post) async {
    if (_repostSaving) return;
    setState(() => _repostSaving = true);
    try {
      final result = post.repostedByCurrentUser
          ? await widget.repository.removeRepost(widget.postId)
          : await widget.repository.repostPost(widget.postId);
      if (mounted) {
        final refreshedPost = widget.repository.loadPost(widget.postId);
        setState(() {
          _post = refreshedPost;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.reposted ? '已转发' : '已取消转发')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('转发操作失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _repostSaving = false);
    }
  }

  Future<void> _report() async {
    _reportController.clear();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('举报帖子'),
        content: TextField(
          key: const Key('post-report-reason'),
          controller: _reportController,
          maxLength: 255,
          maxLines: 4,
          decoration: const InputDecoration(labelText: '举报理由'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_reportController.text.trim()),
            child: const Text('提交举报'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await widget.repository.reportPost(widget.postId, reason);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('举报已提交')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('举报提交失败：$error')));
      }
    }
  }

  Widget _buildCommentItem(CommunityComment comment, {double indent = 0}) =>
      Padding(
        padding: EdgeInsets.only(left: indent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(comment.userName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comment.replyTo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '回复 ${comment.replyTo!.userName}：${comment.replyTo!.content}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Text(comment.content),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(comment.createdAt),
                      if (widget.canInteract)
                        TextButton(
                          key: Key('comment-reply-${comment.id}'),
                          onPressed: () => _selectReply(comment),
                          child: const Text('回复'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  children: comment.replies
                      .map((reply) => _buildCommentItem(reply, indent: 8))
                      .toList(),
                ),
              ),
          ],
        ),
      );

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
            if (post.images.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: post.images.length,
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        post.images[index],
                        key: Key('post-image-$index'),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE9E4DE),
                          child: Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.canInteract)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _like,
                    icon: const Icon(Icons.favorite_border),
                    label: Text('点赞 ${post.likeCount}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _favoriteSaving ? null : _toggleFavorite,
                    icon: Icon(
                      _favorited ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    label: Text(_favorited ? '取消收藏' : '收藏帖子'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _repostSaving ? null : () => _toggleRepost(post),
                    icon: const Icon(Icons.repeat),
                    label: Text(
                      post.repostedByCurrentUser
                          ? '取消转发 ${post.repostCount}'
                          : '转发 ${post.repostCount}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _report,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('举报'),
                  ),
                ],
              ),
            const Divider(height: 32),
            const Text(
              '评论',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            if (widget.canInteract) ...[
              const SizedBox(height: 8),
              if (_replyTarget != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('正在回复 ${_replyTarget!.userName}'),
                      ),
                      TextButton(
                        onPressed: _clearReply,
                        child: const Text('取消回复'),
                      ),
                    ],
                  ),
                ),
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
                      .map((item) => _buildCommentItem(item))
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
