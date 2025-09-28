import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:heif_converter/heif_converter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_snackbar.dart';

class ProfileImageProvider extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  String? _imageUrl;
  bool _isUploading = false;
  Uint8List? _cachedImageBytes;

  Uint8List? get cachedImageBytes => _cachedImageBytes;
  String? get imageUrl => _imageUrl;
  bool get isUploading => _isUploading;

  ProfileImageProvider(BuildContext context) {
    _loadCachedImage(context);
    loadUserProfileImage(context);
  }

  /// Load cached image from SharedPreferences
  Future<void> _loadCachedImage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    /// Image Base64 getting so image can be shown quickly
    final cachedBase64 = prefs.getString('avatar_base64');
    if (cachedBase64 != null) {
      try {
        _cachedImageBytes = base64Decode(cachedBase64);
        notifyListeners();
      } catch (e) {

        if(context.mounted){
          CustomSnackbar.show(context: context, label: 'Failed to decode cached image: $e');

        }

      }
    }
  }

  /// Load latest avatar URL from Supabase profiles table
  Future<void> loadUserProfileImage(BuildContext context) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response =
      await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();

      final newUrl = response['avatar_url'];

      if (newUrl != null && newUrl != _imageUrl) {
        _imageUrl = newUrl;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar_url', newUrl);
        notifyListeners();
      }
    } catch (e) {

      if(context.mounted){
        CustomSnackbar.show(context: context, label: 'Failed to load user profile image: $e');

      }

    }
  }

  /// Pick image and convert if needed
  Future<void> pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: 'No image selected');
      }
      return;
    }

    final filePath = pickedFile.path;
    final extension = filePath.split('.').last.toLowerCase();
    Uint8List? finalBytes;

    try {
      if (extension == 'heic' || extension == 'heif') {
        final convertedPath = await HeifConverter.convert(
          filePath,
          format: 'jpg',
        );
        if (convertedPath == null) {
          if (context.mounted) {
            CustomSnackbar.show(
              context: context,
              label: 'HEIC conversion failed',
            );
          }
          return;
        }
        finalBytes = await File(convertedPath).readAsBytes();
      } else {
        finalBytes = await pickedFile.readAsBytes();
      }

      if (context.mounted) {
        await uploadImageBytes(context, finalBytes, 'jpg');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: 'Failed to process image');
      }
    }
  }

  /// Upload image to Supabase and cache in SharedPreferences
  Future<void> uploadImageBytes(
      BuildContext context,
      Uint8List fileBytes,
      String extension,
      ) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: 'User not authenticated');
      }
      return;
    }

    _isUploading = true;
    notifyListeners();

    try {
      final filePath = '$userId/profile.$extension';

      // upload process in bucket
      await supabase.storage
          .from('profiles')
          .uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/$extension',
        ),
      );

      // getting the public url to fetch the image
      final publicUrl = supabase.storage
          .from('profiles')
          .getPublicUrl(filePath);
      final urlWithTimestamp = _appendTimestampToUrl(publicUrl);

      await supabase
          .from('profiles')
          .update({'avatar_url': urlWithTimestamp})
          .eq('id', userId);

      _imageUrl = urlWithTimestamp;
      _cachedImageBytes = fileBytes;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_url', urlWithTimestamp);
      await prefs.setString('avatar_base64', base64Encode(fileBytes));

      if (context.mounted) {
        CustomSnackbar.show(
          title: 'Boom! Success!',
          context: context,
          label: 'Profile image updated successfully!',
          color: const Color(0xE04CAF50),
          svgColor: const Color(0xE0178327),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: 'Image upload failed');
      }
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Append timestamp to update the url
  String _appendTimestampToUrl(String url) {
    final uri = Uri.parse(url);
    final updatedUri = uri.replace(
      queryParameters: {
        ...uri.queryParameters, /// Add all existing query parameters with spread operator
        'updated': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    return updatedUri.toString();
  }
}
