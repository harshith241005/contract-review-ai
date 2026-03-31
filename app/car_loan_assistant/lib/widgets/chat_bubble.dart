// Chat Bubble Widget - Premium Redesign

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/negotiation.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final int index;

  const ChatBubble({super.key, required this.message, this.index = 0});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.3 : -0.3, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    if (!widget.message.isAnimated) {
      Future.delayed(Duration(milliseconds: 50 * widget.index), () {
        if (mounted) {
          _animController.forward();
          widget.message.isAnimated = true;
        }
      });
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    setState(() => _copied = true);
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              top: 6,
              bottom: 6,
              left: isUser ? 60 : 0,
              right: isUser ? 0 : 40,
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser) ...[
                      _buildAvatar(),
                      const SizedBox(width: 8),
                    ],
                    Flexible(child: _buildBubble(isUser)),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(
                    left: isUser ? 0 : 44,
                    right: isUser ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(widget.message.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _copyToClipboard,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _copied
                                ? Icon(Icons.check_circle,
                                    key: const ValueKey('check'),
                                    size: 14,
                                    color: AppTheme.successColor)
                                : Icon(Icons.copy_rounded,
                                    key: const ValueKey('copy'),
                                    size: 14,
                                    color: Colors.grey[400]),
                          ),
                        ),
                      ],
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

  Widget _buildAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBubble(bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
        ),
        border: isUser
            ? null
            : Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: _buildMessageContent(isUser),
    );
  }

  Widget _buildMessageContent(bool isUser) {
    final content = widget.message.content;
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];

      if (line.startsWith('**') && line.endsWith('**')) {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: i > 0 ? 8 : 0, bottom: 4),
          child: Text(
            line.replaceAll('**', ''),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isUser ? Colors.white : AppTheme.primaryColor,
              fontSize: 15,
            ),
          ),
        ));
      } else if (line.startsWith('•') ||
          line.startsWith('✅') ||
          line.startsWith('🎯') ||
          line.startsWith('1️⃣') ||
          line.startsWith('2️⃣') ||
          line.startsWith('3️⃣') ||
          line.startsWith('4️⃣') ||
          line.startsWith('5️⃣')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 10, top: 4, bottom: 2),
          child: Text(
            line,
            style: GoogleFonts.poppins(
              color: isUser ? Colors.white.withValues(alpha: 0.95) : AppTheme.textPrimary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ));
      } else if (line.startsWith('---')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUser
                    ? [Colors.white24, Colors.white54, Colors.white24]
                    : [Colors.grey.shade200, Colors.grey.shade400, Colors.grey.shade200],
              ),
            ),
          ),
        ));
      } else if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        // Parse inline bold
        widgets.add(_buildRichLine(line, isUser));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichLine(String line, bool isUser) {
    final baseColor = isUser ? Colors.white.withValues(alpha: 0.95) : AppTheme.textPrimary;
    final boldColor = isUser ? Colors.white : AppTheme.primaryColor;

    // Parse **bold** inline
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, match.start),
          style: GoogleFonts.poppins(color: baseColor, fontSize: 13.5, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.poppins(
          color: boldColor,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          height: 1.5,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: GoogleFonts.poppins(color: baseColor, fontSize: 13.5, height: 1.5),
      ));
    }

    if (spans.isEmpty) {
      return Text(
        line,
        style: GoogleFonts.poppins(color: baseColor, fontSize: 13.5, height: 1.5),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// Animated Typing Indicator
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _dotControllers;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(3, (i) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _dotControllers[i],
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.translate(
                        offset: Offset(0, -4 * _dotControllers[i].value),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                              Colors.grey.shade300,
                              AppTheme.accentColor,
                              _dotControllers[i].value,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
