import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingFriendRequestsScreen extends StatefulWidget {
  final String currentUserId;

  const PendingFriendRequestsScreen({super.key, required this.currentUserId});

  @override
  State<PendingFriendRequestsScreen> createState() =>
      _PendingFriendRequestsScreenState();
}

class _PendingFriendRequestsScreenState
    extends State<PendingFriendRequestsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _subscribeToChanges();
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading= true;
    });
    final response = await supabase
        .from('friend_requests')
        .select(
        'id, sender_id, status, profiles!friend_requests_sender_id_fkey(username, avatar_url, full_name)')
        .eq('receiver_id', widget.currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    setState(() {
      _requests = response;
      isLoading = false;
    });
  }

  void _subscribeToChanges() {
    supabase
        .channel('friend_requests_changes')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'friend_requests',
      filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'receiver_id',
          value: widget.currentUserId),
      callback: (payload) {
        _loadRequests();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'friend_requests',
      filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'receiver_id',
          value: widget.currentUserId),
      callback: (payload) {
        _loadRequests();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'friend_requests',
      callback: (payload) {
        _loadRequests();
      },
    )

        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'friend_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: widget.currentUserId,
      ),
      callback: (payload) {
        setState(() {
          _requests.removeWhere((req) => req['id'] == payload.oldRecord['id']);
        });
      },
    )
        .subscribe();
  }


  // requestID is the ID of the friend request table
  Future<void> _acceptRequest(String requestId, String senderId) async {
    final currentUserId = widget.currentUserId;

    try {
      //  Update the friend request status
      await supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      //  Check if the friendship already exists
      final existingFriend = await supabase
          .from('friends')
          .select('id')
          .or(
          'and(user_id_1.eq.$currentUserId,user_id_2.eq.$senderId),'
              'and(user_id_1.eq.$senderId,user_id_2.eq.$currentUserId)'
      )
          .maybeSingle();

      if (existingFriend == null) {
        // Insert the new friendship
        await supabase.from('friends').insert({
          'user_id_1': currentUserId,
          'user_id_2': senderId,
          'can_share_location': false,
        });
      }
      // Remove the request from the list
      setState(() {
        _requests.removeWhere((req) => req['id'] == requestId);
      });
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting friend request: $e')),

      );
    }
  }


  Future<void> _deleteRequest(String requestId) async {

    try{
      final response=await supabase
          .from('friend_requests')
          .delete()
          .eq('id', requestId).select();

      if (response.isNotEmpty) {
        setState(() {
          _requests.removeWhere((req) => req['id'] == requestId);
        });
      }

    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting request: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Friend Requests"),
        centerTitle: true,
      ),
      body: _requests.isEmpty
          ? const Center(
        child: Text(
          "No pending friend requests 🎉",
          style: TextStyle(fontSize: 16),
        ),
      )
          : isLoading?Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      ):ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final req = _requests[index];
          final profile = req['profiles'];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundImage: profile['avatar_url'] != null
                  ? NetworkImage(profile['avatar_url'])
                  : null,
              child: profile['avatar_url'] == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            title: Text(
              profile['full_name'] ?? profile['username'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text("@${profile['username']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.green[800],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>  _acceptRequest(req['id'], req['sender_id']),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8), // space between buttons
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _deleteRequest(req['id']),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                  ),
                ),
              ],

            ),
          );
        },
      ),
    );
  }
}
