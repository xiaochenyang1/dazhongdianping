import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/campaign/campaign_repository.dart';
import 'package:flutter/material.dart';

class LevelPrivilegesScreen extends StatefulWidget {
  const LevelPrivilegesScreen({super.key, required this.repository});

  final GrowthRepository repository;

  @override
  State<LevelPrivilegesScreen> createState() => _LevelPrivilegesScreenState();
}

class _LevelPrivilegesScreenState extends State<LevelPrivilegesScreen> {
  late Future<LevelPrivileges> _privileges;

  @override
  void initState() {
    super.initState();
    _privileges = widget.repository.privileges();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.levelPrivilegesTitle)),
      body: FutureBuilder<LevelPrivileges>(
        future: _privileges,
        builder: (context, snapshot) {
          final item = snapshot.data;
          if (item == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Lv${item.level} ${item.levelName}', style: Theme.of(context).textTheme.titleLarge),
              Text('${item.growthValue}'),
              const SizedBox(height: 12),
              Text(item.privileges),
            ],
          );
        },
      ),
    );
  }
}
