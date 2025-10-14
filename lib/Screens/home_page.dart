
import 'package:companion/Screens/settings.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'active_journey_list.dart';
import 'companionsscreen.dart';
import 'dashboard.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({required this.user, super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late final User user;
  late List<Widget> screens;
  int index = 0;

  // Bottom Navigator bar icons
  List<CurvedNavigationBarItem> items = <CurvedNavigationBarItem>[
    CurvedNavigationBarItem(
        child:Icon(Icons.home_outlined),
        label: 'Home'
    ),
    CurvedNavigationBarItem(
      child:Icon(Icons.people_alt_outlined),
      label: 'Companions'
    ),

    CurvedNavigationBarItem(
        child:Icon(Icons.mode_of_travel_outlined),
        label: 'Rides'
    ),

    CurvedNavigationBarItem(
        child:Icon(Icons.settings),
        label: 'Settings'

    )



  ];

  @override
  void initState() {
    super.initState();

    user = widget.user;
    screens = <Widget>[
      Dashboard(user: user),
      CompanionsScreen(),
      JourneyViewersListScreen(),
      SettingPage(user: user,),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;


    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    );
    return SafeArea(

      child: ClipRect(
        child: Scaffold(
          body: screens[index],
          bottomNavigationBar: CurvedNavigationBar(
            height: 65,
            items: items,
            index: index,
            color: Colors.blue.shade300,
            backgroundColor: index==0?(isDark ? Color(0xff202327) : Color(0xffffffff)):  Colors.transparent,
            onTap: (index) {
              setState(() {
                this.index = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
