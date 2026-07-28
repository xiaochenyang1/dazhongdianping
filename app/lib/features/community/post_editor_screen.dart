import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
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
  String _auditStatus = '';
  String _auditRemark = '';

  @override
  void initState() {
    super.initState();
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
        _auditStatus = post.auditStatusText;
        _auditRemark = post.auditRemark;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = '$error');
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
    if (_busy ||
        _loading ||
        _deleting ||
        _deleteDialogOpen ||
        _images.length >= 9) {
      return;
    }
    setState(() => _busy = true);
    CommunityImageUpload? image;
    try {
      try {
        image = await (widget.imagePicker ?? const SystemCommunityImagePicker())
            .pickImage();
      } catch (error) {
        if (mounted) _showMessage(AppLocalizations.of(context).imagePickFailed(error));
        return;
      }
      if (image == null) return;
      try {
        final url = await widget.repository.uploadImage(image);
        if (mounted) setState(() => _images.add(url));
      } catch (error) {
        if (mounted) _showMessage(AppLocalizations.of(context).imageUploadFailed(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy ||
        _loading ||
        _deleting ||
        _deleteDialogOpen ||
        _loadError != null) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final input = CommunityPostInput(
      title: _title.text.trim(),
      content: _content.text.trim(),
      contentType: 1,
      circleId: widget.circleId,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).postSubmittedForAudit)));
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) _showMessage(AppLocalizations.of(context).postSaveFailed(error));
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
    if (postId == null || _deleting || _busy || _deleteDialogOpen) return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).postDeleted)));
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).deleteFailed(error))));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.postId == null ? AppLocalizations.of(context).publishPost : AppLocalizations.of(context).editPost),
      actions: [
        if (widget.postId != null)
          TextButton(
            key: const Key('post-delete-button'),
            onPressed:
                _deleting ||
                    _deleteDialogOpen ||
                    _busy ||
                    _loading ||
                    _loadError != null
                ? null
                : _delete,
            child: Text(_deleting ? AppLocalizations.of(context).deleting : AppLocalizations.of(context).delete),
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
                Text(AppLocalizations.of(context).postEditorLoadFailed(_loadError!)),
                SizedBox(height: 12),
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
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (widget.circleName != null) ...[
                  Card(
                    color: const Color(0xFFFFE5D8),
                    child: ListTile(
                      leading: const Icon(Icons.groups_2_outlined),
                      title: Text(AppLocalizations.of(context).publishToCircle(widget.circleName!)),
                      subtitle: Text(AppLocalizations.of(context).circlePostNeedsAudit),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_auditStatus.isNotEmpty) ...[
                  Card(
                    color: const Color(0xFFFFF4D6),
                    child: ListTile(
                      title: Text(_auditStatus),
                      subtitle: _auditRemark.isEmpty
                          ? null
                          : Text(_auditRemark),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
                TextFormField(
                  key: const Key('post-title'),
                  controller: _title,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).titleLabel),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? AppLocalizations.of(context).pleaseEnterTitle : null,
                ),
                TextFormField(
                  key: const Key('post-content'),
                  controller: _content,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: 5000,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).bodyLabel),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? AppLocalizations.of(context).pleaseEnterBody : null,
                ),
                TextField(
                  key: const Key('post-topics'),
                  controller: _topics,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).topicsCommaSeparated),
                ),
                SizedBox(height: 12),
                Text(AppLocalizations.of(context).uploadedCount(_images.length)),
                OutlinedButton.icon(
                  key: const Key('post-add-image'),
                  onPressed: _busy || _deleteDialogOpen || _images.length >= 9
                      ? null
                      : _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(AppLocalizations.of(context).addImages),
                ),
                SizedBox(height: 18),
                FilledButton(
                  key: const Key('post-submit'),
                  onPressed: _busy || _deleteDialogOpen ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(AppLocalizations.of(context).submitForAudit),
                  ),
                ),
              ],
            ),
          ),
  );
}
