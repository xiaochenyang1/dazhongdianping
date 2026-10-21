import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/community/community_error_localizer.dart';
import 'package:dazhongdianping_app/features/community/post_commerce_picker_screen.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class CommunityImagePicker {
  Future<CommunityImageUpload?> pickImage();
}

class SystemCommunityImagePicker implements CommunityImagePicker {
  const SystemCommunityImagePicker();
  @override
  Future<CommunityImageUpload?> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1920,
    );
    if (file == null) return null;
    final lower = file.name.toLowerCase();
    final type =
        file.mimeType ??
        (lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg');
    return CommunityImageUpload(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      contentType: type,
    );
  }
}

class PostEditorScreen extends StatefulWidget {
  const PostEditorScreen({
    super.key,
    required this.repository,
    this.postId,
    this.imagePicker,
    this.circleId,
    this.circleName,
  });
  final CommunityRepository repository;
  final int? postId;
  final CommunityImagePicker? imagePicker;
  final int? circleId;
  final String? circleName;
  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _topics = TextEditingController();
  final List<String> _images = [];
  bool _busy = false;
  bool _loading = false;
  bool _deleting = false;
  bool _deleteDialogOpen = false;
  String? _loadError;
  int? _auditStatus;
  String _auditStatusText = '';
  String _auditRemark = '';
  int? _shopId;
  int? _dealId;
  int? _circleId;
  PostShopLink? _linkedShop;
  PostDealLink? _linkedDeal;
  bool _choosingLink = false;

  bool get _actionsBlocked =>
      _busy ||
      _loading ||
      _deleting ||
      _deleteDialogOpen ||
      _choosingLink ||
      _loadError != null;

  Future<void> _chooseShop() async {
    if (_actionsBlocked) return;
    setState(() => _choosingLink = true);
    try {
      final shop = await Navigator.of(context).push<ShopSummary>(
        MaterialPageRoute(
          builder: (_) => PostShopPickerScreen(
            repository: ApiBrowseRepository(widget.repository.api),
          ),
        ),
      );
      if (!mounted || shop == null) return;
      setState(() {
        if (_shopId != shop.id) {
          _dealId = null;
          _linkedDeal = null;
        }
        _shopId = shop.id;
        _linkedShop = PostShopLink(
          id: shop.id,
          available: true,
          name: shop.name,
        );
      });
    } finally {
      if (mounted) setState(() => _choosingLink = false);
    }
  }

