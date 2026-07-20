import 'package:dazhongdianping_app/features/community/community_repository.dart';
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
  String _auditStatus = '';
  String _auditRemark = '';

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
    final image =
        await (widget.imagePicker ?? const SystemCommunityImagePicker())
            .pickImage();
    if (image == null) return;
    setState(() => _busy = true);
    try {
      final url = await widget.repository.uploadImage(image);
      if (mounted) setState(() => _images.add(url));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
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
      ).showSnackBar(const SnackBar(content: Text('帖子已提交审核')));
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.postId == null ? '发布帖子' : '编辑帖子')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
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
                      title: Text('发布到 ${widget.circleName}'),
                      subtitle: const Text('内容仍需经过现有社区审核。'),
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
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  key: const Key('post-title'),
                  controller: _title,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: '标题'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入标题' : null,
                ),
                TextFormField(
                  key: const Key('post-content'),
                  controller: _content,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: 5000,
                  decoration: const InputDecoration(labelText: '正文'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入正文' : null,
                ),
                TextField(
                  key: const Key('post-topics'),
                  controller: _topics,
                  decoration: const InputDecoration(labelText: '话题，用逗号分隔'),
                ),
                const SizedBox(height: 12),
                Text('已上传 ${_images.length}/9'),
                OutlinedButton.icon(
                  key: const Key('post-add-image'),
                  onPressed: _busy || _images.length >= 9 ? null : _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('添加图片'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  key: const Key('post-submit'),
                  onPressed: _busy ? null : _submit,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('提交审核'),
                  ),
                ),
              ],
            ),
          ),
  );
}
