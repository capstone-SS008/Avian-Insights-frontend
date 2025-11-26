import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class FileUploadSection extends StatefulWidget {
  const FileUploadSection({super.key});

  @override
  State<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends State<FileUploadSection> {
  String backendUrl = "";
  String result = "Results will appear here after processing.";

  @override
  void initState() {
    super.initState();
    _loadEnv(); // Load backend URL from env.json
  }

  // -------------------- Load ENV File --------------------
  Future<void> _loadEnv() async {
    try {
      final envString = await rootBundle.loadString("assets/env.json");
      final env = jsonDecode(envString);
      backendUrl = env["backend_url"] ?? "";
    } catch (e) {
      setState(() {
        result = "⚠ Error loading env.json: $e";
      });
    }
  }

  // -------------------- Backend Call --------------------
  Future<void> _callBackend() async {
    if (backendUrl.isEmpty) {
      setState(() {
        result =
            "⚠ backend_url is empty. Check assets/env.json and restart the app.";
      });
      return;
    }

    setState(() {
      result = "⏳ Processing... please wait.";
    });

    try {
      final uri = Uri.parse("$backendUrl/predict_test");
      final response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          result = response.body;
        });
      } else {
        setState(() {
          result = "❌ Error ${response.statusCode}: ${response.body}";
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
    final crossAxisCount = width > 900 ? 3 : 2; // Responsive card count

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------- Main Title --------------------
          const Text(
            "Upload for Identification",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // -------------------- Small Upload Cards --------------------
          GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 2, // Makes cards smaller
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              UploadCard(title: "Image Upload", icon: "📸"),
              UploadCard(title: "Single Bird Audio", icon: "🎵"),
              UploadCard(title: "Mixed Audio", icon: "🎼"),
            ],
          ),

          const SizedBox(height: 20),

          // -------------------- Process Button --------------------
          Center(
            child: ElevatedButton(
              onPressed: _callBackend,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                child: Text(
                  "Process & Identify",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // -------------------- Big Result Visualization Box --------------------
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 240),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFFB3E5FC), // LIGHT SKY BLUE RESULT BOX
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              result,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
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

  const UploadCard({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ----------------------------------------------
      // 👉 THIS IS THE CARD COLOR — CHANGE IT HERE
      // ----------------------------------------------
      decoration: BoxDecoration(
      color: Colors.lightGreenAccent,// CARD BG COLOR
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
              onPressed: () {},
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
