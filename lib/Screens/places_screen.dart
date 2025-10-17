import 'package:flutter/material.dart';
import '../core/utils/constant.dart';
import 'add_place_map_screen.dart';

class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  void openPlace(BuildContext context, String placeType, {bool isCustom = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPlaceMapScreen(
          placeType: placeType,
          isCustom: isCustom,
        ),
      ),
    );
  }

  Widget buildPlaceItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool showBell = false,
    bool isAddNew = false,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor:
        isAddNew ? Colors.purple : Colors.purple.withOpacity(0.1),
        child: Icon(icon, color: isAddNew ? Colors.white : Colors.purple),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isAddNew ? Colors.purple : Colors.black,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isAddNew)
            Icon(Icons.close, color: Colors.purple.withOpacity(0.8)),
          if (showBell) const SizedBox(width: 12),
          if (showBell) Icon(Icons.notifications, color: AppColors.getIconColor(context)),
        ],
      ),
      onTap: () {
        if (isAddNew) {
          openPlace(context, "Custom Place", isCustom: true);
        } else {
          openPlace(context, title);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Places"),
        leading: IconButton(
          icon:  Icon(Icons.arrow_back,color: AppColors.getAppBarColor(context),),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          buildPlaceItem(
            context: context,
            icon: Icons.add,
            title: "Add a new Place",
            isAddNew: true,
          ),
          buildPlaceItem(
            context: context,
            icon: Icons.home,
            title: "Home",
            showBell: true,
          ),

          SizedBox(
            height: 16,
          ),
          buildPlaceItem(
            context: context,
            icon: Icons.work,
            title: "Office",
            showBell: true,
          ),

          SizedBox(
            height: 16,
          ),
          buildPlaceItem(
            context: context,
            icon: Icons.school,
            title: "School",
          ),

          SizedBox(
            height: 16,
          ),
          buildPlaceItem(
            context: context,
            icon: Icons.fitness_center,
            title: "Gym",
          ),

          SizedBox(
            height: 16,
          ),
          buildPlaceItem(
            context: context,
            icon: Icons.shopping_cart,
            title: "Grocery Store",
          ),
        ],
      ),
    );
  }
}
