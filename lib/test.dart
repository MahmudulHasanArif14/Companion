import 'package:flutter/material.dart';



class Demo extends StatelessWidget {
  const Demo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Email', // Placeholder
                border: InputBorder.none, // No border
              ),
              cursorColor: Colors.blue, // Optional: customize cursor color
              style: TextStyle(fontSize: 18), // Optional: text styling
            ),
          ),
        ),
      ),
    );
  }

}
