import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class ConversationsListPage extends ConsumerStatefulWidget {
  const ConversationsListPage({super.key});

  @override
  ConsumerState<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends ConsumerState<ConversationsListPage> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  Timer? _pollTimer;
  final Map<String, String> _namesCache = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _loadConversations());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await _apiClient.dio.get('/chat/conversations');
      final convos = List.from(res.data);
      final myId = ref.read(authProvider).userId ?? '';

      for (var convo in convos) {
        final otherId = _otherParticipant(convo, myId);
        if (otherId.isNotEmpty && !_namesCache.containsKey(otherId)) {
          try {
            final userRes = await _apiClient.dio.get('/public/users/$otherId');
            if (userRes.data != null && userRes.data['fullName'] != null) {
              _namesCache[otherId] = userRes.data['fullName'].toString();
            }
          } catch (_) {
            _namesCache[otherId] = 'User ${otherId.substring(0, 6).toUpperCase()}';
          }
        }
      }

      if (mounted) {
        setState(() {
          _conversations = convos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Conversations load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _otherParticipant(Map<String, dynamic> convo, String myId) {
    final participants = convo['participantUserIds'] as List? ?? [];
    final other = participants.firstWhere(
      (p) => p != myId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
    return other.toString();
  }

  String _formatTime(dynamic timestamp) {
    // Backend Chat uses lastMessageTimestamp (Instant → ISO string)
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Messages',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1C1C))),
            Text('Your conversations', style: TextStyle(fontSize: 12, color: Color(0xFF707A6C))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Color(0xFF2E7D32)),
            onPressed: _loadConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D631B)))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: const Color(0xFF0D631B),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final convo = _conversations[i] as Map<String, dynamic>;
                      final myId = ref.watch(authProvider).userId ?? '';
                      final otherId = _otherParticipant(convo, myId);
                      final otherName = _namesCache[otherId] ?? 'User ${otherId.substring(0, 6).toUpperCase()}';
                      final lastMsg = convo['lastMessageText'] as String? ?? 'No messages yet';
                      final lastTime = _formatTime(convo['lastMessageTimestamp']);
                      final orderId = convo['associatedOrderId'] as String?;
                      const unread = 0; // Backend Chat doesn't track unread count yet

                      return _ConversationTile(
                        otherId: otherId,
                        displayName: otherName,
                        lastMessage: lastMsg,
                        lastTime: lastTime,
                        orderId: orderId,
                        unreadCount: unread,
                        onTap: () {
                          context.push(
                            '/chat?recipient=$otherId&name=${Uri.encodeComponent(otherName)}${orderId != null ? '&orderId=$orderId' : ''}',
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA3F69C), width: 2),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 20),
          const Text('No conversations yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C))),
          const SizedBox(height: 8),
          const Text(
            'Start chatting by messaging a customer\nor farmer from an order.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF707A6C)),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String otherId;
  final String displayName;
  final String lastMessage;
  final String lastTime;
  final String? orderId;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.otherId,
    required this.displayName,
    required this.lastMessage,
    required this.lastTime,
    required this.orderId,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unreadCount > 0 ? const Color(0xFFA3F69C) : const Color(0xFFEEEEEE),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: unreadCount > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFF3F3F3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: unreadCount > 0 ? const Color(0xFF2E7D32) : Colors.grey,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF1A1C1C),
                        ),
                      ),
                      Text(lastTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: unreadCount > 0 ? const Color(0xFF2E7D32) : const Color(0xFF707A6C),
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          )),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: unreadCount > 0 ? const Color(0xFF1A1C1C) : const Color(0xFF707A6C),
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D631B),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (orderId != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 11, color: Color(0xFF707A6C)),
                        const SizedBox(width: 3),
                        Text(
                          'Order #${orderId!.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF707A6C)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
