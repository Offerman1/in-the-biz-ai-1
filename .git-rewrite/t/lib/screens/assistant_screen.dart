import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ai_agent_service.dart';
import '../services/ai_actions_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/animated_logo.dart';
import 'package:intl/intl.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _loadingMessage = '';
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AIActionsService _aiActions = AIActionsService();
  final DatabaseService _db = DatabaseService();
  String _userContext = '';

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _loadChatHistory();
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

      final response = await aiAgent.sendMessage(message, history);

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

        // Refresh data if functions were executed
        if (functionsExecuted > 0) {
          // Refresh shifts
          final shiftProvider =
              Provider.of<ShiftProvider>(context, listen: false);
          await shiftProvider.loadShifts();

          // Theme changes happen automatically via database triggers
          // No manual refresh needed
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Attachment', style: AppTheme.titleMedium),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppTheme.primaryGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: AppTheme.accentBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: AppTheme.accentPurple,
                    onTap: () {
                      Navigator.pop(context);
                      _recordVideo();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.labelSmall),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // Save to phone gallery immediately
      final bytes = await photo.readAsBytes();
      await Gal.putImageBytes(bytes);
      _showPhotoTypeDialog(photo);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      _showPhotoTypeDialog(photo);
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      // Save to phone gallery immediately
      await Gal.putVideo(video.path);
      setState(() {
        _messages.add(ChatMessage(
          text: "📹 Video saved to gallery",
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _messages.add(ChatMessage(
          text:
              "Got it! I saved the video. Videos aren't analyzed by AI, but they're attached to your shift records.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _showPhotoTypeDialog(XFile photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.image, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            const Text('What is this image?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPhotoOption(
              title: 'Scan for Tips/Income',
              subtitle: 'Receipt, BEO, or Paycheck',
              icon: Icons.document_scanner,
              color: AppTheme.primaryGreen,
              onTap: () {
                Navigator.pop(context);
                _analyzeImage(photo);
              },
            ),
            const SizedBox(height: 12),
            _buildPhotoOption(
              title: 'Add to Gallery',
              subtitle: 'Event photos, memories',
              icon: Icons.photo_library,
              color: AppTheme.accentBlue,
              onTap: () {
                Navigator.pop(context);
                _saveToGallery(photo);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleMedium),
                  Text(subtitle, style: AppTheme.labelSmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeImage(XFile photo) async {
    setState(() {
      _messages.add(ChatMessage(
        text: "📷 Analyzing image...",
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: photo.path,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final bytes = await photo.readAsBytes();

      final result = await ApiService.analyzeImage(bytes);

      if (mounted) {
        _showReviewScreen(result, photo.path);
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              "Sorry, I couldn't analyze that image. Please try again with a clearer photo.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _showReviewScreen(Map<String, dynamic> data, String imagePath) {
    setState(() => _isLoading = false);

    // Create editable controllers with extracted data
    final dateController = TextEditingController(
        text: data['date']?.toString() ??
            DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final cashTipsController =
        TextEditingController(text: data['cashTips']?.toString() ?? '0.00');
    final creditTipsController =
        TextEditingController(text: data['creditTips']?.toString() ?? '0.00');
    final hourlyRateController =
        TextEditingController(text: data['hourlyRate']?.toString() ?? '0.00');
    final hoursWorkedController =
        TextEditingController(text: data['hoursWorked']?.toString() ?? '0.0');
    final eventNameController =
        TextEditingController(text: data['eventName']?.toString() ?? '');
    final notesController =
        TextEditingController(text: data['notes']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Icon(Icons.auto_fix_high,
                        color: AppTheme.primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Extracted Data',
                              style: AppTheme.headlineSmall),
                          Text('Review and edit before saving',
                              style: AppTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Confidence indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Data extracted successfully! Please verify.',
                        style: AppTheme.labelSmall
                            .copyWith(color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Event Name (if detected)
                if (data['eventName'] != null ||
                    eventNameController.text.isNotEmpty) ...[
                  _buildEditableReviewField(
                    label: 'Event / Party Name',
                    controller: eventNameController,
                    icon: Icons.celebration,
                    color: AppTheme.accentPurple,
                  ),
                  const SizedBox(height: 16),
                ],

                // Date
                _buildEditableReviewField(
                  label: 'Date',
                  controller: dateController,
                  icon: Icons.calendar_today,
                  color: AppTheme.accentBlue,
                  hint: 'YYYY-MM-DD',
                ),
                const SizedBox(height: 16),

                // Tips Row
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableReviewField(
                        label: 'Cash Tips',
                        controller: cashTipsController,
                        icon: Icons.money,
                        color: AppTheme.primaryGreen,
                        prefix: '\$',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEditableReviewField(
                        label: 'Credit Tips',
                        controller: creditTipsController,
                        icon: Icons.credit_card,
                        color: AppTheme.accentBlue,
                        prefix: '\$',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hours Row
                Row(
                  children: [
                    Expanded(
                      child: _buildEditableReviewField(
                        label: 'Hourly Rate',
                        controller: hourlyRateController,
                        icon: Icons.attach_money,
                        color: AppTheme.accentYellow,
                        prefix: '\$',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEditableReviewField(
                        label: 'Hours Worked',
                        controller: hoursWorkedController,
                        icon: Icons.access_time,
                        color: AppTheme.accentYellow,
                        suffix: 'hrs',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                _buildEditableReviewField(
                  label: 'Notes',
                  controller: notesController,
                  icon: Icons.notes,
                  color: AppTheme.textMuted,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Total Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.greenGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Total',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${_calculateTotal(cashTipsController.text, creditTipsController.text, hourlyRateController.text, hoursWorkedController.text).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _messages.add(ChatMessage(
                              text:
                                  "No problem! Discarded the scan. You can try again or enter manually.",
                              isUser: false,
                              timestamp: DateTime.now(),
                            ));
                          });
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Discard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: AppTheme.cardBackgroundLight),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _saveShiftFromReview(
                            date: dateController.text,
                            cashTips: cashTipsController.text,
                            creditTips: creditTipsController.text,
                            hourlyRate: hourlyRateController.text,
                            hoursWorked: hoursWorkedController.text,
                            eventName: eventNameController.text,
                            notes: notesController.text,
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Save Shift'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calculateTotal(
      String cash, String credit, String rate, String hours) {
    final cashVal = double.tryParse(cash) ?? 0;
    final creditVal = double.tryParse(credit) ?? 0;
    final rateVal = double.tryParse(rate) ?? 0;
    final hoursVal = double.tryParse(hours) ?? 0;
    return cashVal + creditVal + (rateVal * hoursVal);
  }

  Widget _buildEditableReviewField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    String? hint,
    String? prefix,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.labelSmall.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
            filled: true,
            fillColor: AppTheme.darkBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Save shift from review screen with edited values
  void _saveShiftFromReview({
    required String date,
    required String cashTips,
    required String creditTips,
    required String hourlyRate,
    required String hoursWorked,
    required String eventName,
    required String notes,
  }) async {
    try {
      final cashVal = double.tryParse(cashTips) ?? 0.0;
      final creditVal = double.tryParse(creditTips) ?? 0.0;
      final rateVal = double.tryParse(hourlyRate) ?? 0.0;
      final hoursVal = double.tryParse(hoursWorked) ?? 0.0;
      final total = cashVal + creditVal + (rateVal * hoursVal);

      final shift = Shift(
        id: '', // Will be generated
        date: _parseDate(date) ?? DateTime.now(),
        cashTips: cashVal,
        creditTips: creditVal,
        hourlyRate: rateVal,
        hoursWorked: hoursVal,
        eventName: eventName.isNotEmpty ? eventName : null,
        notes: notes.isNotEmpty ? notes : null,
      );

      final provider = Provider.of<ShiftProvider>(context, listen: false);
      final savedShift = await provider.addShift(shift);

      if (savedShift != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: "✅ Shift saved successfully!\n\n"
                "${eventName.isNotEmpty ? '🎉 Event: $eventName\n' : ''}"
                "💵 Cash Tips: \$${cashVal.toStringAsFixed(2)}\n"
                "💳 Credit Tips: \$${creditVal.toStringAsFixed(2)}\n"
                "⏱️ Hours: ${hoursVal.toStringAsFixed(1)} @ \$${rateVal.toStringAsFixed(2)}/hr\n"
                "━━━━━━━━━━━━━━━━━━━\n"
                "💰 Total: \$${total.toStringAsFixed(2)}\n\n"
                "View it in your Calendar!",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        throw Exception('Failed to save shift');
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              "❌ Failed to save shift: ${e.toString()}\n\nPlease try again or enter manually.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
    _scrollToBottom();
  }

  // Helper to parse date from various formats
  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null) return null;
    if (dateStr is DateTime) return dateStr;

    try {
      // Try parsing common formats
      if (dateStr.toString().toLowerCase() == 'today') {
        return DateTime.now();
      }
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return null;
    }
  }

  // Helper to parse numbers safely
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    try {
      // Remove currency symbols and parse
      final cleaned = value.toString().replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  void _saveToGallery(XFile photo) {
    setState(() {
      _messages.add(ChatMessage(
        text: "📸 Photo added to gallery",
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: photo.path,
      ));
      _messages.add(ChatMessage(
        text: "Photo saved! You can view it in your shift details.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
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
          backgroundColor: AppTheme.cardBackground,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
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
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showAttachmentOptions,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackgroundLight.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.add, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackgroundLight.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.camera_alt,
                            color: AppTheme.textSecondary),
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
                            hintText:
                                'Ask me about earnings, goals, or scan a photo...',
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
                          color: _isLoading ? AppTheme.textMuted : Colors.black,
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
                  color: message.isUser ? Colors.black : AppTheme.textPrimary,
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
