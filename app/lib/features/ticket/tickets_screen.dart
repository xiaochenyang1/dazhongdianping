import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/ticket/ticket_repository.dart';
import 'package:flutter/material.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.repository});

  final TicketRepository repository;

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  late Future<List<SupportTicket>> _tickets;
  final _subject = TextEditingController();
  final _content = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tickets = widget.repository.loadMine();
  }

  @override
  void dispose() {
    _subject.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = widget.repository.loadMine();
    setState(() => _tickets = future);
    await future;
  }

  Future<void> _create() async {
    await widget.repository.create(subject: _subject.text.trim(), content: _content.text.trim());
    _subject.clear();
    _content.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.myTicketsTitle)),
      body: FutureBuilder<List<SupportTicket>>(
        future: _tickets,
        builder: (context, snapshot) {
          final tickets = snapshot.data ?? const <SupportTicket>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(controller: _subject, decoration: InputDecoration(labelText: strings.ticketSubject)),
              TextField(controller: _content, decoration: InputDecoration(labelText: strings.ticketContent)),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(onPressed: _create, child: Text(strings.ticketSubmit)),
              ),
              if (snapshot.hasError) Text(strings.ticketsLoadFailed(snapshot.error!)),
              if (snapshot.connectionState == ConnectionState.done && tickets.isEmpty)
                Text(strings.ticketsEmpty, key: const Key('tickets-empty')),
              for (final ticket in tickets)
                ListTile(
                  key: Key('ticket-${ticket.id}'),
                  title: Text(ticket.subject),
                  subtitle: Text('${ticket.statusText}\n${ticket.content}'),
                  isThreeLine: true,
                ),
            ],
          );
        },
      ),
    );
  }
}
