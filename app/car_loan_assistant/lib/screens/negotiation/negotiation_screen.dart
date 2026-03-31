// Negotiation Assistant Screen - Premium Redesign

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/contract_provider.dart';
import '../../providers/negotiation_provider.dart';
import '../../models/negotiation.dart';
import '../../widgets/chat_bubble.dart';

class NegotiationScreen extends StatefulWidget {
  const NegotiationScreen({super.key});

  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  late AnimationController _fabAnimController;
  late AnimationController _pageAnimController;
  late Animation<double> _pageAnim;
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pageAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageAnim = CurvedAnimation(
      parent: _pageAnimController,
      curve: Curves.easeOutCubic,
    );
    _pageAnimController.forward();

    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _showSendButton) {
        setState(() => _showSendButton = hasText);
        if (hasText) {
          _fabAnimController.forward();
        } else {
          _fabAnimController.reverse();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contractProvider = context.read<ContractProvider>();
      context
          .read<NegotiationProvider>()
          .initialize(contractProvider.currentContract);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _fabAnimController.dispose();
    _pageAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: AppTheme.accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Negotiation Assistant',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Consumer<NegotiationProvider>(
                builder: (context, provider, child) {
                  return IconButton(
                    icon: Icon(Icons.refresh_rounded, color: Colors.grey[600]),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      provider.clearChat();
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 20), text: 'Chat'),
                Tab(icon: Icon(Icons.lightbulb_outline_rounded, size: 20), text: 'Tips'),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FadeTransition(
            opacity: _pageAnim,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(),
                _buildTipsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Consumer<NegotiationProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildQuickActions(provider),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount:
                    provider.messages.length + (provider.isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.messages.length && provider.isTyping) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: TypingIndicator(),
                    );
                  }
                  return ChatBubble(
                    message: provider.messages[index],
                    index: index,
                  );
                },
              ),
            ),
            _buildInputArea(provider),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(NegotiationProvider provider) {
    final actions = [
      (
        '📊 Interest Tips',
        'Tell me about negotiating interest rates',
        const Color(0xFF3B82F6),
        const Color(0xFF1D4ED8),
      ),
      (
        '✉️ Draft Email',
        'Write an email to the dealer',
        const Color(0xFF8B5CF6),
        const Color(0xFF6D28D9),
      ),
      (
        '❓ Questions',
        'What questions should I ask?',
        const Color(0xFF06B6D4),
        const Color(0xFF0891B2),
      ),
      (
        '💪 Negotiate',
        'Give me negotiation tips',
        const Color(0xFFF59E0B),
        const Color(0xFFD97706),
      ),
      (
        '💵 Down Pay',
        'Tell me about down payment strategy',
        const Color(0xFF10B981),
        const Color(0xFF059669),
      ),
      (
        '🔄 Refinance',
        'Tell me about refinancing my auto loan',
        const Color(0xFFEC4899),
        const Color(0xFFDB2777),
      ),
      (
        '🛡️ Warranty',
        'Tell me about extended warranty',
        const Color(0xFF6366F1),
        const Color(0xFF4F46E5),
      ),
    ];

    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _QuickActionChip(
            label: actions[index].$1,
            color1: actions[index].$3,
            color2: actions[index].$4,
            onTap: () {
              provider.trackQuickAction(actions[index].$1);
              _sendQuickMessage(actions[index].$2);
            },
          );
        },
      ),
    );
  }

  Widget _buildInputArea(NegotiationProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: IconButton(
                icon: Icon(Icons.add_circle_outline_rounded, color: Colors.grey[600], size: 28),
                onPressed: () { HapticFeedback.lightImpact(); },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _showSendButton
                        ? AppTheme.accentColor.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask about your contract...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(23),
                    onTap: _showSendButton ? _sendMessage : () { HapticFeedback.selectionClick(); },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _showSendButton
                              ? [AppTheme.primaryColor, AppTheme.primaryLight]
                              : [Colors.grey.shade300, Colors.grey.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: _showSendButton
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        _showSendButton ? Icons.send_rounded : Icons.mic_none_rounded,
                        color: _showSendButton ? Colors.white : Colors.grey[700],
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsTab() {
    return Consumer<NegotiationProvider>(
      builder: (context, provider, child) {
        if (provider.negotiationPoints.isEmpty) {
          return _buildEmptyTips();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.negotiationPoints.length,
          itemBuilder: (context, index) {
            return _TipCard(
              point: provider.negotiationPoints[index],
              index: index,
              onAskAbout: (description) {
                _tabController.animateTo(0);
                Future.delayed(const Duration(milliseconds: 300), () {
                  _sendQuickMessage(
                      'Tell me more about: $description');
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyTips() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withValues(alpha: 0.15),
                    AppTheme.primaryColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_rounded,
                size: 48,
                color: AppTheme.accentColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Personalized Tips Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a contract to get AI-powered\nnegotiation tips tailored to your deal',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  'Upload Contract',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    context.read<NegotiationProvider>().sendMessage(text);
    _messageController.clear();

    _scrollToBottom();
  }

  void _sendQuickMessage(String message) {
    HapticFeedback.selectionClick();
    context.read<NegotiationProvider>().sendMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
    // Second scroll after AI responds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
}

// Quick Action Chip Widget
class _QuickActionChip extends StatefulWidget {
  final String label;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.color1,
    required this.color2,
    required this.onTap,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) {
        _scaleController.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.forward(),
      child: ScaleTransition(
        scale: _scaleController,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color1.withValues(alpha: 0.1),
            border: Border.all(color: widget.color1.withValues(alpha: 0.25), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              color: widget.color2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Tip Card Widget
class _TipCard extends StatefulWidget {
  final NegotiationPoint point;
  final int index;
  final Function(String) onAskAbout;

  const _TipCard({
    required this.point,
    required this.index,
    required this.onAskAbout,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _expanded = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _priorityColor {
    switch (widget.point.priority) {
      case NegotiationPriority.high:
        return const Color(0xFFEF4444);
      case NegotiationPriority.medium:
        return const Color(0xFFF59E0B);
      case NegotiationPriority.low:
        return const Color(0xFF10B981);
    }
  }

  IconData get _priorityIcon {
    switch (widget.point.priority) {
      case NegotiationPriority.high:
        return Icons.warning_rounded;
      case NegotiationPriority.medium:
        return Icons.info_rounded;
      case NegotiationPriority.low:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_priorityIcon,
                            color: _priorityColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.point.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.point.description,
                              maxLines: _expanded ? 10 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.point.priority.name.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: _priorityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Suggested Action (expandable)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedContent(),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.point.suggestedAction != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                    AppTheme.accentColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 18,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.point.suggestedAction!,
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Action buttons
          Row(
            children: [
              _buildActionButton(
                icon: _copied
                    ? Icons.check_circle_rounded
                    : Icons.copy_rounded,
                label: _copied ? 'Copied!' : 'Copy',
                color: _copied ? AppTheme.successColor : Colors.grey[600]!,
                onTap: () {
                  Clipboard.setData(ClipboardData(
                    text:
                        '${widget.point.title}\n${widget.point.description}\n${widget.point.suggestedAction ?? ''}',
                  ));
                  setState(() => _copied = true);
                  HapticFeedback.lightImpact();
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copied = false);
                  });
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Ask About This',
                color: AppTheme.primaryColor,
                onTap: () =>
                    widget.onAskAbout(widget.point.title),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
