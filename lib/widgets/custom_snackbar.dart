import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String label,
    String? title="Aw, Snap!",
    double padding = 16,
    double radius = 20,
    Color color=const Color(0xFFC72C41),
    Color svgColor=const Color(0xFFDF4F62),  String? actionLabel,   VoidCallback?  onAction,
  }) {



    // Hide Keyboard If Appear on the Screen
    WidgetsBinding.instance.addPostFrameCallback((_){
      FocusScope.of(context).unfocus();
    });


    final snackBar = SnackBar(
      dismissDirection:DismissDirection.horizontal,
      content: Stack(
        clipBehavior: Clip.none,
        children: [
          IntrinsicHeight(
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title,
                            style: const TextStyle(fontSize: 18, color: Colors.white,fontWeight: FontWeight.bold),
                          ),
                        Text(
                          label,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),


          Positioned(
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
              ),
              child: SvgPicture.asset(
                "assets/images/bubbles.svg",
                height: 48,
                width: 40,
                colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
              ),
            ),
          ),


          Positioned(
              top: -14,
              left: 0,
              child: InkWell(
                onTap: (){
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: Stack(
                    alignment: Alignment.center,
                    children:[
                      SvgPicture.asset("assets/images/back.svg",

                        colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
                        height: 40,
                      ),

                      Positioned(
                          top:10,
                          child:SvgPicture.asset("assets/images/failure.svg",
                            height: 16,
                          )
                      ),

                    ]
                ),
              )
          ),



        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      duration: const Duration(seconds:5),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
        label: actionLabel,
        onPressed: onAction,
      )
          : null,
    );

    // Show Snackbar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

// static void hideSnackBar(BuildContext context) {
//   ScaffoldMessenger.of(context).hideCurrentSnackBar();
// }


}
