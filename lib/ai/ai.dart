import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://api-mlc.onrender.com/api/chat";

  Future<String> sendMessage(List<Map<String, String>> history) async {
  try {
    print("SEND TO SERVER:");
    print(history);

    final response = await http
        .post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "model": "gpt-4o-mini",
            "messages": history,
          }),
        )
        .timeout(const Duration(seconds: 40));

    print("STATUS: ${response.statusCode}");
    print(" BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"]?[0]?["message"]?["content"] ??
          "Пустой ответ";
    } else {
      return "Ошибка сервера ${response.statusCode}";
    }
  } catch (e) {
    print("ERROR: $e");
    return "Ошибка соединения";
  }
}

}