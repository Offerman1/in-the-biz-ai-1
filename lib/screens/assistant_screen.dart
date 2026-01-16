import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ai_agent_service.dart';
import '../services/ai_actions_service.dart';
import '../services/database_service.dart';
import '../services/vision_scanner_service.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../providers/shift_provider.dart';
import '../widgets/animated_logo.dart';
import '../widgets/scan_type_menu.dart';
import '../widgets/tour_transition_modal.dart';
import '../models/vision_scan.dart';
import 'document_scanner_screen.dart';
import 'scan_verification_screen.dart';
import 'dashboard_screen.dart';
import 'event_contacts_screen.dart';
import 'event_portfolio_screen.dart';
import 'goals_screen.dart';
import 'server_checkouts_screen.dart';
import 'paychecks_screen.dart';
import 'invoices_receipts_screen.dart';
import 'add_job_screen.dart';
import 'package:intl/intl.dart';

class AssistantScreen extends StatefulWidget {
  /// Optional initial message to send automatically when screen opens
  final String? initialMessage;

  /// Whether this screen is currently visible (for tour triggering)
  final bool isVisible;

  const AssistantScreen(
      {super.key, this.initialMessage, this.isVisible = false});

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

  // Tour state
  bool _isTourShowing = false;
  int _currentTourSlide = 0;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _loadChatHistory().then((_) {
      // No scrolling needed - reversed ListView starts at bottom naturally

      // If there's an initial message, send it after chat loads
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _messageController.text = widget.initialMessage!;
            _sendMessage();
          }
        });
      }

      // Check if tour should start (only if visible from start)
      if (widget.isVisible) {
        _checkAndStartTour();
      }
    });
  }

  @override
  void didUpdateWidget(AssistantScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When this screen becomes visible, check if tour should start
    if (widget.isVisible && !oldWidget.isVisible) {
      debugPrint('🎯 Chat: Became visible, checking tour');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkAndStartTour();
        }
      });
    }
  }

  Future<void> _checkAndStartTour() async {
    if (!mounted) return;

    final tourService = Provider.of<TourService>(context, listen: false);

    debugPrint(
        '🎯 Chat Tour Check: isActive=${tourService.isActive}, currentStep=${tourService.currentStep}, expectedScreen=${tourService.expectedScreen}');

    if (tourService.isActive &&
        tourService.expectedScreen == 'chat' &&
        tourService.currentStep >= 18 &&
        tourService.currentStep <= 23) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isTourShowing) {
        _showChatTour();
      }
    }
  }

  Future<void> _loadUserContext() async {
    try {
      _userContext = await _aiActions.buildContextForAI();
    } catch (e) {
      // Context loading failed, will work without it
      _userContext = '';
    }
  }

  /// Chat tour sample conversations
  static const List<Map<String, dynamic>> _tourSlides = [
    {
      'title': '💬 Add Shifts Naturally',
      'userMessage':
          'Add a shift where I made \$50 cash and \$75 credit tips. I worked 2 PM to 10 PM with Sarah and Billy.',
      'aiMessage':
          'Got it! I\'ve added your shift:\n• Date: Today\n• Hours: 2:00 PM - 10:00 PM (8 hrs)\n• Cash tips: \$50\n• Credit tips: \$75\n• Coworkers: Sarah, Billy\n\nTotal: \$125 in tips! 🎉',
    },
    {
      'title': '✏️ Edit & Update Instantly',
      'userMessage': 'Change the tips I made on the 14th from \$350 to \$250',
      'aiMessage':
          'Updated! Your tips for January 14th are now \$250.\n\nPrevious: \$350\nNew: \$250\nDifference: -\$100',
    },
    {
      'title': '📊 Ask Anything',
      'userMessage': 'How much did I make last Tuesday?',
      'aiMessage':
          'Last Tuesday (Jan 7th) you worked at The Grand Hotel:\n\n• Hours: 4:00 PM - 11:00 PM\n• Cash tips: \$85\n• Credit tips: \$142\n• Hourly: \$52.50\n\nTotal: \$279.50 💰',
    },
    {
      'title': '📈 Analyze Your Earnings',
      'userMessage': 'Compare this month to last month',
      'aiMessage':
          'January vs December:\n\n📈 Tips: \$2,145 vs \$1,890 (+13%)\n📈 Hours: 142 vs 128 (+11%)\n📈 Avg/hour: \$15.10 vs \$14.76\n\nYou\'re on track for your best month yet! 🚀',
    },
    {
      'title': '🔧 Manage Everything',
      'userMessage':
          'Delete my shift from yesterday and show me all shifts with Billy',
      'aiMessage':
          'Done! I\'ve deleted yesterday\'s shift.\n\nShifts with Billy (last 30 days):\n• Jan 12 - The Grand Hotel - \$187\n• Jan 8 - Private Event - \$245\n• Jan 3 - The Grand Hotel - \$156\n\nTotal with Billy: \$588 across 3 shifts',
    },
    {
      'title': '🌟 The Power is Yours!',
      'userMessage': null,
      'aiMessage':
          'I can do SO much more:\n\n• "What\'s my best paying job?"\n• "Export last month to PDF"\n• "Set a goal for \$500/week"\n• "Who did I work with most?"\n• "Scan this receipt" 📷\n• "How many hours this year?"\n\nJust ask - I\'m here 24/7! 🤖💚',
    },
  ];

  void _showChatTour() {
    if (_isTourShowing) return;

    setState(() {
      _isTourShowing = true;
      _currentTourSlide = 0;
    });

    _showTourSlideDialog();
  }

  void _showTourSlideDialog() {
    final tourService = Provider.of<TourService>(context, listen: false);
    final slide = _tourSlides[_currentTourSlide];
    final isLastSlide = _currentTourSlide == _tourSlides.length - 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                slide['title'] as String,
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // User message bubble (if exists)
              if (slide['userMessage'] != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      slide['userMessage'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // AI response bubble
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackgroundLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    slide['aiMessage'] as String,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_tourSlides.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentTourSlide ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentTourSlide
                          ? AppTheme.primaryGreen
                          : AppTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Buttons row
              Row(
                children: [
                  // End Tour button
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isTourShowing = false);
                      tourService.skipAll();
                    },
                    child: Text(
                      'End',
                      style: TextStyle(
                        color: AppTheme.accentRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Skip to Stats (only if not last slide)
                  if (!isLastSlide)
                    TextButton(
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _isTourShowing = false);
                        tourService.setPulsingTarget('stats');
                        tourService.skipToScreen('stats');
                      },
                      child: Text(
                        'Skip →',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Next / Continue button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (isLastSlide) {
                        // Move to Stats
                        setState(() => _isTourShowing = false);
                        tourService.nextStep(); // Step 24 (Stats)
                        tourService.setPulsingTarget('stats');
                        TourTransitionModal.show(
                          context: context,
                          title: 'Check Your Stats!',
                          message:
                              'Tap the Stats button to see your earnings analytics and export options.',
                          onDismiss: () {},
                        );
                      } else {
                        // Next slide
                        setState(() => _currentTourSlide++);
                        tourService.nextStep();
                        _showTourSlideDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isLastSlide ? 'Continue →' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                timestamp:
                    DateTime.parse(msg['created_at'] as String).toLocal(),
              )));
        });
        // Note: Scroll happens in initState's addPostFrameCallback
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
        debugPrint(
            '[AI Agent] Navigation Badges: ${response['navigationBadges']}');
        debugPrint(
            '[AI Agent] Badges null?: ${response['navigationBadges'] == null}');

        setState(() {
          final badges = response['navigationBadges'] != null
              ? List<Map<String, dynamic>>.from(response['navigationBadges'])
              : null;
          debugPrint('[AI Agent] Parsed badges: $badges');

          _messages.add(ChatMessage(
            text: replyText,
            isUser: false,
            timestamp: DateTime.now(),
            navigationBadges: badges,
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
    // No scrolling needed - reversed ListView stays at bottom
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
        if (!mounted) return;
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
              const AnimatedLogo(isTablet: false),
              const SizedBox(height: 2),
              // "Personal Assistant" badge (like "TIPS AND INCOME TRACKER")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.textPrimary.withValues(alpha: 0.1),
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
                    style: const TextStyle(
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
                reverse: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  // Reverse the index since list is reversed
                  final reversedIndex = _messages.length - 1 - index;
                  return _buildMessageBubble(_messages[reversedIndex]);
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
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                          color: AppTheme.cardBackgroundLight
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
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
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
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
                              ? AppTheme.cardBackgroundLight
                                  .withValues(alpha: 0.9)
                              : null,
                          shape: BoxShape.circle,
                          boxShadow: _isLoading
                              ? []
                              : [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.3),
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
            color: AppTheme.textMuted.withValues(alpha: 0.3 + (value * 0.7)),
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
          // Navigation badges (only for AI messages)
          if (!message.isUser &&
              message.navigationBadges != null &&
              message.navigationBadges!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.navigationBadges!.map((badge) {
                  return InkWell(
                    onTap: () => _handleNavigationBadgeTap(badge),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForBadge(badge['icon']),
                            size: 16,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            badge['label'] ?? 'View',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForBadge(String? iconName) {
    switch (iconName) {
      case 'calendar':
        return Icons.calendar_today;
      case 'contacts':
        return Icons.contacts;
      case 'event':
        return Icons.event;
      case 'details':
        return Icons.info_outline;
      case 'receipt':
        return Icons.receipt;
      case 'invoice':
        return Icons.description;
      case 'paycheck':
        return Icons.account_balance_wallet;
      case 'checkout':
        return Icons.point_of_sale;
      case 'goals':
        return Icons.flag;
      case 'jobs':
        return Icons.work;
      default:
        return Icons.arrow_forward;
    }
  }

  void _handleNavigationBadgeTap(Map<String, dynamic> badge) {
    final route = badge['route'] as String?;

    if (route == null) return;

    // Navigate based on route
    switch (route) {
      case '/calendar':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(initialIndex: 1),
          ),
        );
        break;
      case '/contacts':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EventContactsScreen(),
          ),
        );
        break;
      case '/beo':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EventPortfolioScreen(),
          ),
        );
        break;
      case '/goals':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GoalsScreen(),
          ),
        );
        break;
      case '/checkouts':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ServerCheckoutsScreen(),
          ),
        );
        break;
      case '/paychecks':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PaychecksScreen(),
          ),
        );
        break;
      case '/receipts':
      case '/invoices':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const InvoicesReceiptsScreen(),
          ),
        );
        break;
      case '/stats':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(initialIndex: 3),
          ),
        );
        break;
      case '/jobs':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddJobScreen(),
          ),
        );
        break;
      default:
        debugPrint('Unknown route: $route');
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;
  final List<Map<String, dynamic>>? navigationBadges;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
    this.navigationBadges,
  });
}
