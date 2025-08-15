import 'package:companion/Auth/auth_helper.dart';
import 'package:companion/Screens/pending_friend_req.dart';
import 'package:flutter/material.dart';
import 'add_companion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanionsScreen extends StatefulWidget {
  const CompanionsScreen({super.key});

  @override
  State<CompanionsScreen> createState() => _CompanionsScreenState();
}

class _CompanionsScreenState extends State<CompanionsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final currentUserId = OauthHelper.currentUser()!.id;

    try {
      final response = await supabase
          .from('friends')
          .select('user_id_1, user_id_2, can_share_location, '
          'profiles!friends_user_id_2_fkey(id, username, full_name, avatar_url)')
          .or('user_id_1.eq.$currentUserId,user_id_2.eq.$currentUserId');

      List<Map<String, dynamic>> friendsList = [];

      for (var row in response) {
        Map<String, dynamic> friendProfile;
        if (row['user_id_1'] == currentUserId) {
          friendProfile = row['profiles']; // user_id_2 profile
        } else {
          final profileRes = await supabase
              .from('profiles')
              .select('id, username, full_name, avatar_url')
              .eq('id', row['user_id_1'])
              .single();
          friendProfile = profileRes;
        }

        friendsList.add({
          'id': friendProfile['id'],
          'username': friendProfile['username'],
          'full_name': friendProfile['full_name'],
          'avatar_url': friendProfile['avatar_url'],
          'can_share_location': row['can_share_location'],
        });
      }

      setState(() {
        _friends = friendsList;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching friends: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = OauthHelper.currentUser()!.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text(
          'Companions',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'Pending Requests') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PendingFriendRequestsScreen(currentUserId: currentUserId),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'Pending Requests',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Pending Requests'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                ? const Center(child: Text('No companions found.'))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _friends.length,
              separatorBuilder: (context, index) =>
              const Divider(height: 24),
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: friend['avatar_url'] != null
                          ? NetworkImage(friend['avatar_url'])
                          : null,
                      child: friend['avatar_url'] == null
                          ? const Icon(Icons.person, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend['full_name'] ?? friend['username'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Text('@${friend['username']}',
                              style: TextStyle(
                                  color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (friend['can_share_location'] == true)
                      const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    const Icon(Icons.more_vert),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                AddContactDialog.show(context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A57FF),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Add Companions',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A57FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Location'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
