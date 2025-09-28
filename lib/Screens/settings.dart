
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Auth/auth_helper.dart';
import '../Providers/profile_image_provider.dart';
import '../Providers/theme_provider.dart';
import 'login_page.dart';
import 'onboarding_screen.dart';

class SettingPage extends StatefulWidget {
  final User user;
  const SettingPage({super.key, required this.user});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late final User userInfo;
  late final String fullName;
  bool isDark = true;

  @override
  void initState() {
    super.initState();

    userInfo = widget.user;
    fullName = (userInfo.userMetadata?['name'] ?? 'David').toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final height=MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Consumer<ProfileImageProvider>(
                  builder: (ctx, profileProvider, child) {
                    final imageUrl = profileProvider.imageUrl;
                    final isLoading = profileProvider.isUploading;

                    ImageProvider imageProvider;
                    if (profileProvider.cachedImageBytes != null) {
                      imageProvider = MemoryImage(
                        profileProvider.cachedImageBytes!,
                      );
                    } else if (imageUrl != null) {
                      imageProvider = NetworkImage(imageUrl);
                    } else {
                      imageProvider = const AssetImage(
                        "assets/images/avatar.png",
                      );
                    }

                    return Column(
                      children: [
                        SizedBox(height: height * 0.01,),
                        //Image
                        GestureDetector(
                          onTap: () => profileProvider.pickAndUploadImage(ctx),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Hero(
                                    tag: 'profile-image-hero',
                                    child: CircleAvatar(
                                      radius: 70,
                                      backgroundImage: imageProvider,
                                    ),
                                  ),
                                  if (isLoading)
                                    const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  if (!isLoading)
                                    Positioned(
                                      bottom: 0,
                                      right: 12,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey[200],
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Name
                        Text(
                          fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Position Employee
                        Text(
                          "arif55555",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.1,
                            wordSpacing: 1.1,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 15),
                // Edit Profile
                SizedBox(
                  width: 350,
                  child: TextButton(
                    onPressed: () {
                      //Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(),),);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF3085FE),
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Edit Profile",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // List Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      MenuTile(
                        icon: Icons.person_outline,
                        title: 'My Profile',
                        onTap: () {
                          // Goes to Profile page
                         /* Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(),
                            ),
                          );*/


                        },
                      ),
                      const Divider(height: 10),
                      MenuTile(
                        icon: Icons.people_outline,
                        title: 'Team Member',
                        onTap: () {
                          /*Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamMemberPage(),
                            ),
                          );*/
                        },
                      ),
                      const Divider(height: 10),
                      MenuTile(
                        icon: Icons.description_outlined,
                        title: 'Terms & Conditions',
                        onTap: () {
                          /* Navigate to Legal Page */
                         /* Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LegalScreen(),
                            ),
                          );*/
                        },
                      ),
                      const Divider(height: 10),
                      MenuTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          /* Navigate to Privacy Policy Page*/
                         /* Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivacyPolicyScreen(),
                            ),
                          );*/
                        },
                      ),
                      const Divider(height: 10),
                      SwitchListTile.adaptive(
                        activeColor: const Color(0xFF3085FE),
                        inactiveThumbColor: Colors.indigoAccent,
                        value:
                        context.watch<ThemeProvider>().themeMode ==
                            ThemeMode.dark,
                        onChanged: (value) {
                          isDark = value;
                          context.read<ThemeProvider>().toggleTheme(
                            value,
                          );
                        },
                        title: isDark?Text("Dark Mode"):Text("Light Mode"),
                        secondary:
                        isDark
                            ? Icon(Icons.dark_mode)
                            : Icon(Icons.light_mode_outlined),
                      ),
                      const Divider(height: 10),
                      const SizedBox(height: 20),
                      MenuTile(
                        icon: Icons.logout,
                        title: 'Log out',
                        iconColor: Colors.redAccent,
                        textColor: Colors.redAccent,
                        onTap: () async{
                          /* Logout logic */
                          await OauthHelper().signOutUser(context);

                          // Logout and remove all from the stack
                          if(context.mounted){
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                                  (route) => false,
                            );
                          }

                        },
                      ),


                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
