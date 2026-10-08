import 'package:flutter/material.dart';

import '../../application/waitlist_controller.dart';
import '../../domain/entities/waitlist_entry.dart';

class WaitlistPage extends StatelessWidget {
  const WaitlistPage({super.key, required this.controller});

  final WaitlistController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final count = controller.entries.length;
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waitlist'),
                  Text(
                    '$count ${count == 1 ? 'party' : 'parties'} waiting',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    Expanded(child: _buildQueue(context)),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.58,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: _AddPartyForm(
                          controller: controller,
                          isEnabled: !controller.isLoading &&
                              !controller.hasLoadError &&
                              !controller.isMutating,
                          onSaveError: () => _showError(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _buildQueue(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.hasLoadError) {
      return _LoadError(onRetry: controller.load);
    }
    if (controller.entries.isEmpty) {
      return const _EmptyWaitlist();
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      itemCount: controller.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = controller.entries[index];
        return _PartyTile(
          entry: entry,
          partiesAhead: index,
          isNext: index == 0,
          isEnabled: !controller.isMutating,
          onRemove: () => _removeParty(context, entry),
        );
      },
    );
  }

  Future<void> _removeParty(BuildContext context, WaitlistEntry entry) async {
    final removed = await controller.removeParty(entry.ticketNumber);
    if (!context.mounted) return;

    if (removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.name} removed from the waitlist.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final restored = await controller.undoLastRemoval();
              if (!restored && context.mounted) _showError(context);
            },
          ),
        ),
      );
    } else {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    final message = controller.errorMessage;
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AddPartyForm extends StatefulWidget {
  const _AddPartyForm({
    required this.controller,
    required this.isEnabled,
    required this.onSaveError,
  });

  final WaitlistController controller;
  final bool isEnabled;
  final VoidCallback onSaveError;

  @override
  State<_AddPartyForm> createState() => _AddPartyFormState();
}

class _AddPartyFormState extends State<_AddPartyForm> {
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController(text: '2');
  final _nameFocus = FocusNode();
  final _sizeFocus = FocusNode();
  String? _nameError;
  String? _sizeError;

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _nameFocus.dispose();
    _sizeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            enabled: widget.isEnabled,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Party name',
              errorText: _nameError,
            ),
            onChanged: (value) {
              if (_nameError != null) {
                setState(
                    () => _nameError = widget.controller.validateName(value));
              }
            },
            onSubmitted: (_) => _sizeFocus.requestFocus(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _sizeController,
            focusNode: _sizeFocus,
            enabled: widget.isEnabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Party size',
              errorText: _sizeError,
            ),
            onChanged: (value) {
              if (_sizeError != null) {
                setState(
                  () => _sizeError =
                      widget.controller.validatePartySize(int.tryParse(value)),
                );
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.isEnabled ? _submit : null,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add'),
            ),
          ),
        ],
      );

  Future<void> _submit() async {
    final name = _nameController.text;
    final partySize = int.tryParse(_sizeController.text);
    final nameError = widget.controller.validateName(name);
    final sizeError = widget.controller.validatePartySize(partySize);
    setState(() {
      _nameError = nameError;
      _sizeError = sizeError;
    });
    if (nameError != null || sizeError != null || !widget.isEnabled) return;

    final success = await widget.controller.addParty(
      name: name,
      partySize: partySize!,
    );
    if (!mounted) return;

    if (success) {
      _nameController.clear();
      _sizeController.clear();
      setState(() {
        _nameError = null;
        _sizeError = null;
      });
      _nameFocus.requestFocus();
    } else if (widget.controller.errorMessage != null) {
      widget.onSaveError();
    }
  }
}

class _PartyTile extends StatelessWidget {
  const _PartyTile({
    required this.entry,
    required this.partiesAhead,
    required this.isNext,
    required this.isEnabled,
    required this.onRemove,
  });

  final WaitlistEntry entry;
  final int partiesAhead;
  final bool isNext;
  final bool isEnabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: isNext ? colors.secondaryContainer.withValues(alpha: 0.55) : null,
      child: ListTile(
        leading: Semantics(
          label: 'Ticket number ${entry.ticketNumber}',
          excludeSemantics: true,
          child: CircleAvatar(
            child: Text('#${entry.ticketNumber}'),
          ),
        ),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Party of ${entry.partySize} - '
          '${isNext ? 'Next up' : '$partiesAhead ahead'}',
          maxLines: 2,
        ),
        trailing: IconButton(
          tooltip: 'Remove ${entry.name}',
          onPressed: isEnabled ? onRemove : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ),
    );
  }
}

class _EmptyWaitlist extends StatelessWidget {
  const _EmptyWaitlist();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No parties waiting',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text('Add a party to start the queue.'),
            ],
          ),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Could not load the saved waitlist.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
