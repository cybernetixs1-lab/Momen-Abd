import 'package:flutter/material.dart';
import '../../application/waitlist_controller.dart';
import '../../domain/waitlist_entry.dart';

class WaitlistPage extends StatelessWidget {
  const WaitlistPage({super.key, required this.controller});
  final WaitlistController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Restaurant Waitlist')),
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading) return const Center(child: CircularProgressIndicator());
        if (controller.entries.isEmpty) {
          return _EmptyState(
            errorMessage: controller.errorMessage,
            onRetry: controller.errorMessage == null ? null : controller.load,
          );
        }
        return Column(children: [
          if (controller.errorMessage != null) MaterialBanner(
            content: Text(controller.errorMessage!),
            actions: [TextButton(onPressed: controller.load, child: const Text('Retry'))],
          ),
          Expanded(child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = controller.entries[index];
              return WaitlistTile(entry: entry, partiesAhead: index,
                onRemove: () => _confirmRemoval(context, entry));
            },
          )),
        ]);
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: controller.isLoading || controller.errorMessage != null
          ? null
          : () => _showAddPartyDialog(context),
      icon: const Icon(Icons.person_add), label: const Text('Add party'),
    ),
  );

  Future<void> _showAddPartyDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final sizeController = TextEditingController(text: '2');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var saving = false;
        return StatefulBuilder(builder: (context, setState) => AlertDialog(
          title: const Text('Add party'),
          content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameController, autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: sizeController, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Party size'),
              validator: (value) {
                final size = int.tryParse(value ?? '');
                return size == null || size <= 0 ? 'Enter a whole number greater than 0' : null;
              },
            ),
          ])),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => saving = true);
                final success = await controller.addParty(
                  name: nameController.text, partySize: int.parse(sizeController.text));
                if (!dialogContext.mounted) return;
                if (success) Navigator.pop(dialogContext);
                else setState(() => saving = false);
              },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add'),
            ),
          ],
        ));
      },
    );
    nameController.dispose();
    sizeController.dispose();
  }

  Future<void> _confirmRemoval(BuildContext context, WaitlistEntry entry) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove party?'),
        content: Text('Remove ' + entry.name + ' (ticket #' + entry.ticketNumber.toString() + ') from the waitlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (shouldRemove == true) await controller.removeParty(entry.ticketNumber);
  }
}

class WaitlistTile extends StatelessWidget {
  const WaitlistTile({super.key, required this.entry, required this.partiesAhead, required this.onRemove});
  final WaitlistEntry entry;
  final int partiesAhead;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(child: Text(entry.ticketNumber.toString())),
      title: Text(entry.name),
      subtitle: Text(
        entry.partySize.toString() + ' ' + (entry.partySize == 1 ? 'person' : 'people') +
        ' • ' + partiesAhead.toString() + ' ' + (partiesAhead == 1 ? 'party' : 'parties') + ' ahead',
      ),
      trailing: IconButton(tooltip: 'Remove', onPressed: onRemove, icon: const Icon(Icons.remove_circle_outline)),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.errorMessage, this.onRetry});
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            errorMessage ?? 'No parties are currently waiting.',
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    ),
  );
}
