import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/review/review_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_error_localizer.dart';
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
  bool _deleteDialogOpen = false;
  bool _reportSaving = false;
  bool _reportDialogOpen = false;
  bool _reloadingReview = false;
  bool _loadingMoreComments = false;
  bool _reloadingComments = false;
  int _reviewRequestId = 0;
  int _commentRequestId = 0;

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

  Future<ReviewCommentPage> _loadComments() {
    final future = widget.repository.loadCommentPage(widget.reviewId);
    future.ignore();
    return future;
  }

  Future<void> _reloadReview() async {
    if (_reloadingReview) return;
    final requestId = ++_reviewRequestId;
    final future = _loadReview();
    setState(() {
      _review = future;
      _visibleReview = null;
      _comments = null;
      _replyTarget = null;
      _loadingMoreComments = false;
      _reloadingReview = true;
      _commentRequestId++;
    });
    try {
      final detail = await future;
      if (!mounted || requestId != _reviewRequestId) return;
      setState(() {
        _visibleReview = detail;
        if (_shouldShowComments(detail)) {
          _commentRequestId++;
          _comments = _loadComments();
        }
      });
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloadingReview = false);
    }
  }

  bool _shouldShowComments(ReviewDetail detail) =>
      !widget.owned && detail.canInteract;

  bool _interactionAllowed(ReviewDetail detail) =>
      widget.canInteract && !widget.owned && detail.canInteract;

  Future<void> _reloadComments() async {
    if (_reloadingComments) return;
    final future = _loadComments();
    _commentRequestId++;
    setState(() {
      _comments = future;
      _replyTarget = null;
      _loadingMoreComments = false;
      _reloadingComments = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloadingComments = false);
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.liked
                ? AppLocalizations.of(context).liked
                : AppLocalizations.of(context).unliked,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).likeFailed(
              localizeReviewError(AppLocalizations.of(context), error),
            ),
          ),
        ),
      );
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
        _commentRequestId++;
        _comments = _loadComments();
        _visibleReview = detail.copyWith(commentCount: detail.commentCount + 1);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commentPublished)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).commentFailed(
              localizeReviewError(AppLocalizations.of(context), error),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _commentSaving = false);
    }
  }

  Future<void> _loadMoreComments(ReviewCommentPage current) async {
    if (_loadingMoreComments || !current.hasMore) return;
    final requestId = _commentRequestId;
    setState(() => _loadingMoreComments = true);
    try {
      final next = await widget.repository.loadCommentPage(
        widget.reviewId,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || requestId != _commentRequestId) return;
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
      if (mounted && requestId == _commentRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreCommentsFailed(
                localizeReviewError(AppLocalizations.of(context), error),
              ),
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

  Future<void> _reportReview() async {
    if (_reportSaving || _reportDialogOpen) return;
    setState(() => _reportDialogOpen = true);
    String? reason;
    try {
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context).reportReview),
          content: TextField(
            key: const Key('review-report-reason'),
            controller: _reportController,
            maxLength: 200,
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
      await widget.repository.reportReview(widget.reviewId, reason);
      if (!mounted) return;
      _reportController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reportSubmitted)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).reportFailed(
              localizeReviewError(AppLocalizations.of(context), error),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _reportSaving = false);
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
    if (!widget.owned || _deleteSaving || _deleteDialogOpen) return;
    setState(() => _deleteDialogOpen = true);
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context).deleteReview),
          content: Text(AppLocalizations.of(context).deleteReviewConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context).cancelAction),
            ),
            FilledButton(
              key: const Key('review-delete-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context).confirmDelete),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _deleteDialogOpen = false);
    }
    if (confirmed != true) return;
    setState(() => _deleteSaving = true);
    try {
      await widget.repository.deleteReview(widget.reviewId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reviewDeleted)),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).deleteFailed(
              localizeReviewError(AppLocalizations.of(context), error),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleteSaving = false);
    }
  }

  Widget _buildCommentItem(ReviewComment comment, {double indent = 0}) =>
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
                      if (widget.canInteract && !widget.owned)
                        TextButton(
                          key: Key('review-comment-reply-${comment.id}'),
                          onPressed: () =>
                              setState(() => _replyTarget = comment),
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
    appBar: AppBar(
      title: Text(
        widget.owned
            ? AppLocalizations.of(context).myReviewDetail
            : AppLocalizations.of(context).reviewDetail,
      ),
      actions: [
        if (widget.owned) ...[
          TextButton(
            onPressed:
                _visibleReview == null || _deleteSaving || _deleteDialogOpen
                ? null
                : () => _openEditor(_visibleReview!),
            child: Text(AppLocalizations.of(context).edit),
          ),
          TextButton(
            key: const Key('review-delete-button'),
            onPressed: _deleteSaving || _deleteDialogOpen
                ? null
                : _deleteOwnedReview,
            child: Text(
              _deleteSaving
                  ? AppLocalizations.of(context).deleting
                  : AppLocalizations.of(context).delete,
            ),
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
                Text(
                  AppLocalizations.of(context).reviewDetailLoadFailed(
                    localizeReviewError(
                      AppLocalizations.of(context),
                      snapshot.error!,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('review-detail-retry'),
                  onPressed: _reloadingReview ? null : _reloadReview,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _reloadingReview
                        ? AppLocalizations.of(context).processing
                        : AppLocalizations.of(context).retry,
                  ),
                ),
              ],
            ),
          );
        }
        final review = _visibleReview ?? snapshot.data!;
        final showInteraction = _interactionAllowed(review);
        final showComments = _shouldShowComments(review);
        final auditStatusText = AppLocalizations.of(context).auditStatusLabel(
          status: review.auditStatus,
          fallback: review.auditStatusText,
        );
        final showAuditStatus =
            review.auditStatusText.isNotEmpty ||
            switch (review.auditStatus) {
              0 || 1 || 2 => true,
              _ => false,
            };
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
                  review.userName.isEmpty
                      ? AppLocalizations.of(context).anonymousUser
                      : review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (AppLocalizations.of(context)
                    .certificationBadgeLabel(
                      code: review.authorCertificationCode,
                      fallback: review.authorCertificationLabel,
                    )
                    .isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.verified, size: 16),
                    label: Text(
                      AppLocalizations.of(context).certificationBadgeLabel(
                        code: review.authorCertificationCode,
                        fallback: review.authorCertificationLabel,
                      ),
                    ),
                  ),
                Text('★ ${review.scoreOverall.toStringAsFixed(1)}'),
                if (showAuditStatus) Chip(label: Text(auditStatusText)),
              ],
            ),
            if (widget.owned && review.auditRemark.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFFFF7ED),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).auditRemarkLabel(review.auditRemark),
                  ),
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
              '${AppLocalizations.of(context).scoreTaste} ${review.scoreTaste.toStringAsFixed(1)} · ${AppLocalizations.of(context).scoreEnv} ${review.scoreEnv.toStringAsFixed(1)} · ${AppLocalizations.of(context).scoreService} ${review.scoreService.toStringAsFixed(1)}'
              '${review.cost > 0 ? ' · ${AppLocalizations.of(context).averageSpendLabel(amount: formatMoney(review.cost, review.currency, locale: AppLocalizations.of(context).tag))}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (review.merchantReply != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).merchantReplyLabel(review.merchantReply!),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${AppLocalizations.of(context).likeCommentStats(likes: review.likeCount, comments: review.commentCount)}${review.createdAt.isEmpty ? '' : ' · ${review.createdAt}'}',
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
                      label: Text(
                        review.likedByCurrentUser
                            ? AppLocalizations.of(context).liked
                            : AppLocalizations.of(context).like,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('review-report-button'),
                      onPressed: _reportSaving || _reportDialogOpen
                          ? null
                          : _reportReview,
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(AppLocalizations.of(context).report),
                    ),
                  ),
                ],
              ),
            ] else if (!widget.owned &&
                !widget.canInteract &&
                review.canInteract)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context).reviewLoginToInteract,
                    ),
                  ),
                ),
              ),
            if (showComments) ...[
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).commentsSection,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
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
                            AppLocalizations.of(
                              context,
                            ).replyingTo(_replyTarget!.userName),
                            key: const Key('review-reply-target'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _replyTarget = null),
                          child: Text(
                            AppLocalizations.of(context).cancelAction,
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  key: const Key('review-comment-input'),
                  controller: _commentController,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).writeComment,
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
                    child: Text(
                      _commentSaving
                          ? AppLocalizations.of(context).publishing
                          : AppLocalizations.of(context).publishComment,
                    ),
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).commentsLoadFailed(
                            localizeReviewError(
                              AppLocalizations.of(context),
                              commentSnapshot.error!,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          key: const Key('review-comments-retry'),
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
                    );
                  }
                  final page = commentSnapshot.data!;
                  final comments = page.items;
                  if (comments.isEmpty) {
                    return Text(AppLocalizations.of(context).noComments);
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
          ],
        );
      },
    ),
  );
}
