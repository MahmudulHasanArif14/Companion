import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String label,
    String? title = "Aw, Snap!",
    double padding = 16,
    double radius = 20,
    Color color = const Color(0xFFC72C41),
    Color svgColor = const Color(0xFFDF4F62),
    String? actionLabel,
    VoidCallback? onAction,
  }) {

    // Hide keyboard if visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    final snackBar = SnackBar(
      dismissDirection: DismissDirection.horizontal,
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),

      content: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 380;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              IntrinsicHeight(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),

                            if (actionLabel != null && onAction != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: GestureDetector(
                                  onTap: onAction,
                                  child: Text(
                                    actionLabel,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
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
                  borderRadius: const BorderRadius.only(
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
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/images/back.svg",
                        colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
                        height: 40,
                      ),
                      Positioned(
                        top: 10,
                        child: SvgPicture.asset(
                          "assets/images/failure.svg",
                          height: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(snackBar);
  }

  static void hideSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
