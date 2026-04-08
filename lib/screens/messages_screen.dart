import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../config/developer_mode.dart';
import '../utils/responsive_utils.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshMessages();
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _messageService.syncMessages();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = !ResponsiveUtils.isDesktop(context);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Row(
                children: [
                  const Text('Nachrichten'),
                  if (_messageService.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_messageService.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshMessages,
                ),
                if (DeveloperMode.isActive)
                  PopupMenuButton<String>(
                    onSelected: _handleDeveloperAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'test_info',
                        child: ListTile(
                          leading: Icon(Icons.info),
                          title: Text('Test Info'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'test_warning',
                        child: ListTile(
                          leading: Icon(Icons.warning, color: Colors.orange),
                          title: Text('Test Warning'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'test_error',
                        child: ListTile(
                          leading: Icon(Icons.error, color: Colors.red),
                          title: Text('Test Error'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'test_urgent',
                        child: ListTile(
                          leading: Icon(Icons.priority_high, color: Colors.red),
                          title: Text('Test Urgent'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            )
          : null,
      body: _buildBody(),
      floatingActionButton: DeveloperMode.isActive
          ? FloatingActionButton(
              onPressed: () => _handleDeveloperAction('test_info'),
              child: const Icon(Icons.add),
              tooltip: 'Test-Nachricht erstellen',
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Nachrichten werden geladen...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refreshMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final messages = _messageService.messages;

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Nachrichten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Du hast alle Nachrichten gelesen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _MessageCard(
            message: message,
            onTap: () => _openMessage(message),
            onArchive: () => _archiveMessage(message),
          );
        },
      ),
    );
  }

  void _openMessage(Message message) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _MessageDetailScreen(message: message),
      ),
    ).then((_) {
      // Aktualisiere die Liste nach dem Schließen der Detail-Ansicht
      setState(() {});
    });
  }

  Future<void> _archiveMessage(Message message) async {
    try {
      await _messageService.archiveMessage(message.id);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nachricht "${message.title}" archiviert'),
            action: SnackBarAction(
              label: 'Rückgängig',
              onPressed: () {
                // TODO: Implementiere Undo-Funktionalität
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Archivieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDeveloperAction(String action) {
    if (!DeveloperMode.isActive) return;

    switch (action) {
      case 'test_info':
        _messageService.sendTestMessage(
          title: 'Test Info',
          body: 'Dies ist eine Test-Info-Nachricht.',
          type: MessageType.info,
          priority: MessagePriority.normal,
        );
        break;
      case 'test_warning':
        _messageService.sendTestMessage(
          title: 'Test Warnung',
          body: 'Dies ist eine Test-Warn-Nachricht.',
          type: MessageType.warning,
          priority: MessagePriority.high,
        );
        break;
      case 'test_error':
        _messageService.sendTestMessage(
          title: 'Test Fehler',
          body: 'Dies ist eine Test-Fehler-Nachricht.',
          type: MessageType.error,
          priority: MessagePriority.high,
        );
        break;
      case 'test_urgent':
        _messageService.sendTestMessage(
          title: 'Dringende Nachricht',
          body: 'Dies ist eine dringende Test-Nachricht.',
          type: MessageType.announcement,
          priority: MessagePriority.urgent,
        );
        break;
    }

    setState(() {});
  }
}

class _MessageCard extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const _MessageCard({
    required this.message,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !message.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isUnread
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: isUnread ? 2 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getTypeIcon(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: onArchive,
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.senderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    _getPriorityChip(),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(message.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getTypeIcon() {
    switch (message.type) {
      case MessageType.info:
        return const Icon(Icons.info_outline, color: Colors.blue);
      case MessageType.warning:
        return const Icon(Icons.warning_outlined, color: Colors.orange);
      case MessageType.error:
        return const Icon(Icons.error_outline, color: Colors.red);
      case MessageType.success:
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case MessageType.announcement:
        return const Icon(Icons.campaign_outlined, color: Colors.purple);
      case MessageType.update:
        return const Icon(Icons.system_update_outlined, color: Colors.blue);
    }
  }

  Widget _getPriorityChip() {
    if (message.priority == MessagePriority.normal) {
      return const SizedBox.shrink();
    }

    Color color;
    String label;

    switch (message.priority) {
      case MessagePriority.low:
        color = Colors.grey;
        label = 'Niedrig';
        break;
      case MessagePriority.high:
        color = Colors.orange;
        label = 'Hoch';
        break;
      case MessagePriority.urgent:
        color = Colors.red;
        label = 'Dringend';
        break;
      case MessagePriority.normal:
        return const SizedBox.shrink();
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Gestern';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

class _MessageDetailScreen extends StatefulWidget {
  final Message message;

  const _MessageDetailScreen({required this.message});

  @override
  State<_MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<_MessageDetailScreen> {
  final MessageService _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (!widget.message.isRead) {
      await _messageService.markAsRead(widget.message.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.message.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: _archiveMessage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _getTypeIcon(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                _getPriorityChip(),
              ],
            ),
            const SizedBox(height: 16),

            // Metadaten
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 8),
                      Text('Von: ${widget.message.senderName}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text('Gesendet: ${_formatFullDate(widget.message.createdAt)}'),
                    ],
                  ),
                  if (widget.message.readAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.done_all, size: 16),
                        const SizedBox(width: 8),
                        Text('Gelesen: ${_formatFullDate(widget.message.readAt!)}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nachrichteninhalt
            Text(
              widget.message.body,
              style: theme.textTheme.bodyLarge,
            ),

            if (widget.message.route != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // TODO: Implementiere Navigation zur Route
                  Navigator.of(context).pushNamed(widget.message.route!);
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Zur Aktion'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getTypeIcon() {
    switch (widget.message.type) {
      case MessageType.info:
        return const Icon(Icons.info, color: Colors.blue, size: 32);
      case MessageType.warning:
        return const Icon(Icons.warning, color: Colors.orange, size: 32);
      case MessageType.error:
        return const Icon(Icons.error, color: Colors.red, size: 32);
      case MessageType.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 32);
      case MessageType.announcement:
        return const Icon(Icons.campaign, color: Colors.purple, size: 32);
      case MessageType.update:
        return const Icon(Icons.system_update, color: Colors.blue, size: 32);
    }
  }

  Widget _getPriorityChip() {
    if (widget.message.priority == MessagePriority.normal) {
      return const SizedBox.shrink();
    }

    Color color;
    String label;

    switch (widget.message.priority) {
      case MessagePriority.low:
        color = Colors.grey;
        label = 'Niedrige Priorität';
        break;
      case MessagePriority.high:
        color = Colors.orange;
        label = 'Hohe Priorität';
        break;
      case MessagePriority.urgent:
        color = Colors.red;
        label = 'Dringend';
        break;
      case MessagePriority.normal:
        return const SizedBox.shrink();
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
    );
  }

  Future<void> _archiveMessage() async {
    try {
      await _messageService.archiveMessage(widget.message.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nachricht archiviert'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Archivieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
}