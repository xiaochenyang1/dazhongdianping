import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
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
  late Future<CommunityCommentPage> _comments;
  final _commentController = TextEditingController();
  final _reportController = TextEditingController();
  CommunityComment? _replyTarget;
  bool _favoriteSaving = false;
  bool _favorited = false;
  bool _repostSaving = false;
  bool _likeSaving = false;
  bool _commentSaving = false;
  bool _reportSaving = false;
  bool _reportDialogOpen = false;
  bool _reloadingInitial = false;
  bool _loadingMoreComments = false;
  bool _reloadingComments = false;
  int _commentRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (_reloadingInitial) return;
    final post = widget.repository.loadPost(widget.postId);
    _commentRequestId++;
    final comments = _loadComments();
    setState(() {
      _post = post;
      _comments = comments;
      _replyTarget = null;
      _loadingMoreComments = false;
      _reloadingInitial = true;
    });
    try {
      await Future.wait([post, comments]);
    } catch (_) {
      // FutureBuilders render the request errors.
    } finally {
      if (mounted) setState(() => _reloadingInitial = false);
    }
  }

  Future<void> _reloadComments() async {
    if (_reloadingComments) return;
    _commentRequestId++;
    final comments = _loadComments();
    setState(() {
      _comments = comments;
      _loadingMoreComments = false;
      _reloadingComments = true;
    });
    try {
      await comments;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloadingComments = false);
    }
  }

  Future<CommunityCommentPage> _loadComments() {
    final comments = widget.repository.loadCommentPage(widget.postId);
    comments.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return comments;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _like(CommunityPost post) async {
    if (_likeSaving) return;
    setState(() => _likeSaving = true);
    try {
      final result = await widget.repository.toggleLike(widget.postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.liked
                ? AppLocalizations.of(context).liked
                : AppLocalizations.of(context).unliked,
          ),
        ),
      );
      setState(
        () => _post = Future.value(post.copyWith(likeCount: result.likeCount)),
      );
    } catch (error) {
      if (mounted) _showMessage(AppLocalizations.of(context).likeFailed(error));
    } finally {
      if (mounted) setState(() => _likeSaving = false);
    }
  }

  Future<void> _comment(CommunityPost post) async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _commentSaving) return;
    setState(() => _commentSaving = true);
    try {
      await widget.repository.createComment(
        widget.postId,
        content,
        replyTo: _replyTarget?.id,
      );
      if (!mounted) return;
      _commentController.clear();
      _commentRequestId++;
      final refreshedComments = _loadComments();
      setState(() {
        _post = Future.value(
          post.copyWith(commentCount: post.commentCount + 1),
        );
        _comments = refreshedComments;
        _replyTarget = null;
        _loadingMoreComments = false;
      });
    } catch (error) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).commentFailed(error));
      }
    } finally {
      if (mounted) setState(() => _commentSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadMoreComments(CommunityCommentPage current) async {
    if (_loadingMoreComments || !current.hasMore) return;
    final requestId = _commentRequestId;
    setState(() => _loadingMoreComments = true);
    try {
      final next = await widget.repository.loadCommentPage(
        widget.postId,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || requestId != _commentRequestId) return;
      final knownIds = current.items.map((comment) => comment.id).toSet();
      setState(() {
        _comments = Future.value(
          CommunityCommentPage(
            items: [
              ...current.items,
              ...next.items.where((comment) => knownIds.add(comment.id)),
            ],
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && requestId == _commentRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreCommentsFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted && requestId == _commentRequestId) {
        setState(() => _loadingMoreComments = false);
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).favoriteActionFailed(error),
            ),
          ),
        );
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
        setState(() {
          _post = Future.value(
            post.copyWith(
              repostCount: result.repostCount,
              repostedByCurrentUser: result.reposted,
            ),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.reposted
                  ? AppLocalizations.of(context).reposted
                  : AppLocalizations.of(context).unreposted,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).repostFailed(error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _repostSaving = false);
    }
  }

  Future<void> _report() async {
    if (_reportSaving || _reportDialogOpen) return;
    setState(() => _reportDialogOpen = true);
    String? reason;
    try {
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context).reportPost),
          content: TextField(
            key: const Key('post-report-reason'),
            controller: _reportController,
            maxLength: 255,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).reportReason,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_reportController.text.trim()),
              child: Text(AppLocalizations.of(context).submitReport),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _reportDialogOpen = false);
    }
    if (reason == null || reason.isEmpty) return;
    setState(() => _reportSaving = true);
    try {
      await widget.repository.reportPost(widget.postId, reason);
      if (mounted) {
        _reportController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).reportSubmitted)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).reportSubmitFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reportSaving = false);
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
                        AppLocalizations.of(context).replyToPreview(
                          name: comment.replyTo!.userName,
                          content: comment.replyTo!.content,
                        ),
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
                          child: Text(AppLocalizations.of(context).reply),
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
    appBar: AppBar(title: Text(AppLocalizations.of(context).postDetail)),
    body: FutureBuilder<CommunityPost>(
      future: _post,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).postLoadFailed(snapshot.error!),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('post-detail-retry'),
                  onPressed: _reloadingInitial ? null : _loadInitial,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _reloadingInitial
                        ? AppLocalizations.of(context).processing
                        : AppLocalizations.of(context).retry,
                  ),
                ),
              ],
            ),
          );
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
                    key: const Key('post-like-button'),
                    onPressed: _likeSaving ? null : () => _like(post),
                    icon: const Icon(Icons.favorite_border),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      ).likeCountLabel(post.likeCount),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _favoriteSaving ? null : _toggleFavorite,
                    icon: Icon(
                      _favorited ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    label: Text(
                      _favorited
                          ? AppLocalizations.of(context).unfavoritePost
                          : AppLocalizations.of(context).favoritePost,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _repostSaving ? null : () => _toggleRepost(post),
                    icon: const Icon(Icons.repeat),
                    label: Text(
                      post.repostedByCurrentUser
                          ? AppLocalizations.of(
                              context,
                            ).unrepostWithCount(post.repostCount)
                          : AppLocalizations.of(
                              context,
                            ).repostWithCount(post.repostCount),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('post-report-button'),
                    onPressed: _reportSaving || _reportDialogOpen
                        ? null
                        : _report,
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(AppLocalizations.of(context).report),
                  ),
                ],
              ),
            Divider(height: 32),
            Text(
              AppLocalizations.of(context).commentsSection,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            if (widget.canInteract) ...[
              SizedBox(height: 8),
              if (_replyTarget != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).replyingToUser(_replyTarget!.userName),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearReply,
                        child: Text(AppLocalizations.of(context).cancelReply),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        ).saySomethingUsefulShort,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('post-comment-submit'),
                    onPressed: _commentSaving ? null : () => _comment(post),
                    icon: _commentSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
            FutureBuilder<CommunityCommentPage>(
              future: _comments,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          ).commentsLoadFailed(snapshot.error!),
                        ),
                        SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          key: const Key('post-comments-retry'),
                          onPressed: _reloadingComments
                              ? null
                              : _reloadComments,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            _reloadingComments
                                ? AppLocalizations.of(context).processing
                                : AppLocalizations.of(context).retryComments,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final page = snapshot.data!;
                return Column(
                  children: [
                    ...page.items.map((item) => _buildCommentItem(item)),
                    if (page.hasMore)
                      OutlinedButton.icon(
                        key: const Key('post-comments-load-more'),
                        onPressed: _loadingMoreComments
                            ? null
                            : () => _loadMoreComments(page),
                        icon: _loadingMoreComments
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(
                          _loadingMoreComments
                              ? AppLocalizations.of(context).loading
                              : AppLocalizations.of(context).loadMoreComments,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
