import 'dart:ui';
import 'package:flutter/material.dart';
import 'components/file_upload.dart';
import 'components/chatbot.dart';
import 'styles/app_theme.dart';

class BirdApp extends StatelessWidget {
  const BirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Avian Insights',
      theme: AppTheme.lightTheme,
      home: const BirdHomePage(),
    );
  }
}

class BirdHomePage extends StatelessWidget {
  const BirdHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: Column(
        children: [
          // 🟣 Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '🦅',
                      style: TextStyle(fontSize: 30),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Avian Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI-Powered Bird Species Classification',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          // 🌤️ Main content grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isMobile
                  ? const _MobileLayout()
                  : const _DesktopLayout(),
            ),
          ),

          // ⚙️ Footer (with blur)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white.withOpacity(0.1),
                child: const Text(
                  "A Capstone Project",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🖥️ Desktop: Upload left, Chatbot right
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: FileUploadSection(),
        ),
        SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: ChatbotSection(),
        ),
      ],
    );
  }
}

// 📱 Mobile: Stack vertically
class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        FileUploadSection(),
        SizedBox(height: 20),
        ChatbotSection(),
      ],
    );
  }
}

