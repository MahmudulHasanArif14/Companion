import 'dart:ui';
import 'package:companion/Providers/friend_provider.dart';
import 'package:companion/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Services/notification_service.dart';
import '../database/database_helper.dart';

class AddContactDialog {
  static void show({required BuildContext context}) {
    final TextEditingController usernameController = TextEditingController();
    // Local state variables
    bool showUserInfo = false;
    String? localErrorMessage;
    bool isSearching = false;
    bool isSendingRequest = false;
    Map<String, dynamic>? foundUser;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: "Add Contact Dialog",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final size = MediaQuery.of(context).size;

        return StatefulBuilder(
          builder: (context, setState) {
            final dbProvider = Provider.of<DatabaseHelperProvider>(context, listen: false);



            Future<void> searchUser() async {
              final username = usernameController.text.trim();

              if (!_validateUsername(username)) {
                setState(() => localErrorMessage = "Username must be at least 3 characters");
                return;
              }

              setState(() {
                localErrorMessage = null;
                isSearching = true;
                showUserInfo = false;
                foundUser = null;
              });

              try {
                await dbProvider.fetchSpecificUser(username);

                if (!context.mounted) return;

                final profile = dbProvider.profile;
                if (profile == null) {
                  setState(() => localErrorMessage = "User not found");
                  return;
                }

                final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                if (currentUserId == null) {
                  setState(() => localErrorMessage = "Not authenticated");
                  return;
                }

                if (profile['id'] == currentUserId) {
                  setState(() => localErrorMessage = "You can't add yourself");
                  return;
                }


                final existingRequest = await Supabase.instance.client
                    .from('friend_requests')
                    .select('id')
                    .eq('sender_id', currentUserId)
                    .eq('receiver_id', profile['id'])
                    .maybeSingle();

                if (existingRequest != null) {
                  // A request already exists
                  setState(() => localErrorMessage = "Friend request already sent");
                  return;
                }

                setState(() {
                  foundUser = profile;
                  showUserInfo = true;
                  localErrorMessage = null;
                });
              } catch (e) {
                if (context.mounted) {
                  setState(() => localErrorMessage = "Failed to search user");
                }
                if (kDebugMode) print('Error searching user: $e');
              } finally {
                if (context.mounted) {
                  setState(() => isSearching = false);
                }
              }
            }



            // send friend Request
            // This function sends a friend request to the found user
            Future<void> sendRequest() async {
              if (foundUser == null) return;

              setState(() => isSendingRequest = true);

              try {
                final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                if (currentUserId == null) {
                  setState(() => localErrorMessage = "Not authenticated");
                  return;
                }

                final friendProvider = FriendProvider(
                  Supabase.instance.client,
                  currentUserId,
                );







                await friendProvider.sendFriendRequest(foundUser!['username'],currentUserId);

                // Get sender's username
                final senderProfile = await Supabase.instance.client
                    .from('profiles')
                    .select('username')
                    .eq('id', currentUserId)
                    .single();


                if (context.mounted) {
                  usernameController.clear();

                  CustomSnackbar.show(context: context,
                      label: 'Friend request sent to ${foundUser!['username']}',
                  );

                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  setState(() => localErrorMessage = "Failed to send request");
                }
                if (kDebugMode) print('Error sending friend request: $e');
              } finally {
                if (context.mounted) {
                  setState(() => isSendingRequest = false);
                }
              }
            }

            return Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
                Center(
                  child: Dialog(
                    elevation: 0,
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: size.width * 0.95,
                      constraints: BoxConstraints(
                        maxHeight: size.height * 0.85,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!showUserInfo) ...[
                                _buildTopActionButtons(),
                                const SizedBox(height: 30),
                                _buildAddContactHeader(),
                                const SizedBox(height: 20),
                                _buildUsernameInputField(usernameController),
                                const SizedBox(height: 8),
                                if (localErrorMessage != null)
                                  _buildErrorMessage(localErrorMessage!),
                                if (localErrorMessage == null)
                                  _buildSecurityInfo(),
                                const SizedBox(height: 20),
                                _buildQuickAddSection(),
                                const SizedBox(height: 20),
                              ],

                              if (isSearching || isSendingRequest)
                                _buildLoadingIndicator(),

                              if (foundUser != null && showUserInfo)
                                _buildUserInfoCard(foundUser!),

                              const SizedBox(height: 20),
                              _buildActionButtons(
                                context: context,
                                showUserInfo: showUserInfo,
                                isSendingRequest: isSendingRequest,
                                onSearch: searchUser,
                                onSendPressed: sendRequest,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }

  static Widget _buildTopActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildIconButton(Icons.share_location),
        _buildIconButton(Icons.qr_code_scanner),
        _buildIconButton(Icons.notifications_none),
      ],
    );
  }

  static Widget _buildAddContactHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildIconButton(Icons.person_add, color: Colors.greenAccent),
                const SizedBox(width: 15),
                Text(
                  "Add Contact",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Send a friend request to start sharing",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildUsernameInputField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Username",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            suffixText: "@",
            hintText: "Enter username",
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: 13,
        ),
      ),
    );
  }

  static Widget _buildSecurityInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[900]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "Secure location sharing begins once accepted",
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildQuickAddSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.qr_code, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Text(
              "Quick Add",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            "Scan",
            style: TextStyle(color: Colors.greenAccent),
          ),
        ),
      ],
    );
  }

  static Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.greenAccent,
        ),
      ),
    );
  }

  static Widget _buildUserInfoCard(Map<String, dynamic> userData) {
    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 40,
          backgroundImage: userData['avatar_url'] != null
              ? NetworkImage(userData['avatar_url'])
              : null,
          child: userData['avatar_url'] == null
              ? Icon(Icons.person, size: 40, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          userData['username'] ?? 'N/A',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (userData['full_name'] != null) ...[
          const SizedBox(height: 8),
          Text(
            userData['full_name'],
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  static Widget _buildActionButtons({
    required BuildContext context,
    required bool showUserInfo,
    required bool isSendingRequest,
    required VoidCallback onSearch,
    required VoidCallback onSendPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.grey[700]!),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: showUserInfo ? onSendPressed : onSearch,
            child: isSendingRequest
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
                : Text(showUserInfo ? "Send Request" : "Search"),
          ),
        ),
      ],
    );
  }

  static Widget _buildIconButton(IconData icon, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  static bool _validateUsername(String username) {
    if (username.isEmpty) return false;
    if (username.length < 3) return false;
    if (username.contains(' ')) return false;
    return true;
  }
}