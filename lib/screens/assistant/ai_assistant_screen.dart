import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:uniclubs/services/ai_service.dart';



class AiAssistantScreen extends StatefulWidget{
  final ChatUser currentUser;
  const AiAssistantScreen({super.key, required this.currentUser});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  List<ChatMessage> messages = [];

  ChatUser get currentUser => widget.currentUser;
  ChatUser geminiUser = ChatUser(id: "0", firstName: "AI Assistant",);
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
        title: Text("UniClub Assistant",
          style: TextStyle(fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3674B5)),),
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
                  color: const Color(0xFF578FCA).withValues(alpha: 0.1),
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
    return DashChat(
      messageOptions: MessageOptions(
        currentUserContainerColor: Color(0xFF3674B5),
        currentUserTextColor: Colors.white,
        containerColor: Colors.white,
        textColor: Color(0xFF3674B5),
        avatarBuilder: _aIavatar,),
      inputOptions: InputOptions(alwaysShowSend: true,
          cursorStyle: CursorStyle(color: Color(0xFF578FCA))),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      scrollToBottomOptions: ScrollToBottomOptions(
        onScrollToBottomPress: () {},),);
  }

  Widget _aIavatar(ChatUser user, Function? onAvatarTap,
      Function? onAvatarLongPress) {
    return Center(child: Image.asset(
      "assets/img.png", height: 50, width: 50,));
  }


  Future<void> _loadMessages() async {
    try {
      final loadedMessages = await AiService.getMessages(currentUser.id);

      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading messages: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    ChatMessage typing = ChatMessage(
        text: "Typing...",
        user: geminiUser,
        createdAt: DateTime.now());
    setState(() {
      messages = [typing, ...messages];
    });

    try {
      final responseText = await AiService.sendMessage(
        chatMessage.text, currentUser.id,);

      setState(() {
        messages.removeWhere((m) => m.text == "Typing...");

        messages = [
          ChatMessage(
            text: responseText,
            user: geminiUser,
            createdAt: DateTime.now(),),
          ...messages
        ];
      });
    } catch (e) {
      setState(() {
        messages.removeWhere((m) => m.text == "Typing...");

        messages = [
          ChatMessage(
            text: "something went wrong",
            user: geminiUser,
            createdAt: DateTime.now(),),
          ...messages
        ];
      });
      }

    }
  }










