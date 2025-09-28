import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? ""),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            placesAutoCompleteTextField(),
          ],
        ),
      ),
    );
  }

  Widget placesAutoCompleteTextField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: controller,
        googleAPIKey: "AIzaSyBf7Fs8FpwkMhEMUbOt9wsMUoQT10FSLa0",
        inputDecoration: const InputDecoration(
          hintText: "Search your location",
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        debounceTime: 400,
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          debugPrint("Lat: ${prediction.lat}, Lng: ${prediction.lng}");
        },
        itemClick: (Prediction prediction) {
          controller.text = prediction.description ?? "";
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        },
        seperatedBuilder:  Divider(), // Correct spelling here
        containerHorizontalPadding: 10,
        itemBuilder: (context, index, Prediction prediction) {
          return Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 7),
                Expanded(child: Text(prediction.description ?? "")),
              ],
            ),
          );
        },
        isCrossBtnShown: true,
      ),
    );
  }
}
