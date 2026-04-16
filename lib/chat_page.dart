import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ChatGPTApp());
}

class ChatGPTApp extends StatelessWidget {
  const ChatGPTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  // Hugging Face API için HTTP isteği yapan fonksiyon
  Future<String> fetchHuggingFaceResponse(String userMessage) async {
    const apiUrl =
        "api url"; // Model endpoint //https://api-inference.huggingface.co/models/gpt2
    const apiKey = "your api key";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "inputs": userMessage,
        "parameters": {
          "max_length": 30, // Yanıtın maksimum uzunluğu
          "temperature": 0.3, // Çeşitlilik ve tutarlılık dengesi
          "top_k": 20, // Daha spesifik yanıtlar için
          "top_p": 0.9 // Daha doğal bir yanıt için
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return data[0]['generated_text']; // Yanıtı döndürüyoruz
      } else {
        return "Model yanıt vermedi.";
      }
    } else {
      throw Exception(
          "Hugging Face API yanıt vermedi: ${response.statusCode} - ${response.body}");
    }
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final userMessage = _controller.text;
      setState(() {
        _messages.add({"user": userMessage});
      });
      _controller.clear();

      try {
        final botResponse = await fetchHuggingFaceResponse(userMessage);
        setState(() {
          _messages.add({"bot": botResponse});
        });
      } catch (error) {
        setState(() {
          _messages.add({"bot": "Bir hata oluştu: $error"});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text("PatiHealth Chat"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.containsKey("user");

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepPurple[200] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUser ? message["user"]! : message["bot"]!,
                      style: TextStyle(
                        fontSize: 16,
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Hello,Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}



/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(ChatGPTApp());
}

class ChatGPTApp extends StatelessWidget {
  const ChatGPTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  // Google Gemini API için HTTP isteği yapan fonksiyon
  Future<String> fetchAIResponse(String userMessage) async {
    final apiUrl =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-001:generateContent"; // Google Gemini API URL'si
    final apiKey =
        "AIzaSyDDxZ7Neubkxr8fJ_E5Du67wM7ZAD9Hi2U"; // Buraya API anahtarını ekleyin.

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "input": userMessage, // Kullanıcı mesajını API'ye gönderiyoruz.
        "model":
            "gemini-001", // Gemini model adı (dokümantasyondan kontrol edin)
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[
          'output']; // Yanıtı döndürüyoruz (dokümantasyona göre düzenle).
    } else {
      throw Exception("Google Gemini API yanıt vermedi: ${response.body}");
    }
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final userMessage = _controller.text;
      setState(() {
        _messages.add({"user": userMessage});
      });
      _controller.clear();

      try {
        final botResponse = await fetchAIResponse(userMessage);
        setState(() {
          _messages.add({"bot": botResponse});
        });
      } catch (error) {
        setState(() {
          _messages.add({"bot": "Bir hata oluştu: $error"});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Google Gemini Chat"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.containsKey("user");

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepPurple[200] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUser ? message["user"]! : message["bot"]!,
                      style: TextStyle(
                        fontSize: 16,
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}*/
