import 'dart:ui';
import 'package:flutter/material.dart';

class AddContactDialog {
  static void show({
    required BuildContext context,
  }) {
    final TextEditingController usernameController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: "Add Contact Dialog",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final size = MediaQuery.of(context).size;

        return Stack(
          children: [
            // Blurred background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            // Dialog content
            Center(
              child: Dialog(
                elevation: 0,
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: size.width * 0.95,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIconButton(Icons.share_location),
                            _buildIconButton(Icons.qr_code_scanner),
                            _buildIconButton(Icons.notifications_none),
                          ],
                        ),
                        const SizedBox(height: 30),

                        Container(
                           decoration: BoxDecoration(
                             color: Colors.black,
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: Colors.grey[800]!),
                           ),
                           child: Padding(
                             padding: const EdgeInsets.all(8.0),
                             child: Column(
                               children: [
                                 // Header
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
                         ),




                        const SizedBox(height: 20),

                        // Username field
                        Text(
                          "Username",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: usernameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter username",
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Secure info
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[900]!.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16,
                                  color: Colors.greenAccent),
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
                        ),
                        const SizedBox(height: 20),

                        // QR code section
                        Row(
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
                        ),
                        const SizedBox(height: 20),

                        // Buttons
                        Row(
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
                                child: Text("Cancel"),
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
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Handle send request
                                },
                                child: Text("Send Request"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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


  static Widget _buildIconButton(IconData icon,{Color color=Colors.white }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }


}

