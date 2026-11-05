import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/ticket/ticket_repository.dart';
import 'package:flutter/material.dart';

String localizeTicketError(AppLocalizations strings, Object error) =>
    localizeAuthError(
      strings,
      error,
      overrides: {
        '工单不存在': strings.ticketNotFound,
        '工单当前状态不可回复': strings.ticketReplyUnavailable,
        '主题不能为空': strings.ticketSubjectRequired,
        '内容不能为空': strings.ticketContentRequired,
      },
    );

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({
    super.key,
    required this.repository,
    required this.ticketId,
  });
  final TicketRepository repository;
  final int ticketId;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _reply = TextEditingController();
  final _form = GlobalKey<FormState>();
  SupportTicket? _ticket;
  bool _loading = false;
  bool _sending = false;
  Object? _loadError;
  Object? _replyError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || _sending) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final ticket = await widget.repository.detail(widget.ticketId);
      if (mounted) setState(() => _ticket = ticket);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_sending ||
        _loading ||
        _ticket?.canReply != true ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _sending = true;
      _replyError = null;
    });
    var refreshStatus = false;
    try {
      final ticket = await widget.repository.reply(
        widget.ticketId,
        _reply.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _reply.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _replyError = error);
      refreshStatus = error is ApiException && error.statusCode == 409;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    if (mounted && refreshStatus) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final ticket = _ticket;
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket?.subject ?? strings.myTicketsTitle),
        actions: [
          IconButton(
            key: const Key('ticket-detail-refresh'),
            tooltip: strings.refresh,
            onPressed: _loading || _sending ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_loadError != null) ...[
              Text(
                strings.ticketsLoadFailed(
                  localizeTicketError(strings, _loadError!),
                ),
                key: const Key('ticket-detail-error'),
              ),
              TextButton(
                key: const Key('ticket-detail-retry'),
                onPressed: _loading ? null : _load,
                child: Text(strings.retry),
              ),
            ],
            if (ticket != null) ...[
              Text(
                strings.ticketStatusLabel(ticket.status),
                key: const Key('ticket-status'),
              ),
              if (ticket.messages.isEmpty) SelectableText(ticket.content),
              for (final message in ticket.messages)
                Card(
                  key: Key('ticket-message-${message.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.ticketSenderLabel(message.senderType),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        SelectableText(message.content),
                        if (message.createdAt.isNotEmpty)
                          Text(
                            formatDisplayDateTime(
                              message.createdAt,
                              locale: strings.tag,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              if (_replyError != null)
                Text(
                  strings.actionFailed(
                    localizeTicketError(strings, _replyError!),
                  ),
                  key: const Key('ticket-reply-error'),
                ),
              if (ticket.canReply)
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('ticket-reply-input'),
                        controller: _reply,
                        enabled: !_sending,
                        maxLength: 2000,
                        minLines: 2,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: strings.ticketReply,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? strings.ticketContentRequired
                            : null,
                      ),
                      FilledButton(
                        key: const Key('ticket-reply-send'),
                        onPressed: _sending || _loading ? null : _send,
                        child: Text(
                          _sending ? strings.submitting : strings.ticketSend,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  strings.ticketReplyUnavailable,
                  key: const Key('ticket-reply-unavailable'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
