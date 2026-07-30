import 'dart:typed_data';

import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class ReviewImagePicker {
  Future<ReviewImageUpload?> pickImage();
}

class SystemReviewImagePicker implements ReviewImagePicker {
  const SystemReviewImagePicker();

  @override
  Future<ReviewImageUpload?> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1920,
    );
    if (file == null) return null;
    return ReviewImageUpload(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      contentType: file.mimeType ?? _contentTypeFor(file.name),
    );
  }

  static String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class ReviewEditorScreen extends StatefulWidget {
  const ReviewEditorScreen({
    super.key,
    required this.repository,
    required this.shopId,
    required this.shopName,
    required this.currency,
    this.reviewId,
    this.imagePicker,
  });

  final ReviewRepository repository;
  final int shopId;
  final String shopName;
  final String currency;
  final int? reviewId;
  final ReviewImagePicker? imagePicker;

  @override
  State<ReviewEditorScreen> createState() => _ReviewEditorScreenState();
}

class _ReviewEditorScreenState extends State<ReviewEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _costController = TextEditingController(text: '0');
  final _tagsController = TextEditingController();
  final List<_ReviewImageItem> _images = [];

  double _scoreOverall = 5;
  double _scoreTaste = 5;
  double _scoreEnv = 5;
  double _scoreService = 5;
  bool _loading = false;
  bool _saving = false;
  bool _uploading = false;
  String? _loadError;
  String _shopName = '';
  String _currency = '';
  int? _auditStatus;
  String _auditStatusText = '';
  String _auditRemark = '';

  bool get _isEditing => widget.reviewId != null;

  @override
  void initState() {
    super.initState();
    _shopName = widget.shopName;
    _currency = widget.currency;
    if (_isEditing) _loadReview();
  }

  Future<void> _loadReview() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final detail = await widget.repository.loadOwnedReview(widget.reviewId!);
      if (!mounted) return;
      setState(() {
        _shopName = detail.shopName;
        _currency = detail.currency;
        _contentController.text = detail.content;
        _costController.text = _formatNumber(detail.cost);
        _tagsController.text = detail.tags.join('，');
        _scoreOverall = detail.scoreOverall;
        _scoreTaste = detail.scoreTaste;
        _scoreEnv = detail.scoreEnv;
        _scoreService = detail.scoreService;
        _images
          ..clear()
          ..addAll(detail.images.map((url) => _ReviewImageItem(url: url)));
        _auditStatus = detail.auditStatus;
        _auditStatusText = detail.auditStatusText;
        _auditRemark = detail.auditRemark;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _costController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_uploading) return;
    if (_images.length >= 9) {
      _showMessage(AppLocalizations.of(context).maxNineImages);
      return;
    }
    setState(() => _uploading = true);
    ReviewImageUpload? image;
    try {
      try {
        image = await (widget.imagePicker ?? const SystemReviewImagePicker())
            .pickImage();
      } catch (error) {
        if (mounted)
          _showMessage(AppLocalizations.of(context).imagePickFailed(error));
        return;
      }
      if (image == null || !mounted) return;
      final imageBytes = image.bytes;
      try {
        final url = await widget.repository.uploadImage(image);
        if (!mounted) return;
        setState(
          () => _images.add(_ReviewImageItem(url: url, bytes: imageBytes)),
        );
      } catch (error) {
        if (mounted)
          _showMessage(AppLocalizations.of(context).imageUploadFailed(error));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (_saving || _uploading || !_formKey.currentState!.validate()) return;
    final tags = _tagsController.text
        .split(RegExp('[,，]'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .take(10)
        .toList();
    final input = ReviewSaveInput(
      shopId: widget.shopId,
      content: _contentController.text.trim(),
      scoreOverall: _scoreOverall,
      scoreTaste: _scoreTaste,
      scoreEnv: _scoreEnv,
      scoreService: _scoreService,
      cost: double.parse(_costController.text.trim()),
      currency: _currency.isEmpty ? 'CNY' : _currency,
      tags: tags,
      images: _images.map((image) => image.url).toList(),
    );
    setState(() => _saving = true);
    try {
      final result = _isEditing
          ? await widget.repository.updateReview(widget.reviewId!, input)
          : await widget.repository.createReview(input);
      if (!mounted) return;
      _showMessage(
        _isEditing
            ? AppLocalizations.of(context).reviewUpdatedResubmitted
            : AppLocalizations.of(context).reviewSubmittedPending,
      );
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) _showMessage(AppLocalizations.of(context).saveFailed(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? AppLocalizations.of(context).editReview
              : AppLocalizations.of(context).writeReview,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: FilledButton.icon(
          key: const Key('review-editor-retry'),
          onPressed: _loadReview,
          icon: const Icon(Icons.refresh),
          label: Text(AppLocalizations.of(context).reviewLoadFailedTapRetry),
        ),
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          _ShopHeader(shopName: _shopName),
          if (_auditStatus != null || _auditStatusText.isNotEmpty) ...[
            const SizedBox(height: 12),
            _AuditNotice(
              status: AppLocalizations.of(context).auditStatusLabel(
                status: _auditStatus,
                fallback: _auditStatusText,
              ),
              remark: _auditRemark,
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: AppLocalizations.of(context).ratingPrompt,
            subtitle: AppLocalizations.of(context).ratingHint,
            child: Column(
              children: [
                _ScoreRow(
                  label: AppLocalizations.of(context).scoreOverall,
                  value: _scoreOverall,
                  onChanged: (value) => setState(() => _scoreOverall = value),
                ),
                _ScoreRow(
                  label: AppLocalizations.of(context).scoreTaste,
                  value: _scoreTaste,
                  onChanged: (value) => setState(() => _scoreTaste = value),
                ),
                _ScoreRow(
                  label: AppLocalizations.of(context).scoreEnv,
                  value: _scoreEnv,
                  onChanged: (value) => setState(() => _scoreEnv = value),
                ),
                _ScoreRow(
                  label: AppLocalizations.of(context).scoreService,
                  value: _scoreService,
                  onChanged: (value) => setState(() => _scoreService = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: AppLocalizations.of(context).saySomethingUseful,
            subtitle: AppLocalizations.of(context).reviewWritingHint,
            child: TextFormField(
              key: const Key('review-content'),
              controller: _contentController,
              minLines: 5,
              maxLines: 9,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).reviewContentHint,
                filled: true,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppLocalizations.of(context).pleaseWriteRealExperience
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: AppLocalizations.of(context).onSitePhotos,
            subtitle: AppLocalizations.of(context).photosUploadHint,
            trailing: Text(
              AppLocalizations.of(context).uploadedCount(_images.length),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_images.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var index = 0; index < _images.length; index++)
                        _ImagePreview(
                          image: _images[index],
                          onRemove: () =>
                              setState(() => _images.removeAt(index)),
                        ),
                    ],
                  ),
                if (_images.isNotEmpty) const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('review-add-image'),
                  onPressed: _uploading || _images.length >= 9
                      ? null
                      : _pickImage,
                  icon: _uploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _uploading
                        ? AppLocalizations.of(context).uploading
                        : AppLocalizations.of(context).addImages,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: AppLocalizations.of(context).spendAndTags,
            subtitle: AppLocalizations.of(context).spendTagsHint,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('review-cost'),
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).spendAmount,
                    suffixText: _currency.isEmpty ? 'CNY' : _currency,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    return amount == null || amount < 0
                        ? AppLocalizations.of(context).enterNonNegativeAmount
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('review-tags'),
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).tagsLabel,
                    hintText: AppLocalizations.of(context).tagsHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('review-submit'),
            onPressed: _saving || _uploading ? null : _submit,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.rate_review_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _isEditing
                    ? AppLocalizations.of(context).saveAndResubmit
                    : AppLocalizations.of(context).publishReview,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewImageItem {
  const _ReviewImageItem({required this.url, this.bytes});
  final String url;
  final Uint8List? bytes;
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shopName});
  final String shopName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, const Color(0xFFFFE6D4)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.surface,
            child: const Icon(Icons.storefront_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).reviewingShop,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditNotice extends StatelessWidget {
  const _AuditNotice({required this.status, required this.remark});
  final String status;
  final String remark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6C96C)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status),
                if (remark.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).auditRemarkLabel(remark),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const Icon(Icons.star_rounded, color: Color(0xFFF29A38), size: 20),
        SizedBox(
          width: 28,
          child: Text(value.toStringAsFixed(0), textAlign: TextAlign.center),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image, required this.onRemove});
  final _ReviewImageItem image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 92,
            child: image.bytes != null
                ? Image.memory(image.bytes!, fit: BoxFit.cover)
                : Image.network(
                    image.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFFFE6D4),
                      child: Icon(Icons.image_outlined),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: -8,
          top: -8,
          child: IconButton.filled(
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
      ],
    );
  }
}
