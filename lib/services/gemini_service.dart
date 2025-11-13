import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  // API Key and model are defined as compile-time constants to work with --dart-define on web.
  static const String _apiKey = 'AIzaSyCfVJSZsau4g4lnBIeIE88V3kPp90QJWXE';
  static const String _model = 'gemini-pro';

  /// Mengirim pesan ke Gemini API dengan menyertakan riwayat percakapan.
  ///
  /// [history] adalah daftar pesan sebelumnya dalam percakapan.
  /// Setiap pesan dalam riwayat adalah Map yang harus berisi 'role' ('user' atau 'model') dan 'parts'.
  /// [newMessage] adalah pesan baru yang dikirim oleh pengguna.
  Future<String> sendChatMessage(
    List<Map<String, dynamic>> history,
    String newMessage,
  ) async {
    // Endpoint API 'v1beta' untuk model 'gemini-1.5-flash-latest'.
    final String url =
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey';

    // Membuat 'contents' baru dengan menggabungkan riwayat dan pesan baru.
    final List<Map<String, dynamic>> newContents = List.from(history);
    newContents.add({
      'role': 'user',
      'parts': [
        {'text': newMessage},
      ],
    });

    final Map<String, dynamic> requestBody = {
      'contents': newContents,
      'generationConfig': {
        // Explicitly disable citation mode to prevent errors with models that don't support it.
        'citationMode': 'DISABLED',
      },
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Parsing JSON yang aman untuk mendapatkan teks yang dihasilkan dari kandidat.
        if (data.containsKey('candidates') &&
            data['candidates'] is List &&
            data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate.containsKey('content') &&
              candidate['content'].containsKey('parts') &&
              candidate['content']['parts'] is List &&
              candidate['content']['parts'].isNotEmpty) {
            return candidate['content']['parts'][0]['text'];
          }
        }
        // Jika struktur respons tidak seperti yang diharapkan.
        throw Exception(
          'Failed to parse generated content from response. Body: ${response.body}',
        );
      } else {
        // Memberikan pesan error yang lebih detail dari server.
        throw Exception(
          'Failed to load content: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      // Menangkap error jaringan atau lainnya.
      throw Exception('Error sending chat message: $e');
    }
  }
}
