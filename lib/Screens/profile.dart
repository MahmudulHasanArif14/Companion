import 'package:flutter/material.dart';

import '../core/utils/constant.dart';
import 'Personal_info.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 1,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            forceMaterialTransparency: true,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(onPressed: (){
              Navigator.pop(context);
            }, icon: Icon(Icons.arrow_back, color: AppColors.getAppBarColor(context))),
            animateColor: true,
            elevation: 0,
            title: const Text(
              "My Profile",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.canvasColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFF3085FE),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_outline),
                              SizedBox(width: 6),
                              Text("Personal Info"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: const TabBarView(
            children: [
              ProfileDetails(),
            ],
          ),
        ),
      ),
    );
  }
}


