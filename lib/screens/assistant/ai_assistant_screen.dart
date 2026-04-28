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
  // V1 Logic: Proper typing indicator list
  List<ChatUser> typingUsers = [];
  bool isLoading = true;

  ChatUser get currentUser => widget.currentUser;
  final ChatUser _geminiUser = ChatUser(id: '0', firstName: 'UniClubs AI');

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final loaded = await AiService.getMessages(currentUser.id);
      if (mounted) {
        setState(() {
          messages = loaded;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _sendMessage(ChatMessage msg) async {
    setState(() {
      messages = [msg, ...messages];
      // V1 Logic: Add AI to typing users for native animation
      typingUsers.add(_geminiUser);
    });

    try {
      final reply = await AiService.sendMessage(msg.text, currentUser.id);
      if (mounted) {
        setState(() {
          // Remove typing indicator and add response
          typingUsers.remove(_geminiUser);
          messages = [
            ChatMessage(text: reply, user: _geminiUser, createdAt: DateTime.now()),
            ...messages,
          ];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // Remove typing indicator and add error message
          typingUsers.remove(_geminiUser);
          messages = [
            ChatMessage(
              text: 'Something went wrong. Please try again.',
              user: _geminiUser,
              createdAt: DateTime.now(),
            ),
            ...messages,
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: _buildAppBar(context),
      body: isLoading ? _buildLoader() : _buildChat(),
    );
  }

  // V2 UI: Beautiful Gradient AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x333674B5),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                // Bot avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                // Name + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'UniClubs AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF69F0AE),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Online — here to help',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF3674B5),
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildChat() {
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      typingUsers: typingUsers, // V1 Logic: Enables native DashChat typing animation
      messageOptions: MessageOptions(
        currentUserContainerColor: const Color(0xFF3674B5),
        currentUserTextColor: Colors.white,
        containerColor: Colors.white,
        textColor: const Color(0xFF1A2F4B),
        borderRadius: 18,
        messagePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        showTime: true,
        timeTextColor: const Color(0xFF90A4AE),
        avatarBuilder: (user, onTap, onLongPress) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      inputOptions: InputOptions(
        alwaysShowSend: true,
        sendButtonBuilder: (onSend) => GestureDetector(
          onTap: onSend,
          child: Container(
            margin: const EdgeInsets.only(left: 6, right: 4),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3674B5), Color(0xFF578FCA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3674B5).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
          ),
        ),
        inputDecoration: InputDecoration(
          hintText: 'Ask me anything...',
          hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDEECF8), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF578FCA), width: 1.5),
          ),
        ),
        inputTextStyle: const TextStyle(
          color: Color(0xFF1A2F4B),
          fontSize: 14,
        ),
        cursorStyle: const CursorStyle(color: Color(0xFF578FCA)),
        inputToolbarPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        inputToolbarStyle: const BoxDecoration(
          color: Color(0xFFF0F9FF),
          border: Border(
            top: BorderSide(color: Color(0xFFDEECF8), width: 1),
          ),
        ),
      ),
      scrollToBottomOptions: ScrollToBottomOptions(
        scrollToBottomBuilder: (scrollController) => Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 12),
            child: GestureDetector(
              onTap: () => scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3674B5),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3674B5).withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}