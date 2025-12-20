class ChatMemory {
  String summary = "";

  int summaryAfter = 10;

  List<Map<String, String>> buildMessages(List messages, String systemPrompt) {
    List<Map<String, String>> output = [];


    output.add({
      "role": "system",
      "content": systemPrompt,
    });

    if (summary.isNotEmpty) {
      output.add({
        "role": "system",
        "content": "Вот краткое резюме предыдущего диалога: $summary",
      });
    }

    int start = messages.length > summaryAfter
        ? messages.length - summaryAfter
        : 0;

    for (int i = start; i < messages.length; i++) {
      var msg = messages[i];
      output.add({
        "role": msg.isUser ? "user" : "assistant",
        "content": msg.text,
      });
    }

    return output;
  }

  void updateSummary(List messages) {
    if (messages.length <= summaryAfter) return;

    final buffer = StringBuffer();

    for (int i = 0; i < messages.length - summaryAfter; i++) {
      final msg = messages[i];
      buffer.writeln(
        "${msg.isUser ? 'Пользователь' : 'ИИ'}: ${msg.text}",
      );
    }

    // Сильное мини-резюме
    summary = "Основные детали разговора: ${buffer.toString()}";
  }
}
