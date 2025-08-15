import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Services/notification_service.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';

class FriendProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  final String _userId;

  List<FriendRequest> _pendingRequests = [];
  List<Friend> _friends = [];

  // object create instance pass
  FriendProvider(this._supabase, this._userId);

  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<Friend> get friends => _friends;


  // get pendingRequest
  Future<void> fetchFriendRequests() async {
    final data = await _supabase
        .from('friend_requests')
        .select()
        .eq('receiver_id', _userId)
        .eq('status', 'pending');

    _pendingRequests = data.map((req) => FriendRequest.fromMap(req)).toList();
    notifyListeners();
  }

  Future<void> fetchFriends() async {
    final data = await _supabase
        .from('friends')
        .select()
        .or('user1_id.eq.$_userId,user2_id.eq.$_userId');

    _friends = data.map((friend) => Friend.fromMap(friend)).toList();
    notifyListeners();
  }








  // In your FriendProvider or wherever you handle friend requests
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      // First get the request details
      final request = await _supabase
          .from('friend_requests')
          .select('sender_id, receiver_id')
          .eq('id', requestId)
          .single();

      // Update the request status
      await _supabase
          .from('friend_requests')
          .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);

      // Get receiver's username for the notification
      final receiverData = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', request['receiver_id'])
          .single();

      // Send acceptance notification
      final notificationService = NotificationService();
      await notificationService.sendFriendRequestAcceptedNotification(
        senderId: request['sender_id'],
        receiverName: receiverData['username'],
      );

      // Refresh data
      await fetchFriendRequests();
      await fetchFriends();
    } catch (e) {
      if (kDebugMode) print('Error accepting friend request: $e');
      rethrow;
    }
  }




  Future<void> sendFriendRequest(String receiverUsername,String currentUser) async {
    // First get receiver ID from username
    final receiverData = await _supabase
        .from('profiles')
        .select('id, full_name')
        .eq('username', receiverUsername)
        .single();

    // to get current userName who is sending the request
    final senderData=await _supabase
        .from('profiles')
        .select('id, full_name')
        .eq('id', currentUser)
        .single();

    await _supabase.from('friend_requests').insert({
      'sender_id': _userId,
      'receiver_id': receiverData['id'],
      'sender_name': senderData['full_name'],
      'receiver_name': receiverData['full_name'],
    });


  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    if (accept) {
      // Get the request first
      final request = await _supabase
          .from('friend_requests')
          .select()
          .eq('id', requestId)
          .single();

      // Update request status
      await _supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      // Add to friends table
      await _supabase.from('friends').insert({
        'user1_id': request['sender_id'],
        'user2_id': request['receiver_id'],
      });
    } else {
      await _supabase
          .from('friend_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);
    }

    await fetchFriendRequests();
    await fetchFriends();
  }
}