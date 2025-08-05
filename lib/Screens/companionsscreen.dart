import 'package:flutter/material.dart';

import 'add_companion.dart';
//import 'package:lucide_icons/lucide_icons.dart';

class CompanionsScreen extends StatelessWidget {
  const CompanionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companions = [
      {'name': 'Jane Hawkins', 'email': 'janehawkins@demo.com', 'avatar': 'assets/avatars/avatar1.png'},
      {'name': 'Brooklyn Simmons', 'email': 'brooklynsimmons@demo.com', 'avatar': 'assets/avatars/avatar2.png'},
      {'name': 'Leslie Alexander', 'email': 'lesliealexander@demo.com', 'avatar': 'assets/avatars/avatar3.png'},
      {'name': 'Ronald Richards', 'email': 'ronaldrichards@demo.com', 'avatar': 'assets/avatars/avatar4.png'},
      {'name': 'Jenny Wilson', 'email': 'jennywilson@demo.com', 'avatar': 'assets/avatars/avatar5.png'},
    ];

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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert, color: Colors.black),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: companions.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final user = companions[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(user['avatar']!),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user['email']!,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
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
          //BottomNavigationBarItem(icon: Icon(LucideIcons.shield), label: 'Safety'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
