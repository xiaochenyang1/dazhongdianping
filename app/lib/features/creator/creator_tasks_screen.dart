import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/creator/creator_repository.dart';
import 'package:flutter/material.dart';

class CreatorTasksScreen extends StatefulWidget {
  const CreatorTasksScreen({super.key, required this.repository});

  final CreatorRepository repository;

  @override
  State<CreatorTasksScreen> createState() => _CreatorTasksScreenState();
}

class _CreatorTasksScreenState extends State<CreatorTasksScreen> {
  late Future<List<CreatorTask>> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = widget.repository.load();
  }

  Future<void> _reload() async {
    final future = widget.repository.load();
    setState(() => _tasks = future);
    await future;
  }

  Future<void> _claim(CreatorTask task) async {
    await widget.repository.claim(task.id);
    await _reload();
  }

  Future<void> _complete(CreatorTask task) async {
    await widget.repository.complete(task.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.creatorTasksTitle)),
      body: FutureBuilder<List<CreatorTask>>(
        future: _tasks,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
          final tasks = snapshot.data ?? const <CreatorTask>[];
          if (snapshot.connectionState == ConnectionState.done && tasks.isEmpty) {
            return Center(child: Text(strings.creatorEmpty));
          }
          return ListView(
            children: [
              for (final task in tasks)
                ListTile(
                  key: Key('creator-task-${task.id}'),
                  title: Text(task.title),
                  subtitle: Text('${task.description}\n+${task.rewardPoints}'),
                  isThreeLine: true,
                  trailing: task.claimStatus == 0
                      ? TextButton(onPressed: () => _claim(task), child: Text(strings.creatorClaim))
                      : task.claimStatus == 1
                          ? TextButton(onPressed: () => _complete(task), child: Text(strings.creatorComplete))
                          : const Icon(Icons.check),
                ),
            ],
          );
        },
      ),
    );
  }
}
