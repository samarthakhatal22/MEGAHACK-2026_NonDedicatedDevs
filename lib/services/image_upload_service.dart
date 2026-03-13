import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

class ImageUploadService {
  final String cloudName;
  final String uploadPreset;

  ImageUploadService({
    required this.cloudName,
    required this.uploadPreset,
  });

  /// Uploads image bytes to Cloudinary and returns the secure URL.
  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      debugPrint('Cloudinary credentials missing.');
      return null;
    }

    try {
      final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
      
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: fileName,
          folder: 'fact_checks',
        ),
      );

      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      return null;
    }
  }
}
