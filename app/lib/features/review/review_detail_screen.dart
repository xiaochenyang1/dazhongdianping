import 'package:dazhongdianping_app/features/review/review_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter/material.dart';

class ReviewDetailScreen extends StatefulWidget {
  const ReviewDetailScreen({
    super.key,
    required this.repository,
    required this.reviewId,
    this.owned = false,
    this.canInteract = true,
  });

  final ReviewRepository repository;
  final int reviewId;
  final bool owned;
  final bool canInteract;

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  late Future<ReviewDetail> _review;
  Future<ReviewCommentPage>? _comments;
  final _commentController = TextEditingController();
  final _reportController = TextEditingController();
  ReviewDetail? _visibleReview;
  ReviewComment? _replyTarget;
  bool _likeSaving = false;
  bool _commentSaving = false;
  bool _deleteSaving = false;
  bool _loadingMoreComments = false;
  int _reviewRequestId = 0;

  @override
  void initState() {
    super.initState();
    _reloadReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  Future<ReviewDetail> _loadReview() => widget.owned
      ? widget.repository.loadOwnedReviewDetail(widget.reviewId)
      : widget.repository.loadPublicReview(widget.reviewId);

  void _reloadReview() {
    final requestId = ++_reviewRequestId;
    final future = _loadReview();
    setState(() {
      _review = future;
      _visibleReview = null;
      _comments = null;
      _replyTarget = null;
    });
    future
        .then((detail) {
          if (!mounted || requestId != _reviewRequestId) return;
          setState(() {
            _visibleReview = detail;
            if (_shouldShowComments(detail)) {
              _comments = widget.repository.loadCommentPage(widget.reviewId);
            }
          });
        })
        .catchError((_) {});
  }

  bool _shouldShowComments(ReviewDetail detail) =>
      !widget.owned && detail.canInteract;

  bool _interactionAllowed(ReviewDetail detail) =>
      widget.canInteract && !widget.owned && detail.canInteract;

  Future<void> _toggleLike(ReviewDetail detail) async {
    if (_likeSaving || !_interactionAllowed(detail)) return;
    setState(() => _likeSaving = true);
    try {
      final result = await widget.repository.toggleLike(widget.reviewId);
      if (!mounted) return;
      setState(() {
        _visibleReview = detail.copyWith(
          likedByCurrentUser: result.liked,
          likeCount: result.likeCount,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.liked ? '已点赞' : '已取消点赞')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('点赞失败：$error')));
    } finally {
      if (mounted) setState(() => _likeSaving = false);
    }
  }

  Future<void> _submitComment(ReviewDetail detail) async {
    if (_commentSaving || !_interactionAllowed(detail)) return;
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _commentSaving = true);
    try {
      await widget.repository.createComment(
        widget.reviewId,
        content,
        replyTo: _replyTarget?.id,
      );
      if (!mounted) return;
      _commentController.clear();
      setState(() {
        _replyTarget = null;
        _comments = widget.repository.loadCommentPage(widget.reviewId);
        _visibleReview = detail.copyWith(commentCount: detail.commentCount + 1);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('评论已发布')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('评论失败：$error')));
    } finally {
      if (mounted) setState(() => _commentSaving = false);
    }
  }

