import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/qa/qa_repository.dart';
import 'package:flutter/material.dart';

/// 门店详情页的"问大家"板块：浏览问题、提问、展开与回答。
class ShopQaSection extends StatefulWidget {
  const ShopQaSection({super.key, required this.repository, required this.shopId});

  final QaRepository repository;
  final int shopId;

  @override
  State<ShopQaSection> createState() => _ShopQaSectionState();
}

class _ShopQaSectionState extends State<ShopQaSection> {
  late Future<List<ShopQuestion>> _questions;
  final _askController = TextEditingController();
  bool _asking = false;
  final Set<int> _expanded = <int>{};
  final Map<int, List<ShopAnswer>> _answers = {};
  final Map<int, TextEditingController> _answerControllers = {};

  @override
  void initState() {
    super.initState();
    _questions = widget.repository.loadQuestions(widget.shopId);
  }

  @override
  void dispose() {
    _askController.dispose();
    for (final c in _answerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _reload() {
    setState(() => _questions = widget.repository.loadQuestions(widget.shopId));
  }

  Future<void> _ask() async {
    if (_asking) return;
    final content = _askController.text.trim();
    if (content.isEmpty) return;
    setState(() => _asking = true);
    final strings = AppLocalizations.of(context);
    try {
      await widget.repository.ask(widget.shopId, content);
      _askController.clear();
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.qaAskFailed(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  Future<void> _toggle(ShopQuestion q) async {
    if (_expanded.contains(q.id)) {
      setState(() => _expanded.remove(q.id));
      return;
    }
    setState(() => _expanded.add(q.id));
    if (!_answers.containsKey(q.id)) {
      try {
        final answers = await widget.repository.loadAnswers(widget.shopId, q.id);
        if (mounted) setState(() => _answers[q.id] = answers);
      } catch (_) {
        if (mounted) setState(() => _answers[q.id] = const []);
      }
    }
  }

  Future<void> _answer(ShopQuestion q) async {
    final controller = _answerControllers[q.id];
    final content = controller?.text.trim() ?? '';
    if (content.isEmpty) return;
    final strings = AppLocalizations.of(context);
    try {
      final answer = await widget.repository.answer(widget.shopId, q.id, content);
      controller?.clear();
      if (mounted) {
        setState(() => _answers[q.id] = [...(_answers[q.id] ?? const []), answer]);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.qaAnswerFailed(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      key: const Key('shop-qa-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.qaSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('qa-ask-input'),
                controller: _askController,
                decoration: InputDecoration(hintText: strings.qaAskHint),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('qa-ask-submit'),
              onPressed: _asking ? null : _ask,
              child: Text(strings.qaAsk),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<ShopQuestion>>(
          future: _questions,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Text(strings.qaLoadFailed(snapshot.error!), key: const Key('qa-error'));
            }
            final questions = snapshot.data ?? const [];
            if (questions.isEmpty) {
              return Text(strings.qaEmpty, key: const Key('qa-empty'));
            }
            return Column(
              children: questions.map((q) => _questionTile(strings, q)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _questionTile(AppLocalizations strings, ShopQuestion q) {
    final expanded = _expanded.contains(q.id);
    final controller = _answerControllers.putIfAbsent(q.id, () => TextEditingController());
    return Card(
      key: Key('qa-question-${q.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.content, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (q.latestAnswer.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(q.latestAnswer, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            TextButton(
              key: Key('qa-toggle-${q.id}'),
              onPressed: () => _toggle(q),
              child: Text(expanded ? strings.qaViewAnswers : strings.qaAnswerCount(q.answerCount)),
            ),
            if (expanded) ...[
              if ((_answers[q.id] ?? const []).isEmpty)
                Text(strings.qaNoAnswers)
              else
                ...(_answers[q.id] ?? const []).map((a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${a.userNickname}: ${a.content}'),
                    )),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: Key('qa-answer-input-${q.id}'),
                      controller: controller,
                      decoration: InputDecoration(hintText: strings.qaAnswerHint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    key: Key('qa-answer-submit-${q.id}'),
                    onPressed: () => _answer(q),
                    child: Text(strings.qaAnswer),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
