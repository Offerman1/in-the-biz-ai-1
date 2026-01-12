import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ai_agent_service.dart';
import '../services/ai_actions_service.dart';
import '../services/database_service.dart';
import '../services/vision_scanner_service.dart';
import '../theme/app_theme.dart';
import '../providers/shift_provider.dart';
import '../widgets/animated_logo.dart';
import '../widgets/scan_type_menu.dart';
import '../models/vision_scan.dart';
import 'document_scanner_screen.dart';
import 'scan_verification_screen.dart';
import 'package:intl/intl.dart';

class AssistantScreen extends StatefulWidget {
  /// Optional initial message to send automatically when screen opens
  final String? initialMessage;

  const AssistantScreen({super.key, this.initialMessage});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _loadingMessage = '';
  final ScrollController _scrollController = ScrollController();
  final AIActionsService _aiActions = AIActionsService();
  final DatabaseService _db = DatabaseService();
  final VisionScannerService _visionScanner = VisionScannerService();
  String _userContext = '';

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _loadChatHistory().then((_) {
      // If there's an initial message, send it after chat loads
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _messageController.text = widget.initialMessage!;
            _sendMessage();
          }
        });
      }
    });
  }

  Future<void> _loadUserContext() async {
    try {
      _userContext = await _aiActions.buildContextForAI();
    } catch (e) {
      // Context loading failed, will work without it
      _userContext = '';
    }
  }

  /// Load chat history from Supabase
  Future<void> _loadChatHistory() async {
    try {
      final messages = await _db.getChatMessages();

      if (messages.isEmpty) {
        // First time user - show welcome message
        setState(() {
          _messages.add(ChatMessage(
            text:
                "Hey! I'm ITB, your AI assistant. Ask me about your income, goals, or send me a photo to scan! 📷💰",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        await _saveChatMessage(
          "Hey! I'm ITB, your AI assistant. Ask me about your income, goals, or send me a photo to scan! 📷💰",
          false,
        );
      } else {
        // Load existing chat history
        setState(() {
          _messages.addAll(messages.map((msg) => ChatMessage(
                text: msg['message'] as String,
                isUser: msg['is_user'] as bool,
                timestamp: DateTime.parse(msg['created_at'] as String),
              )));
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      // Show welcome message on error
      setState(() {
        _messages.add(ChatMessage(
          text:
              "Hey! I'm ITB, your AI assistant. Ask me about your income, goals, or send me a photo to scan! 📷💰",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  /// Save a single chat message to Supabase
  Future<void> _saveChatMessage(String message, bool isUser) async {
    try {
      await _db.saveChatMessage(message, isUser);
    } catch (e) {
      debugPrint('Error saving chat message: $e');
    }
  }

  /// Clear all chat history
  Future<void> _clearChatHistory() async {
    try {
      await _db.clearChatHistory();
      setState(() {
        _messages.clear();
        _messages.add(ChatMessage(
          text:
              "Hey! I'm ITB, your AI assistant. Ask me about your income, goals, or send me a photo to scan! 📷💰",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      await _saveChatMessage(
        "Hey! I'm ITB, your AI assistant. Ask me about your income, goals, or send me a photo to scan! 📷💰",
        false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat history cleared')),
        );
      }
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing chat: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _loadingMessage = 'Thinking...';
    });
    _messageController.clear();
    _scrollToBottom();

    // Save user message to database
    await _saveChatMessage(message, true);

    try {
      // Use new AI Agent service with function calling
      final aiAgent = AIAgentService();

      // Convert messages to history format
      final history = _messages
          .map((msg) => {
                'text': msg.text,
                'isUser': msg.isUser,
                'timestamp': msg.timestamp.toIso8601String(),
              })
          .toList();

      final response = await aiAgent.sendMessage(
        message,
        history,
        userContext: _userContext,
      );

      if (response['success'] == true) {
        final functionsExecuted = response['functionsExecuted'] ?? 0;
        String replyText = response['reply'] ?? 'No response';

        // Update loading message based on what's happening
        if (functionsExecuted > 0) {
          setState(() {
            _loadingMessage = 'Executing actions...';
          });
          replyText = '✨ $replyText'; // Sparkle indicates action was taken
        }

        debugPrint('[AI Agent] Reply: $replyText');

        setState(() {
          _messages.add(ChatMessage(
            text: replyText,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
          _loadingMessage = '';
        });

        // Save AI response to database
        await _saveChatMessage(replyText, false);

        // Refresh data if functions were executed (silently)
        if (functionsExecuted > 0 && mounted) {
          final shiftProvider =
              Provider.of<ShiftProvider>(context, listen: false);
          await shiftProvider.loadShifts();
        }
      } else {
        throw Exception(response['error'] ?? 'Unknown error');
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I couldn't process that. Please try again. Error: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
        _loadingMessage = '';
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================================
  // UNIFIED AI VISION SCANNER SYSTEM (Same as Add Shift Screen)
  // ============================================================================

  /// Show the scan type menu (same menu as Add Shift screen)
  void _showScanMenu() {
    showScanTypeMenu(context, _handleScanTypeSelected);
  }

  /// Handle scan type selection - navigate to document scanner
  void _handleScanTypeSelected(ScanType scanType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentScannerScreen(
          scanType: scanType,
          onScanComplete: _handleScanComplete,
        ),
      ),
    );
  }

  /// Handle completed scan session - process images with AI
  Future<void> _handleScanComplete(DocumentScanSession session) async {
    if (!mounted) return;

    // Add message to chat showing scan is processing
    setState(() {
      _messages.add(ChatMessage(
        text: "📷 Scanning ${session.scanType.displayName}...",
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _loadingMessage =
          'Processing ${session.pageCount} page${session.pageCount == 1 ? '' : 's'} with AI...';
    });
    _scrollToBottom();

    try {
      final userId = _db.supabase.auth.currentUser!.id;
      Map<String, dynamic> result;

      // Route to appropriate handler based on scan type
      switch (session.scanType) {
        case ScanType.beo:
          if (kIsWeb && session.hasBytes) {
            result = await _visionScanner.analyzeBEOFromBytes(
                session.imageBytes!, userId,
                mimeTypes: session.mimeTypes);
          } else {
            result =
                await _visionScanner.analyzeBEO(session.imagePaths, userId);
          }
          break;
        case ScanType.checkout:
          if (kIsWeb && session.hasBytes) {
            result = await _visionScanner.analyzeCheckoutFromBytes(
                session.imageBytes!, userId,
                mimeTypes: session.mimeTypes);
          } else {
            result = await _visionScanner.analyzeCheckout(
                session.imagePaths, userId);
          }
          break;
        case ScanType.businessCard:
          if (kIsWeb && session.hasBytes) {
            result = await _visionScanner.scanBusinessCardFromBytes(
                session.imageBytes!, userId,
                mimeTypes: session.mimeTypes);
          } else {
            result = await _visionScanner.scanBusinessCard(
                session.imagePaths, userId);
          }
          break;
        case ScanType.paycheck:
          if (kIsWeb && session.hasBytes) {
            result = await _visionScanner.analyzePaycheckFromBytes(
                session.imageBytes!, userId,
                mimeTypes: session.mimeTypes);
          } else {
            result = await _visionScanner.analyzePaycheck(
                session.imagePaths, userId);
          }
          break;
        case ScanType.invoice:
          if (kIsWeb && session.hasBytes) {
            result = await _visionScanner.analyzeInvoiceFromBytes(
                session.imageBytes!, userId,
                mimeTypes: session.mimeTypes);
          } else {
            result =
                await _visionScanner.analyzeInvoice(session.imagePaths, userId);
          }
          break;
        case ScanType.receipt:
          if (kIsWeb && session.hasBytes) {
            result = await _visionScanner.analyzeReceiptFromBytes(
                session.imageBytes!, userId,
                mimeTypes: session.mimeTypes);
          } else {
            result =
                await _visionScanner.analyzeReceipt(session.imagePaths, userId);
          }
          break;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });

      // Navigate to verification screen
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanVerificationScreen(
            scanType: session.scanType,
            extractedData: result['data'] as Map<String, dynamic>,
            confidenceScores:
                result['data']['ai_confidence_scores'] as Map<String, dynamic>?,
            onConfirm: (data) async {
              // Show success message in chat
              Navigator.pop(context, true);
            },
          ),
        ),
      );

      if (confirmed == true && mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                "✅ ${session.scanType.displayName} scanned successfully! The data has been saved.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        await _saveChatMessage(
          "✅ ${session.scanType.displayName} scanned successfully! The data has been saved.",
          false,
        );

        // Refresh shifts
        final shiftProvider =
            Provider.of<ShiftProvider>(context, listen: false);
        await shiftProvider.loadShifts();
      } else if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Scan cancelled. You can try again anytime!",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                "❌ Scan failed: ${e.toString()}\n\nPlease try again with a clearer photo.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
          _loadingMessage = '';
        });
      }
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we can pop (i.e., if this screen was navigated to, not shown as a tab)
    final canPop = Navigator.canPop(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor:
              AppTheme.cardBackground, // Solid color to match input area
          elevation: 0, // Remove shadow for cleaner look
          scrolledUnderElevation:
              0, // Prevent color change on scroll (Material 3)
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent, // Prevent Material 3 tint
          toolbarHeight: 70, // Slightly taller for stacked text
          // Only show back button if we can actually pop (not when shown as a tab)
          leading: canPop
              ? IconButton(
                  icon:
                      Icon(Icons.arrow_back, color: AppTheme.adaptiveTextColor),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          automaticallyImplyLeading: false, // Don't show default back button
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use the exact same AnimatedLogo from dashboard
              AnimatedLogo(isTablet: false),
              const SizedBox(height: 2),
              // "Personal Assistant" badge (like "TIPS AND INCOME TRACKER")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.textPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.accentBlue,
                      AppTheme.primaryGreen,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    _isLoading ? 'TYPING...' : 'PERSONAL ASSISTANT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppTheme.cardBackground,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: AppTheme.accentRed),
                          title: Text('Clear Chat',
                              style: TextStyle(
                                color: AppTheme.adaptiveTextColor,
                              )),
                          onTap: () async {
                            Navigator.pop(context);
                            await _clearChatHistory();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                        if (_loadingMessage.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            _loadingMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Scan button - same as Add Shift screen
                    GestureDetector(
                      onTap: _showScanMenu,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.greenGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppTheme.primaryGreen.computeLuminance() > 0.5
                              ? Colors.black87
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackgroundLight.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: AppTheme.bodyLarge,
                          maxLines: null,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Ask me about earnings, goals, shifts...',
                            hintStyle: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isLoading ? null : _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: _isLoading ? null : AppTheme.greenGradient,
                          color: _isLoading
                              ? AppTheme.cardBackgroundLight.withOpacity(0.9)
                              : null,
                          shape: BoxShape.circle,
                          boxShadow: _isLoading
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.send,
                          color: _isLoading
                              ? AppTheme.textMuted
                              : (AppTheme.primaryGreen.computeLuminance() > 0.5
                                  ? Colors.black87
                                  : Colors.white),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.textMuted.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              // Copy message to clipboard
              Clipboard.setData(ClipboardData(text: message.text));

              // Show snackbar confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Message copied to clipboard'),
                  duration: const Duration(milliseconds: 1500),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryGreen
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? (AppTheme.primaryGreen.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white)
                      : AppTheme.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              timeFormat.format(message.timestamp),
              style: AppTheme.labelSmall.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });
}