  Future<void> _loadMoreComments(ReviewCommentPage current) async {
    if (_loadingMoreComments || !current.hasMore) return;
    setState(() => _loadingMoreComments = true);
    try {
      final next = await widget.repository.loadCommentPage(
        widget.reviewId,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted) return;
      final knownIds = current.items.map((comment) => comment.id).toSet();
      setState(() {
        _comments = Future.value(
          ReviewCommentPage(
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多评论失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _loadingMoreComments = false);
    }
  }

  Future<void> _reportReview() async {
    _reportController.clear();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('举报点评'),
        content: TextField(
          key: const Key('review-report-reason'),
          controller: _reportController,
          maxLength: 200,
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
      await widget.repository.reportReview(widget.reviewId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('举报已提交')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('举报失败：$error')));
    }
  }

  void _openEditor(ReviewDetail detail) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ReviewEditorScreen(
              repository: widget.repository,
              reviewId: detail.id,
              shopId: detail.shopId,
              shopName: detail.shopName,
              currency: detail.currency,
            ),
          ),
        )
        .then((_) {
          if (mounted) _reloadReview();
        });
  }

  Future<void> _deleteOwnedReview() async {
    if (!widget.owned || _deleteSaving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除点评'),
        content: const Text('删除后不可恢复，确认删除这条点评吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('review-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleteSaving = true);
    try {
      await widget.repository.deleteReview(widget.reviewId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('点评已删除')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$error')));
    } finally {
      if (mounted) setState(() => _deleteSaving = false);
    }
  }

  Widget _buildCommentItem(
    ReviewComment comment, {
    double indent = 0,
  }) => Padding(
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
                  if (widget.canInteract && !widget.owned)
                    TextButton(
                      key: Key('review-comment-reply-${comment.id}'),
                      onPressed: () => setState(() => _replyTarget = comment),
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
    appBar: AppBar(
      title: Text(widget.owned ? '我的点评详情' : '点评详情'),
      actions: [
        if (widget.owned) ...[
          TextButton(
            onPressed: _visibleReview == null || _deleteSaving
                ? null
                : () => _openEditor(_visibleReview!),
            child: const Text('编辑'),
          ),
          TextButton(
            key: const Key('review-delete-button'),
            onPressed: _deleteSaving ? null : _deleteOwnedReview,
            child: Text(_deleteSaving ? '删除中...' : '删除'),
          ),
        ],
      ],
    ),
    body: FutureBuilder<ReviewDetail>(
      future: _review,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('点评详情加载失败：${snapshot.error}'),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('review-detail-retry'),
                  onPressed: _reloadReview,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }
        final review = _visibleReview ?? snapshot.data!;
        final showInteraction = _interactionAllowed(review);
        final showComments = _shouldShowComments(review);
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              review.shopName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  review.userName.isEmpty ? '匿名用户' : review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (review.authorCertificationLabel != null)
                  Chip(
                    avatar: const Icon(Icons.verified, size: 16),
                    label: Text(review.authorCertificationLabel!),
                  ),
                Text('★ ${review.scoreOverall.toStringAsFixed(1)}'),
                if (review.auditStatusText.isNotEmpty)
                  Chip(label: Text(review.auditStatusText)),
              ],
            ),
            if (widget.owned && review.auditRemark.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFFFF7ED),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('审核备注：${review.auditRemark}'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(review.content),
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: review.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
            ],
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: review.images
                    .map(
                      (url) => Chip(
                        avatar: const Icon(Icons.image_outlined, size: 16),
                        label: Text(
                          url.length > 24
                              ? '...${url.substring(url.length - 20)}'
                              : url,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '口味 ${review.scoreTaste.toStringAsFixed(1)} · 环境 ${review.scoreEnv.toStringAsFixed(1)} · 服务 ${review.scoreService.toStringAsFixed(1)}'
              '${review.cost > 0 ? ' · 人均 ${review.currency} ${review.cost.toStringAsFixed(0)}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (review.merchantReply != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('商家回复：${review.merchantReply}'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '点赞 ${review.likeCount} · 评论 ${review.commentCount}'
              '${review.createdAt.isEmpty ? '' : ' · ${review.createdAt}'}',
            ),
            if (showInteraction) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const Key('review-like-button'),
                      onPressed: _likeSaving ? null : () => _toggleLike(review),
                      icon: Icon(
                        review.likedByCurrentUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      label: Text(review.likedByCurrentUser ? '已点赞' : '点赞'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('review-report-button'),
                      onPressed: _reportReview,
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('举报'),
                    ),
                  ),
                ],
              ),
            ] else if (!widget.owned &&
                !widget.canInteract &&
                review.canInteract)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('登录后可点赞、评论和举报这条点评。'),
                  ),
                ),
              ),
            if (showComments) ...[
              const SizedBox(height: 24),
              const Text(
                '评论',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (showInteraction) ...[
                if (_replyTarget != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '回复 ${_replyTarget!.userName}',
                            key: const Key('review-reply-target'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _replyTarget = null),
                          child: const Text('取消'),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  key: const Key('review-comment-input'),
                  controller: _commentController,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '写评论',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('review-comment-submit'),
                    onPressed: _commentSaving
                        ? null
                        : () => _submitComment(review),
                    child: Text(_commentSaving ? '发布中...' : '发布评论'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FutureBuilder<ReviewCommentPage>(
                future: _comments,
                builder: (context, commentSnapshot) {
                  if (_comments == null ||
                      commentSnapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (commentSnapshot.hasError) {
                    return Text('评论加载失败：${commentSnapshot.error}');
                  }
                  final page = commentSnapshot.data!;
                  final comments = page.items;
                  if (comments.isEmpty) {
                    return const Text('暂无评论');
                  }
                  return Column(
                    children: [
                      ...comments.map((comment) => _buildCommentItem(comment)),
                      if (page.hasMore)
                        OutlinedButton.icon(
                          key: const Key('review-comments-load-more'),
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
                            _loadingMoreComments ? '加载中...' : '加载更多评论',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        );
      },
    ),
  );
}
