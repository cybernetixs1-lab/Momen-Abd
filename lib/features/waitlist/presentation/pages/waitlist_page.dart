import 'package:flutter/material.dart';
import '../../application/waitlist_controller.dart';
import '../../domain/entities/waitlist_entry.dart';

class WaitlistPage extends StatelessWidget {
  const WaitlistPage({super.key, required this.controller});
  final WaitlistController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Restaurant Waitlist')),
          body: _buildBody(context),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: controller.isLoading || controller.errorMessage != null
                ? null
                : () => _showAddPartyDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add party'),
          ),
        ),
      );

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.entries.isEmpty) {
      return _EmptyState(
        errorMessage: controller.errorMessage,
        onRetry: controller.errorMessage == null ? null : controller.load,
      );
    }
    return Column(children: [
      if (controller.errorMessage != null)
        MaterialBanner(
          content: Text(controller.errorMessage!),
          actions: [
            TextButton(onPressed: controller.load, child: const Text('Retry'))
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
              partiesAhead: index,
              onRemove: () => _confirmRemoval(context, entry));
        },
      )),
    ]);
  }

  Future<void> _showAddPartyDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddPartyDialog(controller: controller),
    );
  }

  Future<void> _confirmRemoval(
      BuildContext context, WaitlistEntry entry) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove party?'),
        content: Text(
            'Remove ${entry.name} (ticket #${entry.ticketNumber}) from the waitlist?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (shouldRemove == true) await controller.removeParty(entry.ticketNumber);
  }
}

class _AddPartyDialog extends StatefulWidget {
  const _AddPartyDialog({required this.controller});

  final WaitlistController controller;

  @override
  State<_AddPartyDialog> createState() => _AddPartyDialogState();
}

class _AddPartyDialogState extends State<_AddPartyDialog> {
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController(text: '2');
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add party'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Party size'),
                validator: (value) {
                  final size = int.tryParse(value ?? '');
                  return size == null || size <= 0
                      ? 'Enter a whole number greater than 0'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _addParty,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      );

  Future<void> _addParty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final success = await widget.controller.addParty(
      name: _nameController.text,
      partySize: int.parse(_sizeController.text),
    );
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }
}

class WaitlistTile extends StatelessWidget {
  const WaitlistTile(
      {super.key,
      required this.entry,
      required this.partiesAhead,
      required this.onRemove});
  final WaitlistEntry entry;
  final int partiesAhead;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Text(entry.ticketNumber.toString())),
          title: Text(entry.name),
          subtitle: Text(
            '${entry.partySize} ${entry.partySize == 1 ? 'person' : 'people'}'
            ' • $partiesAhead ${partiesAhead == 1 ? 'party' : 'parties'} ahead',
          ),
          trailing: IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline)),
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
