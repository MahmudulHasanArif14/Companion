// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class JourneyChatScreen extends StatefulWidget {
//   final String journeyId;
//
//   const JourneyChatScreen({super.key, required this.journeyId});
//
//   @override
//   State<JourneyChatScreen> createState() => _JourneyChatScreenState();
// }
//
// class _JourneyChatScreenState extends State<JourneyChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   List<Map<String, dynamic>> _messages = [];
//   Timer? _pollingTimer;
//   final SupabaseClient _client = Supabase.instance.client;
//   final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchMessages();
//     _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchMessages());
//   }
//
//   @override
//   void dispose() {
//     _pollingTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _fetchMessages() async {
//     final response = await _client
//         .from('journey_messages')
//         .select('id, sender_id, message, created_at, status, profiles(full_name, avatar_url)')
//         .eq('journey_id', widget.journeyId)
//         .order('created_at', ascending: true);
//
//     final List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(response);
//
//     // Mark messages as delivered if they are received by this user
//     for (var msg in messages) {
//       if (msg['sender_id'] != _currentUserId && msg['status'] == 'sent') {
//         await _client
//             .from('journey_messages')
//             .update({'status': 'delivered'})
//             .eq('id', msg['id']);
//         msg['status'] = 'delivered';
//       }
//     }
//
//     setState(() => _messages = messages);
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent + 60,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//
//     // Mark messages as seen if chat is open
//     for (var msg in messages) {
//       if (msg['sender_id'] != _currentUserId && msg['status'] != 'seen') {
//         await _client
//             .from('journey_messages')
//             .update({'status': 'seen'})
//             .eq('id', msg['id']);
//       }
//     }
//     }
//
//   Future<void> _sendMessage() async {
//     final text = _messageController.text.trim();
//     if (text.isEmpty) return;
//
//     if (_currentUserId != null) {
//       final res = await _client.from('journey_messages').insert({
//         'journey_id': widget.journeyId,
//         'sender_id': _currentUserId,
//         'message': text,
//         'status': 'sent',
//       }).select().single();
//
//       _messageController.clear();
//       _fetchMessages();
//     }
//   }
//
//   Widget _buildMessageBubble(Map<String, dynamic> msg) {
//     final isMe = msg['sender_id'] == _currentUserId;
//     final status = msg['status'] ?? 'sent';
//
//     Icon? statusIcon;
//     if (isMe) {
//       if (status == 'sent') statusIcon = const Icon(Icons.check, size: 16, color: Colors.grey);
//       if (status == 'delivered') statusIcon = const Icon(Icons.check, size: 16, color: Colors.grey);
//       if (status == 'seen') statusIcon = const Icon(Icons.check, size: 16, color: Colors.blue);
//     }
//
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blueAccent : Colors.grey[300],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment:
//           isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//           children: [
//             if (!isMe)
//               Text(
//                 msg['profiles'] != null ? msg['profiles']['full_name'] : "Unknown",
//                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//               ),
//             Text(
//               msg['message'] ?? '',
//               style: TextStyle(color: isMe ? Colors.white : Colors.black87),
//             ),
//             const SizedBox(height: 2),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   msg['created_at'] != null
//                       ? DateTime.parse(msg['created_at']).toLocal().toString().substring(11, 16)
//                       : "",
//                   style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
//                 ),
//                 if (statusIcon != null) ...[
//                   const SizedBox(width: 4),
//                   statusIcon,
//                 ]
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Journey Chat"), centerTitle: true),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(8),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
//             ),
//           ),
//           const Divider(height: 1),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             color: Colors.white,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: const InputDecoration(hintText: "Type a message..."),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send, color: Colors.blue),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
