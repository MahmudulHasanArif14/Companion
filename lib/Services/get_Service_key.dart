import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

class GetServiceKey {
  Future<String> getServiceKey() async {
    // FCM v1 API scope
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // Load your service account JSON
    final jsonString = await rootBundle.loadString('assets/images/credentials.json');
    final jsonData = jsonDecode(jsonString);

    // Authenticate and get OAuth2 token
    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(jsonData),
      scopes,
    );

    final accessToken = client.credentials.accessToken.data;
    client.close();

    return accessToken; // This is your Bearer token for FCM v1 API
  }
}
