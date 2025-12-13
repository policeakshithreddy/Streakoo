import 'package:flutter/material.dart';
import '../services/groq_ai_service.dart';
import '../services/ai_goal_parser_service.dart';
import '../services/health_service.dart';

class AiHabitAssistantModal extends StatefulWidget {
  final String habitName;
  final String category;
  final Function(
    String goal,
    String? reminderTime,
    double? healthGoalValue,
    HealthMetricType? healthMetricType,
    int? focusDuration,
  ) onApply;

  const AiHabitAssistantModal({
    super.key,
    required this.habitName,
    required this.category,
    required this.onApply,
  });

  @override
  State<AiHabitAssistantModal> createState() => _AiHabitAssistantModalState();
}

class _AiHabitAssistantModalState extends State<AiHabitAssistantModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = []; // Role: content
  bool _isAnalyzing = true;
  bool _isTyping = false;
  ParsedGoalData? _lastParsedData;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _fadeAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_animController);

    // Start analysis
    _startAnalysis();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startAnalysis() async {
    // Fake analysis delay for effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
      _isTyping = true;
    });

    // Initial prompt
    final systemPrompt =
        '''You are an expert ${widget.category} coach. Analyze the user's intent to start "${widget.habitName}".
Suggest a specific, measurable goal and a good time of day (reminder).
Keep responses concise, encouraging, and conversational.
Format suggestions clearly.
If you suggest a time, mention it like "at 7:00 AM" or "at 20:00".''';

    final initialUserMsg =
        'I want to start a habit called "${widget.habitName}" in the ${widget.category} category. Suggest a good goal and time.';

    _messages.add({'role': 'system', 'content': systemPrompt});
    _messages.add({'role': 'user', 'content': initialUserMsg});

    try {
      final response = await GroqAIService.instance.generateChatResponse(
        messages: _messages,
      );

      if (mounted) {
        if (response != null) {
          _addBotMessage(response);
          _tryParseGoal(response);
        } else {
          _addBotMessage("I couldn't generate a suggestion. What's your goal?");
        }
      }
    } catch (e) {
      if (mounted) _addBotMessage("Connection error. Let's try chatting.");
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Send entire history (excluding system prompt if list too long? for now keep all)
      final response = await GroqAIService.instance.generateChatResponse(
        messages: _messages,
      );

      if (mounted && response != null) {
        _addBotMessage(response);
        _tryParseGoal(response);
      }
    } catch (e) {
      if (mounted) _addBotMessage("Sorry, I missed that. Can you repeat?");
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _addBotMessage(String content) {
    setState(() {
      _messages.add({'role': 'assistant', 'content': content});
    });
    _scrollToBottom();
  }

  void _tryParseGoal(String text) {
    final data = AiGoalParserService.instance.parseGoal(text);
    // Only update if we found something useful
    if (data.originalGoal.isNotEmpty || data.suggestedReminderTime != null) {
      // If originalGoal is empty (failed to parse useful text), use the full text?
      // No, parseGoal returns originalGoal as cleaned up string.
      // If it returns empty string, it means it didn't find a pattern?
      // Actually parseGoal just tries to extract info.
      // Let's rely on hasHealthGoal or hasReminder
      if (data.hasHealthGoal || data.hasReminder || text.length < 100) {
        setState(() {
          _lastParsedData = data;
          // If parseGoal returned text is empty (fallback), use a snippet of the response?
          // AiGoalParserService returns `originalGoal` which is passed in.
          // We want the AI's suggestion text.
          // Let's assume the parser's `originalGoal` is what we want IF it extracted metrics.
          // If not, we might just want to use the text as is if it's short.
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFFFFA94A); // Brand Orange

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // 75% height
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.auto_awesome, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Habit Coach',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Analyzing & Suggesting',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isAnalyzing
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(Icons.psychology,
                                size: 40, color: primaryColor),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Analyzing your habit...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crafting the perfect goal for "${widget.habitName}"',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length -
                        2 +
                        (_isTyping
                            ? 1
                            : 0), // Skip first 2 (system + initial prompt)
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length - 2) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    primaryColor.withValues(alpha: 0.1),
                                child: Icon(Icons.auto_awesome,
                                    size: 14, color: primaryColor),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Typing...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final msg = _messages[index + 2];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? primaryColor : theme.cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isUser
                                  ? const Radius.circular(20)
                                  : const Radius.circular(4),
                              bottomRight: isUser
                                  ? const Radius.circular(4)
                                  : const Radius.circular(20),
                            ),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: theme.dividerColor
                                        .withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            msg['content']!,
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Suggestion Action Card
          if (!_isAnalyzing && _lastParsedData != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'AI Suggestion',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_lastParsedData!.suggestedReminderTime != null)
                    Text(
                      '⏰ Reminder: ${_lastParsedData!.suggestedReminderTime}',
                      style: TextStyle(
                          fontSize: 14, color: theme.colorScheme.onSurface),
                    ),

                  // Display parsed goals
                  if (_lastParsedData!.hasHealthGoal)
                    Text(
                      '🎯 Goal: ${_lastParsedData!.healthGoalValue!.toInt()} ${_lastParsedData!.healthMetric!.name}',
                      style: TextStyle(
                          fontSize: 14, color: theme.colorScheme.onSurface),
                    )
                  else
                    // Fallback to text if structured data is weak but text exists
                    Text(
                      '🎯 Goal: ${_messages.last['role'] == 'assistant' ? _messages.last['content']!.split('\n').first : "Custom Goal"}',
                      // Simple heuristic to show top line as goal summary
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14, color: theme.colorScheme.onSurface),
                    ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply logic
                        // We pass the raw text from the LAST assistant message as "goal description"
                        // And parsed values for specific fields if available
                        String goalText = "";
                        if (_messages.isNotEmpty &&
                            _messages.last['role'] == 'assistant') {
                          goalText = _messages.last['content']!;
                        }

                        widget.onApply(
                          goalText,
                          _lastParsedData?.suggestedReminderTime,
                          _lastParsedData?.healthGoalValue,
                          _lastParsedData?.healthMetric,
                          _lastParsedData?.focusDuration,
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // requested black button
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: primaryColor), // requested orange border
                        ),
                      ),
                      child: const Text('Apply to Habit'),
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          if (!_isAnalyzing)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write a message to habit...',
                        hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, size: 20),
                      color: primaryColor,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
