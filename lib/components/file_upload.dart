import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import 'bird_prediction_store.dart'; // shared context for chatbot

class FileUploadSection extends StatefulWidget {
  const FileUploadSection({super.key});

  @override
  State<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends State<FileUploadSection> {
  String backendUrl = "";
  String result = "Results will appear here after processing.";

  // For showing uploaded image preview
  Uint8List? _uploadedImageBytes;
  String? _uploadedImageName;

  @override
  void initState() {
    super.initState();
    _loadEnv();
  }

  // -------------------- Load ENV File --------------------
  Future<void> _loadEnv() async {
    try {
      final envString = await rootBundle.loadString("assets/env.json");
      final env = jsonDecode(envString);
      setState(() {
        backendUrl = env["backend_url"] ?? "";
      });
    } catch (e) {
      setState(() {
        result = "⚠ Error loading env.json: $e";
      });
    }
  }

  // -------------------- Pretty formatting for backend JSON --------------------
  String _prettyBirdName(String raw) {
    // "Pavo_cristatus" -> "Pavo cristatus"
    return raw.replaceAll('_', ' ');
  }

  String _formatResult(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);

      // Expecting { "prediction": ... }
      if (decoded is Map && decoded.containsKey("prediction")) {
        final pred = decoded["prediction"];

        // Case 1 & 2: single prediction string
        if (pred is String) {
          return "Predicted Bird:\n• ${_prettyBirdName(pred)}";
        }

        // Case 3: list of separated sources
        if (pred is List) {
          final buffer = StringBuffer();
          buffer.writeln("Separated Sources:");

          for (final item in pred) {
            if (item is Map &&
                item.containsKey("source") &&
                item.containsKey("predicted_bird")) {
              final source = item["source"];
              final birdRaw = item["predicted_bird"] ?? "";
              buffer.writeln(
                  "• Source $source → ${_prettyBirdName(birdRaw.toString())}");
            }
          }

          final text = buffer.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }

      // Fallback: pretty JSON
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      // If parsing fails, just show raw text
      return jsonStr;
    }
  }

  /// Extract bird label from backend JSON and update global store
  void _updateBirdContext(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map && decoded.containsKey("prediction")) {
        final pred = decoded["prediction"];

        // Simple prediction: { "prediction": "Pavo_cristatus" }
        if (pred is String) {
          BirdPredictionStore.instance.lastBirdId = pred;
          return;
        }

        // Separation: { "prediction": [ { "source": 1, "predicted_bird": "..." }, ... ] }
        if (pred is List && pred.isNotEmpty) {
          final first = pred.first;
          if (first is Map && first["predicted_bird"] is String) {
            BirdPredictionStore.instance.lastBirdId =
                first["predicted_bird"] as String;
            return;
          }
        }
      }
    } catch (_) {
      // Ignore parsing errors for context; not critical
    }
  }

  // -------------------- Generic Upload Helper --------------------
  Future<void> _uploadToEndpoint({
    required String endpoint,
    required FileType pickerType,
    List<String>? allowedExtensions,
  }) async {
    if (backendUrl.isEmpty) {
      setState(() {
        result =
            "⚠ backend_url is empty. Check assets/env.json and restart the app.";
      });
      return;
    }

    // Pick file
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: pickerType,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: true, // so we can show image preview
      );
    } catch (e) {
      setState(() {
        result = "⚠ Error opening file picker: $e";
      });
      return;
    }

    if (picked == null) {
      // user cancelled
      return;
    }

    final file = picked.files.single;

    setState(() {
      result = "⏳ Uploading ${file.name} to $endpoint ...";

      // Clear previous image preview unless this is an image upload
      if (endpoint != "/predict_image") {
        _uploadedImageBytes = null;
        _uploadedImageName = null;
      }
    });

    try {
      final uri = Uri.parse("$backendUrl$endpoint");
      final request = http.MultipartRequest("POST", uri);

      // FastAPI expects the field name "file"
      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          "file",
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          "file",
          file.path!,
          filename: file.name,
        ));
      } else {
        setState(() {
          result = "⚠ Could not read selected file.";
        });
        return;
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (!mounted) return;

      if (streamedResponse.statusCode == 200) {
        // 1) Update global bird context (for chatbot)
        _updateBirdContext(responseBody);

        // 2) Update UI
        setState(() {
          result = _formatResult(responseBody);

          // If this was an image upload, store preview
          if (endpoint == "/predict_image" && file.bytes != null) {
            _uploadedImageBytes = file.bytes;
            _uploadedImageName = file.name;
          }
        });
      } else {
        setState(() {
          result =
              "❌ Error ${streamedResponse.statusCode}: $responseBody";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = "⚠ Network error: $e";
      });
    }
  }

  // -------------------- UI BUILD --------------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 3 : 2;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload for Identification",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // -------------------- Upload Cards --------------------
          GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. IMAGE → /predict_image
              UploadCard(
                title: "Image Upload",
                icon: "📸",
                onUpload: () => _uploadToEndpoint(
                  endpoint: "/predict_image",
                  pickerType: FileType.image,
                ),
              ),

              // 2. SINGLE AUDIO → /predict_sound
              UploadCard(
                title: "Single Bird Audio",
                icon: "🎵",
                onUpload: () => _uploadToEndpoint(
                  endpoint: "/predict_sound",
                  pickerType: FileType.audio,
                ),
              ),

              // 3. MIXED AUDIO → /separater
              UploadCard(
                title: "Mixed Audio",
                icon: "🎼",
                onUpload: () => _uploadToEndpoint(
                  endpoint: "/separater",
                  pickerType: FileType.audio,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // -------------------- Combined Result + Image Box --------------------
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 240),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFFB3E5FC),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If there is an uploaded image, show it at the top of the same block
                if (_uploadedImageBytes != null) ...[
                  const Text(
                    "Uploaded Image",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_uploadedImageName != null)
                    Text(
                      _uploadedImageName!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _uploadedImageBytes!,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 12),
                ],

                // Result text (always shown)
                Text(
                  result,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// =================================================================
//                          UPLOAD CARD WIDGET
// =================================================================
//

class UploadCard extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback onUpload;

  const UploadCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.lightGreenAccent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: onUpload,
              child: const Text(
                "Upload",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
