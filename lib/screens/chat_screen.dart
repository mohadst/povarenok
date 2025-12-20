import 'package:flutter/material.dart';
import '../ai/ai.dart';
import '../ai/memory.dart';

class Message {
  final String text;
  final bool isUser;

  Message(this.text, this.isUser);
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool isTyping = false;

  final ApiService api = ApiService();
  final ChatMemory memory = ChatMemory();

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String systemPrompt =
      "Ты умный помощник по готовке. Помни контекст разговора, используй резюме, "
      "Всегда учитывай указания пользователя";

  List<Message> messages = [];

  void scrollDown() {
    Future.delayed(Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }


Widget buildTypingBubble() {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Составляю рецепт",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          AnimatedDots(),   
        ],
      ),
    ),
  );
}


  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

   setState(() {
       messages.add(Message(text, true));
       isTyping = true;   
    });

    controller.clear();
    scrollDown();

    final history = memory.buildMessages(messages, systemPrompt);

    final reply = await api.sendMessage(history);

    setState(() {
      messages.add(Message(reply, false));
      isTyping = false;   
    });

    memory.updateSummary(messages);

    scrollDown();
  }

  Widget buildMessageBubble(Message msg) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 14),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == messages.length) {
                     return buildTypingBubble();
                    }
                return buildMessageBubble(messages[index]);
              },
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isTyping,
                    decoration: InputDecoration(
                      hintText: "Введите сообщение...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: isTyping ? null : sendMessage,
                  iconSize: 28,
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}
class AnimatedDots extends StatefulWidget {
  @override
  _AnimatedDotsState createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        int dots = 1 + (_controller.value * 3).floor();
        return Text("." * dots,
            style: TextStyle(fontSize: 20, color: Colors.black87));
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
