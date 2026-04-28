import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:uniclubs/services/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  final ChatUser currentUser;
  const AiAssistantScreen({super.key, required this.currentUser});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  List<ChatMessage> messages = [];
  List<ChatUser> typingUsers = [];

  ChatUser get currentUser => widget.currentUser;
  ChatUser geminiUser = ChatUser(id: "0", firstName: "AI Assistant");
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "UniClub Assistant",
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3674B5),
          ),
        ),
        backgroundColor: const Color(0xFFE8F4FD),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF578FCA).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFF3674B5)),
          ),
        ),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3674B5)),
      );
    }

    return DashChat(
      messageOptions: MessageOptions(
        currentUserContainerColor: const Color(0xFF3674B5),
        currentUserTextColor: Colors.white,
        containerColor: Colors.white,
        textColor: const Color(0xFF3674B5),
        avatarBuilder: _aIavatar,
      ),
      inputOptions: const InputOptions(
        alwaysShowSend: true,
        cursorStyle: CursorStyle(color: Color(0xFF578FCA)),
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      typingUsers: typingUsers,
      scrollToBottomOptions: ScrollToBottomOptions(
        onScrollToBottomPress: () {},
      ),
    );
  }

  Widget _aIavatar(ChatUser user, Function? onAvatarTap, Function? onAvatarLongPress) {
    return Center(
      child: Image.asset("assets/img.png", height: 50, width: 50),
    );
  }

  Future<void> _loadMessages() async {
    try {
      final loadedMessages = await AiService.getMessages(currentUser.id);

      if (mounted) {
        setState(() {
          messages = loadedMessages;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      messages = [chatMessage, ...messages];
      typingUsers.add(geminiUser);
    });

    try {
      final responseText = await AiService.sendMessage(
        chatMessage.text,
        currentUser.id,
      );

      if (mounted) {
        setState(() {
          typingUsers.remove(geminiUser);

          messages = [
            ChatMessage(
              text: responseText,
              user: geminiUser,
              createdAt: DateTime.now(),
            ),
            ...messages
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          typingUsers.remove(geminiUser);

          messages = [
            ChatMessage(
              text: "Sorry, a connection error occurred. Please try again.",
              user: geminiUser,
              createdAt: DateTime.now(),
            ),
            ...messages
          ];
        });
      }
    }
  }
}