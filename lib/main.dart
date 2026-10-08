import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/waitlist_controller.dart';
import 'data/shared_preferences_waitlist_repository.dart';
import 'domain/waitlist_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final repository = SharedPreferencesWaitlistRepository(preferences);
  final controller = WaitlistController(repository);
  await controller.load();

  runApp(RestaurantWaitlistApp(controller: controller));
}

class RestaurantWaitlistApp extends StatelessWidget {
  const RestaurantWaitlistApp({super.key, required this.controller});

  final WaitlistController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Waitlist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: WaitlistPage(controller: controller),
    );
  }
}

class WaitlistPage extends StatelessWidget {
  const WaitlistPage({super.key, required this.controller});

  final WaitlistController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Waitlist')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.entries.isEmpty) {
            return _EmptyState(errorMessage: controller.errorMessage);
          }

          return Column(
            children: [
              if (controller.errorMessage != null)
                MaterialBanner(
                  content: Text(controller.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: controller.load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = controller.entries[index];
                    return WaitlistTile(
                      entry: entry,
                      partiesAhead: entry.partiesAheadOf(index),
                      onRemove: () => _confirmRemoval(context, entry),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPartyDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add party'),
      ),
    );
  }

  Future<void> _showAddPartyDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final sizeController = TextEditingController(text: '2');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var saving = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add party'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Smith',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Party size'),
                    validator: (value) {
                      final size = int.tryParse(value ?? '');
                      if (size == null || size <= 0) {
                        return 'Enter a whole number greater than 0';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() => saving = true);
                        final success = await controller.addParty(
                          name: nameController.text,
                          partySize: int.parse(sizeController.text),
                        );

                        if (dialogContext.mounted) {
                          if (success) {
                            Navigator.pop(dialogContext);
                          } else {
                            setState(() => saving = false);
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    sizeController.dispose();
  }

  Future<void> _confirmRemoval(
    BuildContext context,
    WaitlistEntry entry,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove party?'),
        content: Text(
          'Remove ${entry.name} (ticket #${entry.ticketNumber}) from the waitlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      await controller.removeParty(entry.ticketNumber);
    }
  }
}

class WaitlistTile extends StatelessWidget {
  const WaitlistTile({
    super.key,
    required this.entry,
    required this.partiesAhead,
    required this.onRemove,
  });

  final WaitlistEntry entry;
  final int partiesAhead;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${entry.ticketNumber}')),
        title: Text(entry.name),
        subtitle: Text(
          '${entry.partySize} ${entry.partySize == 1 ? 'person' : 'people'}'
          ' • $partiesAhead ${partiesAhead == 1 ? 'party' : 'parties'} ahead',
        ),
        trailing: IconButton(
          tooltip: 'Remove',
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMessage ?? 'No parties are currently waiting.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
