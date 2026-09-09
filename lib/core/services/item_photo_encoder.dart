import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ItemPhotoBundle {
  /// Small preview stored inside the item document (data URI).
  final String thumbnail;

  /// Full-size photos stored in a side document (data URIs).
  final List<String> photos;

  const ItemPhotoBundle({required this.thumbnail, required this.photos});
}

/// Encodes picked photos into Firestore-friendly data URIs. Photos stay on
/// the free Spark plan by living inside Firestore instead of Storage, so
/// sizes are capped aggressively:
///  - picker already downscales to ~1024px JPEG (~70-150KB each)
///  - one ~320px thumbnail rides along in the item document
///  - whole bundle must stay under the Firestore 1MB document limit
class ItemPhotoEncoder {
  ItemPhotoEncoder._();

  static const _maxTotalBytes = 700 * 1024;

  /// Throws [PhotoTooLargeException] when the selection cannot fit.
  static Future<ItemPhotoBundle> encode(List<File> files) async {
    final photos = <String>[];
    Uint8List? firstBytes;

    for (final file in files) {
      final bytes = await file.readAsBytes();
      photos.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      firstBytes ??= bytes;
    }

    final total = photos.fold<int>(0, (sum, uri) => sum + uri.length);
    if (total > _maxTotalBytes) {
      throw const PhotoTooLargeException();
    }

    return ItemPhotoBundle(
      thumbnail: _makeThumbnail(firstBytes),
      photos: photos,
    );
  }

  static String _makeThumbnail(Uint8List? bytes) {
    if (bytes == null) return '';
    try {
      final decoded = img.decodeJpg(bytes);
      if (decoded == null) return '';
      final resized = img.copyResize(decoded, width: 320);
      final thumb = Uint8List.fromList(img.encodeJpg(resized, quality: 68));
      return 'data:image/jpeg;base64,${base64Encode(thumb)}';
    } on Object {
      return '';
    }
  }

  /// Builds a 320px thumbnail from an already-stored photo data URI.
  static Future<String> thumbnailFor(String dataUri) async {
    if (!dataUri.startsWith('data:image/jpeg;base64,')) return '';
    try {
      final bytes = base64Decode(dataUri.split(',').last);
      return _makeThumbnail(bytes);
    } on Object {
      return '';
    }
  }
}

class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException();
}