  Future<void> _chooseDeal() async {
    if (_shopId == null || _actionsBlocked) return;
    setState(() => _choosingLink = true);
    try {
      final deal = await Navigator.of(context).push<DealSummary>(
        MaterialPageRoute(
          builder: (_) => PostDealPickerScreen(
            repository: TradeRepository(widget.repository.api),
            shopId: _shopId!,
          ),
        ),
      );
      if (!mounted || deal == null) return;
      setState(() {
        _dealId = deal.id;
        _linkedDeal = PostDealLink(
          id: deal.id,
          available: true,
          shopId: deal.shopId,
          title: deal.title,
          coverImage: deal.coverImage,
          price: deal.price,
          currency: deal.currency,
        );
      });
    } finally {
      if (mounted) setState(() => _choosingLink = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _circleId = widget.circleId;
    if (widget.postId != null) _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final post = await widget.repository.loadOwnedPost(widget.postId!);
      if (!mounted) return;
      setState(() {
        _title.text = post.title;
        _content.text = post.content;
        _topics.text = post.topics.join('，');
        _images
          ..clear()
          ..addAll(post.images);
        _auditStatus = post.auditStatus;
        _auditStatusText = post.auditStatusText;
        _auditRemark = post.auditRemark;
        _shopId = post.shopId;
        _dealId = post.dealId;
        _circleId = post.circleId ?? widget.circleId;
        _linkedShop = post.linkedShop;
        _linkedDeal = post.linkedDeal;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _loadError = localizeCommunityError(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _topics.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_actionsBlocked || _images.length >= 9) {
      return;
    }
    setState(() => _busy = true);
    CommunityImageUpload? image;
    try {
      try {
        image = await (widget.imagePicker ?? const SystemCommunityImagePicker())
            .pickImage();
      } catch (error) {
        if (mounted) {
          _showMessage(AppLocalizations.of(context).imagePickFailed(error));
        }
        return;
      }
      if (image == null) return;
      try {
        final url = await widget.repository.uploadImage(image);
        if (mounted) setState(() => _images.add(url));
      } catch (error) {
        if (mounted) {
          _showMessage(AppLocalizations.of(context).imageUploadFailed(error));
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_actionsBlocked) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final input = CommunityPostInput(
      title: _title.text.trim(),
      content: _content.text.trim(),
      contentType: 1,
      circleId: _circleId,
      shopId: _shopId,
      dealId: _dealId,
      images: _images,
      topics: _topics.text
          .split(RegExp('[,，]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .take(5)
          .toList(),
    );
    setState(() => _busy = true);
    try {
      final result = widget.postId == null
          ? await widget.repository.createPost(input)
          : await widget.repository.updatePost(widget.postId!, input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).postSubmittedForAudit),
        ),
      );
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) {
        final strings = AppLocalizations.of(context);
        _showMessage(
          strings.postSaveFailed(localizeCommunityError(strings, error)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete() async {
    final postId = widget.postId;
    if (postId == null || _actionsBlocked) return;
    setState(() => _deleteDialogOpen = true);
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context).deletePost),
          content: Text(AppLocalizations.of(context).deletePostConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context).cancelAction),
            ),
            FilledButton(
              key: const Key('post-delete-confirm'),
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
    setState(() => _deleting = true);
    try {
      await widget.repository.deletePost(postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).postDeleted)),
      );
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.deleteFailed(localizeCommunityError(strings, error)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Widget _commerceFields(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.postRelatedContent,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ListTile(
          key: const Key('post-choose-shop'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.storefront_outlined),
          title: Text(
            _shopId == null
                ? strings.postChooseShop
                : _linkedShop?.available == true && _linkedShop?.id == _shopId
                ? _linkedShop!.name
                : strings.postShopUnavailable,
          ),
          onTap: _actionsBlocked ? null : _chooseShop,
          trailing: _shopId == null
              ? const Icon(Icons.chevron_right)
              : IconButton(
                  key: const Key('post-remove-shop'),
                  tooltip: strings.postRemoveLink,
                  onPressed: _actionsBlocked
                      ? null
                      : () => setState(() {
                          _shopId = null;
                          _dealId = null;
                          _linkedShop = null;
                          _linkedDeal = null;
                        }),
                  icon: const Icon(Icons.close),
                ),
        ),
        ListTile(
          key: const Key('post-choose-deal'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_offer_outlined),
          title: Text(
            _dealId == null
                ? strings.postChooseDeal
                : _linkedDeal?.available == true && _linkedDeal?.id == _dealId
                ? _linkedDeal!.title
                : strings.postDealUnavailable,
          ),
          subtitle: _shopId == null ? Text(strings.postChooseShopFirst) : null,
          onTap: _shopId == null || _actionsBlocked ? null : _chooseDeal,
          trailing: _dealId == null
              ? null
              : IconButton(
                  key: const Key('post-remove-deal'),
                  tooltip: strings.postRemoveLink,
                  onPressed: _actionsBlocked
                      ? null
                      : () => setState(() {
                          _dealId = null;
                          _linkedDeal = null;
                        }),
                  icon: const Icon(Icons.close),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.postId == null
            ? AppLocalizations.of(context).publishPost
            : AppLocalizations.of(context).editPost,
      ),
      actions: [
        if (widget.postId != null)
          TextButton(
            key: const Key('post-delete-button'),
            onPressed: _actionsBlocked ? null : _delete,
            child: Text(
              _deleting
                  ? AppLocalizations.of(context).deleting
                  : AppLocalizations.of(context).delete,
            ),
          ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  ).postEditorLoadFailed(_loadError!),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('post-editor-retry'),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          )
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.circleName != null) ...[
                    Card(
                      color: const Color(0xFFFFE5D8),
                      child: ListTile(
                        leading: const Icon(Icons.groups_2_outlined),
                        title: Text(
                          AppLocalizations.of(
                            context,
                          ).publishToCircle(widget.circleName!),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context).circlePostNeedsAudit,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_auditStatus != null || _auditStatusText.isNotEmpty) ...[
                    Card(
                      color: const Color(0xFFFFF4D6),
                      child: ListTile(
                        title: Text(
                          AppLocalizations.of(context).auditStatusLabel(
                            status: _auditStatus,
                            fallback: _auditStatusText,
                          ),
                        ),
                        subtitle: _auditRemark.isEmpty
                            ? null
                            : Text(
                                AppLocalizations.of(
                                  context,
                                ).auditRemarkLabel(_auditRemark),
                              ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                  TextFormField(
                    key: const Key('post-title'),
                    controller: _title,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).titleLabel,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? AppLocalizations.of(context).pleaseEnterTitle
                        : null,
                  ),
                  TextFormField(
                    key: const Key('post-content'),
                    controller: _content,
                    minLines: 5,
                    maxLines: 10,
                    maxLength: 5000,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).bodyLabel,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? AppLocalizations.of(context).pleaseEnterBody
                        : null,
                  ),
                  TextField(
                    key: const Key('post-topics'),
                    controller: _topics,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).topicsCommaSeparated,
                    ),
                  ),
                  SizedBox(height: 12),
                  _commerceFields(context),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).uploadedCount(_images.length),
                  ),
                  OutlinedButton.icon(
                    key: const Key('post-add-image'),
                    onPressed: _actionsBlocked || _images.length >= 9
                        ? null
                        : _pick,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(AppLocalizations.of(context).addImages),
                  ),
                  SizedBox(height: 18),
                  FilledButton(
                    key: const Key('post-submit'),
                    onPressed: _actionsBlocked ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(AppLocalizations.of(context).submitForAudit),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}
