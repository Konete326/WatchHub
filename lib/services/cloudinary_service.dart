import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CloudinaryService {
  // Cloudinary credentials
  // TODO: Move to environment variables once flutter_dotenv path issue is resolved
  static const String cloudName = 'deyzo6ops';
  static const String apiKey = '882353846583382';
  static const String apiSecret = '2RpDsDp_n1xcMxlo09GopMejeoE';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static String? get _cloudName => cloudName;
  static String? get _apiKey => apiKey;
  static String? get _apiSecret => apiSecret;

  static int _serverTimeOffset = 0;

  static String _getTimestamp() {
    return ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + _serverTimeOffset)
        .toString();
  }

  static Future<void> _syncTime() async {
    try {
      // Try WorldTimeAPI first
      final response = await http
          .get(Uri.parse('https://worldtimeapi.org/api/timezone/Etc/UTC'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int serverTime = data['unixtime'];
        final int localTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        _serverTimeOffset = serverTime - localTime;
        print(
            'CloudinaryService: Time synced. Offset: $_serverTimeOffset seconds');
      }
    } catch (e) {
      print('CloudinaryService: Failed to sync time: $e');
    }
  }

  /// Upload an image file to Cloudinary
  ///
  /// [file] - The image file to upload (XFile works on both web and mobile)
  /// [folder] - Optional folder path in Cloudinary (e.g., 'watches', 'brands', 'banners')
  /// [publicId] - Optional public ID for the image. If not provided, a unique ID will be generated
  /// Returns the secure URL of the uploaded image
  static Future<String> uploadImage(
    dynamic file, {
    String? folder,
    String? publicId,
  }) async {
    if (_cloudName == null || _apiKey == null || _apiSecret == null) {
      throw Exception('Cloudinary credentials not configured.');
    }

    try {
      Uint8List fileBytes;
      String fileName;

      // Handle both XFile (web and mobile) and File (mobile only)
      if (file is XFile) {
        // XFile works on both web and mobile
        fileBytes = await file.readAsBytes();
        fileName = path.basename(file.path);
      } else if (!kIsWeb) {
        // On mobile, we might receive a File object
        final filePath = (file as dynamic).path as String;
        fileBytes = await (file as dynamic).readAsBytes() as Uint8List;
        fileName = path.basename(filePath);
      } else {
        throw Exception('Invalid file type for web platform. Use XFile.');
      }

      // Verify file is not empty
      if (fileBytes.isEmpty) {
        throw Exception('File is empty');
      }

      // Retry loop for handling stale requests
      int attempts = 0;
      while (attempts < 2) {
        final timestamp = _getTimestamp();

        // Build public_id
        String finalPublicId;
        if (publicId != null) {
          finalPublicId = publicId;
        } else {
          finalPublicId =
              '${folder ?? 'uploads'}/${timestamp}_${path.basenameWithoutExtension(fileName)}';
        }

        // Create form data
        final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

        // Build parameters for signature
        final signatureParams = <String, String>{
          'timestamp': timestamp,
          'public_id': finalPublicId,
        };

        final signature = _generateSignature(signatureParams);

        request.fields.addAll({
          'api_key': _apiKey!,
          'timestamp': timestamp,
          'public_id': finalPublicId,
          'signature': signature,
        });

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
          ),
        );

        // Send request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          return responseData['secure_url'] as String;
        } else if (response.statusCode == 400 &&
            response.body.contains('Stale request')) {
          if (attempts == 0) {
            print(
                'CloudinaryService: Stale request detected. Syncing time and retrying...');
            await _syncTime();
            attempts++;
            continue;
          }
          throw Exception(
              'Failed to upload image (Stale Request): ${response.statusCode} - ${response.body}');
        } else {
          throw Exception(
              'Failed to upload image: ${response.statusCode} - ${response.body}');
        }
      }
      throw Exception('Failed to upload image after retries');
    } catch (e) {
      throw Exception('Error uploading image to Cloudinary: $e');
    }
  }

  /// Upload multiple images to Cloudinary
  ///
  /// [files] - List of image files to upload (File for mobile, XFile for web)
  /// [folder] - Optional folder path in Cloudinary
  /// Returns a list of secure URLs of the uploaded images
  static Future<List<String>> uploadImages(
    List<dynamic> files, {
    String? folder,
  }) async {
    final urls = <String>[];
    for (var file in files) {
      final url = await uploadImage(file, folder: folder);
      urls.add(url);
    }
    return urls;
  }

  /// Delete an image from Cloudinary using its public ID
  ///
  /// [publicId] - The public ID of the image to delete
  static Future<void> deleteImage(String publicId) async {
    if (_cloudName == null || _apiKey == null || _apiSecret == null) {
      throw Exception('Cloudinary credentials not configured.');
    }

    try {
      final timestamp = _getTimestamp();
      final params = <String, String>{
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': _apiKey!,
      };

      final signature = _generateSignature(params);
      params['signature'] = signature;

      final queryString = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url =
          'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy?$queryString';

      final response = await http.post(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Log error but don't throw - deletion failures shouldn't break the app
      print('Error deleting image from Cloudinary: $e');
    }
  }

  /// Extract public ID from Cloudinary URL
  ///
  /// [url] - The Cloudinary URL
  /// Returns the public ID if found, null otherwise
  /// Cloudinary URLs format: https://res.cloudinary.com/{cloud_name}/{type}/upload/{transformations}/{version}/{public_id}.{format}
  static String? extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the 'upload' segment
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) {
        return null;
      }

      // After 'upload', there might be transformations, then version, then public_id
      // The public_id is typically the last segment before the file extension
      // Or it could be multiple segments (folder structure)

      // Look for version pattern (v followed by numbers)
      int publicIdStartIndex = uploadIndex + 1;
      if (uploadIndex + 1 < pathSegments.length) {
        final nextSegment = pathSegments[uploadIndex + 1];
        // If it's a version (v1234567890), skip it
        if (nextSegment.startsWith('v') &&
            RegExp(r'^v\d+$').hasMatch(nextSegment)) {
          publicIdStartIndex = uploadIndex + 2;
        }
      }

      // Everything from publicIdStartIndex to the end (minus file extension) is the public_id
      if (publicIdStartIndex < pathSegments.length) {
        final publicIdParts = pathSegments.sublist(publicIdStartIndex);
        if (publicIdParts.isNotEmpty) {
          // Remove file extension from the last segment
          final lastPart = publicIdParts.last;
          final nameWithoutExt = path.basenameWithoutExtension(lastPart);
          publicIdParts[publicIdParts.length - 1] = nameWithoutExt;
          return publicIdParts.join('/');
        }
      }

      return null;
    } catch (e) {
      print('Error extracting public ID from URL: $e');
      return null;
    }
  }

  /// Generate signature for Cloudinary API requests
  /// Note: api_key should NOT be included in the signature calculation
  static String _generateSignature(Map<String, String> params) {
    // Remove signature, file, and api_key from params for signing
    final sortedParams = Map.fromEntries(
      params.entries
          .where((e) =>
              e.key != 'file' && e.key != 'signature' && e.key != 'api_key')
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Build string to sign: key1=value1&key2=value2...
    final stringToSign =
        sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    // Append API secret
    final stringToSignWithSecret = '$stringToSign$_apiSecret';

    // Generate SHA-1 hash for Cloudinary signature
    final bytes = utf8.encode(stringToSignWithSecret);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
