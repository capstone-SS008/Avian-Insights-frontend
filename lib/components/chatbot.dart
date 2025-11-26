import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

//
// ============================================================================
//                               CHATBOT SECTION
// ============================================================================
//

class ChatbotSection extends StatefulWidget {
  const ChatbotSection({super.key});

  @override
  State<ChatbotSection> createState() => _ChatbotSectionState();
}

class _ChatbotSectionState extends State<ChatbotSection> {
  final List<_ChatMessage> _messages = []; // Stores chat history
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  // ⭐ Your Gemini API key here
  static const String _apiKey = "AIzaSyAFg-g-AlKnAWDEST4bCHBySBBXDF3zC0o"; 

  // ========================================================================
  // SEND MESSAGE
  // ========================================================================

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(_ChatMessage(text: text, sender: Sender.user));
      _controller.clear();
      _isSending = true;
    });

    if (_apiKey.isEmpty) {
      setState(() {
        _messages.add(
          _ChatMessage(
            text: "⚠️ No API key provided. Please set your Gemini API key.",
            sender: Sender.bot,
          ),
        );
        _isSending = false;
      });
      return;
    }

    try {
      final botReply = await _getBotReply(text);
      setState(() {
        _messages.add(_ChatMessage(text: botReply, sender: Sender.bot));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: "⚠️ Error: $e", sender: Sender.bot));
      });
    }

    setState(() => _isSending = false);
  }

  // ========================================================================
  // GEMINI API WITH MEMORY
  // ========================================================================

  Future<String> _getBotReply(String userInput) async {
    const endpoint =
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent";

    final headers = {"Content-Type": "application/json"};

    // ---------------------------
    // BUILD CHAT MEMORY
    // ---------------------------
    List<Map<String, dynamic>> conversation = [];

    // Add previous messages
    for (var msg in _messages) {
      conversation.add({
        "role": msg.sender == Sender.user ? "user" : "model",
        "parts": [
          {"text": msg.text}
        ]
      });
    }

    // Add new user message with instructions
    conversation.add({
      "role": "user",
      "parts": [
        {
          "text": """
You are BirdBot — an AI assistant with two modes:

1. Bird Mode:
   If the user asks about birds, reply briefly (max 4 lines).
   Keep the response short and factual.

2. Chat Mode:
   For non-bird questions, reply like a friendly chatbot.

3. Only give detailed bird info if user explicitly asks:
   ("explain more", "full details", "scientific name", etc.)

User: $userInput
"""
        }
      ]
    });

    final body = jsonEncode({
      "contents": conversation,
      "generationConfig": {
        "temperature": 0.6,
        "maxOutputTokens": 180
      }
    });

    try {
      final response = await http.post(
        Uri.parse("$endpoint?key=$_apiKey"),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        return "⚠️ API Error ${response.statusCode}: ${response.body}";
      }

      final data = jsonDecode(response.body);

      // ---------------------------
      // SAFE TEXT EXTRACTION
      // ---------------------------
      final text =
          data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ??
              data["output"] ??
              data["candidates"]?[0]?["output"] ??
              data["result"]?["text"] ??
              "⚠️ No valid text received";

      return text.toString().trim();
    } catch (e) {
      return "⚠️ Network error: $e";
    }
  }

  // ========================================================================
  // UI
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(20),

      child: Column(
        children: [
          const Text(
            "🦜 Bird Assistant (Gemini)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // CHAT LIST
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == Sender.user;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text,
                        style: const TextStyle(fontSize: 15)),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // INPUT BAR
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: "Ask BirdBot something...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

//
// ============================================================================
//                        MESSAGE MODEL
// ============================================================================
//

enum Sender { user, bot }

class _ChatMessage {
  final String text;
  final Sender sender;
  _ChatMessage({required this.text, required this.sender});
}
