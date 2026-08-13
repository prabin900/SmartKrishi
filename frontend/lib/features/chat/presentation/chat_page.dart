import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String recipientUserId;
  final String? orderId;
  final String? recipientName;

  const ChatPage({
    super.key,
    required this.recipientUserId,
    this.orderId,
    this.recipientName,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ApiClient _apiClient = ApiClient();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _messages = [];
  String? _chatId;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final sessionRes = await _apiClient.dio.post('/chat/session', queryParameters: {
        'recipientUserId': widget.recipientUserId,
        if (widget.orderId != null) 'orderId': widget.orderId,
      });

      _chatId = sessionRes.data['id'];

      await _fetchMessages();

      setState(() => _isLoading = false);
      _scrollToBottom();

      // Poll every 4 seconds for new messages
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchMessages());
    } catch (e) {
      debugPrint('Chat init error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMessages() async {
    if (_chatId == null) return;
    try {
      final messagesRes = await _apiClient.dio.get('/chat/messages/$_chatId');
      final List<dynamic> fetched = messagesRes.data;
      // Check last message ID to detect new messages
      final lastFetchedId = fetched.isNotEmpty ? fetched.last['id'] : null;
      final lastCurrentId = _messages.isNotEmpty ? _messages.last['id'] : null;
      if (fetched.length != _messages.length || lastFetchedId != lastCurrentId) {
        if (mounted) {
          setState(() => _messages = fetched);
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null || _isSending) return;
    final textToSend = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);
    try {
      final response = await _apiClient.dio.post('/chat/messages', data: {
        'chatId': _chatId,
        'text': textToSend,
      });

      setState(() {
        _messages.add(response.data);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).userId;
    final title = widget.recipientName ?? 'Live Chat';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF2E7D32), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1C1C))),
                if (widget.orderId != null)
                  Text('Order #${widget.orderId!.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Live', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D631B)))
          : Column(
              children: [
                if (widget.orderId != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFFF3FFF3),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Text(
                          'Regarding Order #${widget.orderId!.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 56, color: Color(0xFFBFCABA)),
                              SizedBox(height: 12),
                              Text('No messages yet. Say hello! 👋',
                                  style: TextStyle(color: Color(0xFF707A6C), fontSize: 15)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, idx) {
                            final msg = _messages[idx];
                            final isMe = msg['senderUserId'] == currentUserId;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF0D631B) : Colors.white,
                                  borderRadius: BorderRadius.circular(18).copyWith(
                                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                                    bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? Colors.white : const Color(0xFF1A1C1C),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _formatTime(msg['timestamp']),
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : const Color(0xFF707A6C),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onSubmitted: (_) => _sendMessage(),
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: const TextStyle(color: Color(0xFFBFCABA)),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isSending ? Colors.grey : const Color(0xFF0D631B),
                            shape: BoxShape.circle,
                          ),
                          child: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(dynamic sentAt) {
    if (sentAt == null) return '';
    try {
      final dt = DateTime.parse(sentAt.toString()).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
