import 'package:flutter/material.dart';
import '../ai/ai.dart';
import '../ai/memory.dart';
import '../theme/retro_colors.dart';

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
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: RetroColors.paper,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: RetroColors.cocoa.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu,
              color: RetroColors.mustard,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              "Составляю рецепт",
              style: TextStyle(
                fontSize: 16,
                color: RetroColors.cocoa,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
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
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? RetroColors.cherryRed : RetroColors.paper,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: isUser ? Radius.circular(20) : Radius.circular(4),
            bottomRight: isUser ? Radius.circular(4) : Radius.circular(20),
          ),
          border: Border.all(
            color: isUser
                ? RetroColors.cherryRed.withOpacity(0.5)
                : RetroColors.cocoa.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              Icon(
                Icons.restaurant_menu,
                color: RetroColors.mustard,
                size: 20,
              ),
            if (!isUser) SizedBox(width: 8),
            Expanded(
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : RetroColors.cocoa,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                  height: 1.4,
                ),
              ),
            ),
            if (isUser)
              SizedBox(width: 8),
            if (isUser)
              Icon(
                Icons.person,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Чат с вашим говорящим Поварёнком",
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: RetroColors.cherryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              RetroColors.paper.withOpacity(0.1),
              RetroColors.paper,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.only(bottom: 8),
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
              decoration: BoxDecoration(
                color: RetroColors.paper,
                border: Border(
                  top: BorderSide(
                    color: RetroColors.cocoa.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: RetroColors.cocoa.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: controller,
                        enabled: !isTyping,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: "Напишите вопрос о рецепте...",
                          hintStyle: TextStyle(
                            color: RetroColors.cocoa.withOpacity(0.5),
                            fontFamily: 'Roboto',
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          color: RetroColors.cocoa,
                          fontFamily: 'Roboto',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RetroColors.mustard,
                      border: Border.all(
                        color: RetroColors.cocoa.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: isTyping ? null : sendMessage,
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        return Text(
          "." * dots,
          style: TextStyle(
            fontSize: 20,
            color: RetroColors.mustard,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}