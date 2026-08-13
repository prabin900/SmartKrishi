import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'n_1',
      'title': 'Order Dispatched',
      'body': 'Your order #SK-9081 has been picked up by Suman Thapa and is on the way!',
      'time': '10 mins ago',
      'read': false,
      'icon': Icons.local_shipping
    },
    {
      'id': 'n_2',
      'title': 'Contract Signed',
      'body': 'Ram Prasad Shrestha accepted your crop requisition contract for Tomato supply.',
      'time': '2 hours ago',
      'read': false,
      'icon': Icons.handshake
    },
    {
      'id': 'n_3',
      'title': 'Price Alert',
      'body': 'High mountain apples from Mustang Orchard dropped to Rs. 180/kg today.',
      'time': '1 day ago',
      'read': true,
      'icon': Icons.trending_down
    }
  ];

  void _markAllRead() {
    setState(() {
      for (var item in _notifications) {
        item['read'] = true;
      }
    });
  }

  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read', style: TextStyle(color: Color(0xFF2E7D32))),
          )
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No new notifications.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, idx) {
                final note = _notifications[idx];
                return Dismissible(
                  key: Key(note['id']),
                  onDismissed: (direction) => _dismissNotification(note['id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    color: note['read'] ? Colors.white : const Color(0xFF2E7D32).withOpacity(0.05),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: note['read'] ? Colors.grey.shade200 : const Color(0xFF2E7D32).withOpacity(0.1),
                        child: Icon(note['icon'], color: note['read'] ? Colors.grey : const Color(0xFF2E7D32)),
                      ),
                      title: Text(note['title'] ?? '', style: TextStyle(fontWeight: note['read'] ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(note['body'] ?? ''),
                          const SizedBox(height: 4),
                          Text(note['time'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
