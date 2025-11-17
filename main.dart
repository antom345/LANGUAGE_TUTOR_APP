import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const LanguageTutorApp());
}

class LanguageTutorApp extends StatelessWidget {
  const LanguageTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Tutor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F4F7),
      ),
      home: const SetupPage(),
    );
  }
}

// --------------------- МОДЕЛИ -----------------------

class ChatConfig {
  final String language;
  final String level;
  final String topic;
  final String userGender;
  final String partnerGender;
  final int? userAge;

  const ChatConfig({
    required this.language,
    required this.level,
    required this.topic,
    required this.userGender,
    required this.partnerGender,
    this.userAge,
  });
}

class ChatMessage {
  final String sender;
  final String text;
  final bool isUser;
  final bool isSystem;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.isUser,
    this.isSystem = false,
  });
}

// --------------------- ЭКРАН НАСТРОЕК -----------------------

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String _language = 'English';
  String _level = 'B1';
  String _userGender = 'unspecified';
  String _partnerGender = 'female';
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _topicController =
      TextEditingController(text: 'General conversation');

  @override
  void dispose() {
    _ageController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  String _languageLabel(String lang) {
    switch (lang) {
      case 'English':
        return 'English';
      case 'German':
        return 'German';
      case 'French':
        return 'French';
      case 'Spanish':
        return 'Spanish';
      case 'Italian':
        return 'Italian';
      case 'Korean':
        return 'Korean';
      default:
        return lang;
    }
  }

  void _startChat() {
    int? age;
    if (_ageController.text.trim().isNotEmpty) {
      final parsed = int.tryParse(_ageController.text.trim());
      if (parsed != null && parsed > 0 && parsed < 120) {
        age = parsed;
      }
    }

    final topic = _topicController.text.trim().isEmpty
        ? 'General conversation'
        : _topicController.text.trim();

    final config = ChatConfig(
      language: _language,
      level: _level,
      topic: topic,
      userGender: _userGender,
      partnerGender: _partnerGender,
      userAge: age,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(config: config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Tutor — Setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Язык
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Language',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _language,
                          isExpanded: true,
                          onChanged: (v) => setState(() => _language = v!),
                          items: const [
                            DropdownMenuItem(
                              value: 'English',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'German',
                              child: Text('German'),
                            ),
                            DropdownMenuItem(
                              value: 'French',
                              child: Text('French'),
                            ),
                            DropdownMenuItem(
                              value: 'Spanish',
                              child: Text('Spanish'),
                            ),
                            DropdownMenuItem(
                              value: 'Italian',
                              child: Text('Italian'),
                            ),
                            DropdownMenuItem(
                              value: 'Korean',
                              child: Text('Korean'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Уровень
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                            .map(
                              (lvl) => ChoiceChip(
                                label: Text(lvl),
                                selected: _level == lvl,
                                onSelected: (_) =>
                                    setState(() => _level = lvl),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Пол, возраст, собеседник
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Your gender:'),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Not specified'),
                              value: 'unspecified',
                              groupValue: _userGender,
                              onChanged: (v) =>
                                  setState(() => _userGender = v!),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Male'),
                              value: 'male',
                              groupValue: _userGender,
                              onChanged: (v) =>
                                  setState(() => _userGender = v!),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Female'),
                              value: 'female',
                              groupValue: _userGender,
                              onChanged: (v) =>
                                  setState(() => _userGender = v!),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Your age (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Who do you want to talk to?',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Woman'),
                              value: 'female',
                              groupValue: _partnerGender,
                              onChanged: (v) =>
                                  setState(() => _partnerGender = v!),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Man'),
                              value: 'male',
                              groupValue: _partnerGender,
                              onChanged: (v) =>
                                  setState(() => _partnerGender = v!),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Тема
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Topic',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _topicController,
                        decoration: const InputDecoration(
                          hintText: 'Travel, university life, work, hobbies...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('Start chat in ${_languageLabel(_language)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------- ЭКРАН ЧАТА -----------------------

class ChatPage extends StatefulWidget {
  final ChatConfig config;

  const ChatPage({super.key, required this.config});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Бекэнд
  static const String backendBase = 'http://172.86.88.21:8000';
  static const String chatEndpoint = '$backendBase/chat';
  static const String translateEndpoint = '$backendBase/translate_word';

  final TextEditingController _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _history = [];

  bool _isSending = false;

  String _partnerName = 'Tutor';

  @override
  void initState() {
    super.initState();
    _partnerName = _guessPartnerName(
      widget.config.language,
      widget.config.partnerGender,
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _guessPartnerName(String language, String partnerGender) {
    final g = partnerGender.toLowerCase();
    switch (language) {
      case 'English':
        return g == 'male' ? 'James' : 'Emily';
      case 'German':
        return g == 'male' ? 'Lukas' : 'Anna';
      case 'French':
        return g == 'male' ? 'Pierre' : 'Marie';
      case 'Spanish':
        return g == 'male' ? 'Carlos' : 'Sofia';
      case 'Italian':
        return g == 'male' ? 'Marco' : 'Giulia';
      case 'Korean':
        return g == 'male' ? 'Minjun' : 'Jisoo';
      default:
        return 'Tutor';
    }
  }

  String _languageLabel() {
    switch (widget.config.language) {
      case 'English':
        return 'English';
      case 'German':
        return 'German';
      case 'French':
        return 'French';
      case 'Spanish':
        return 'Spanish';
      case 'Italian':
        return 'Italian';
      case 'Korean':
        return 'Korean';
      default:
        return widget.config.language;
    }
  }

  // ------------ Отправка сообщений ------------

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _inputController.clear();
      _messages.add(
        ChatMessage(sender: 'You', text: text, isUser: true),
      );
      _history.add({'role': 'user', 'content': text});
    });

    try {
      final body = {
        'messages': _history,
        'language': widget.config.language,
        'topic': widget.config.topic,
        'level': widget.config.level,
        'user_gender': widget.config.userGender,
        'partner_gender': widget.config.partnerGender,
        'user_age': widget.config.userAge,
      };

      final response = await http.post(
        Uri.parse(chatEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = data['reply'] as String? ?? 'Empty reply';
        final partner =
            data['partner_name'] as String? ?? _partnerName;

        setState(() {
          _partnerName = partner;
          _messages.add(
            ChatMessage(sender: _partnerName, text: reply, isUser: false),
          );
          _history.add({'role': 'assistant', 'content': reply});
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              sender: 'System',
              text:
                  'Server error: ${response.statusCode}. Please try again later.',
              isUser: false,
              isSystem: true,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            sender: 'System',
            text: 'Connection error: $e',
            isUser: false,
            isSystem: true,
          ),
        );
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // ------------ Перевод слова ------------

  Future<void> _translateWord(String rawWord) async {
    final word = rawWord.trim();
    if (word.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(translateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'word': word,
          'language': widget.config.language,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final translation = data['translation'] as String? ?? '';
        final example = data['example'] as String? ?? '';

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text(word),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (translation.isNotEmpty) ...[
                    const Text(
                      'Перевод:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(translation),
                    const SizedBox(height: 8),
                  ],
                  if (example.isNotEmpty) ...[
                    const Text(
                      'Пример:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(example),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // можно тихо игнорировать или показать ошибку
      }
    } catch (_) {
      // тоже можем проигнорировать
    }
  }

  // ------------ UI ------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

return Scaffold(
  appBar: AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chat with $_partnerName'),
        Text(
          '${_languageLabel()} · level ${widget.config.level}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.6),
          ),
        ),
      ],
    ),
  ),
  body: SafeArea(
        child: Column(
          children: [
            // Список сообщений
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Start chatting with $_partnerName 👋',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _ChatBubble(
                              message: msg,
                              onWordTap: (!msg.isUser && !msg.isSystem)
                                  ? _translateWord
                                  : null,
                            );
                          },
                        ),
                ),
              ),
            ),

            if (_isSending)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_partnerName is typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

            // Поле ввода
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _inputController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Write a message...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _isSending ? cs.outline : cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const Icon(Icons.hourglass_top)
                            : const Icon(Icons.send),
                        color: cs.onPrimary,
                        onPressed: _isSending ? null : _sendMessage,
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
}

// --------------------- ПУЗЫРИ СООБЩЕНИЙ -----------------------

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String word)? onWordTap;

  const _ChatBubble({
    required this.message,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final isSystem = message.isSystem;

    final alignment =
        isUser ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleColor = isSystem
        ? Colors.grey.shade300
        : (isUser
            ? cs.primary.withOpacity(0.9)
            : cs.secondaryContainer);

    final textColor = isSystem
        ? Colors.black87
        : (isUser ? cs.onPrimary : cs.onSecondaryContainer);

    final senderStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: textColor.withOpacity(0.8),
    );

    final textStyle = TextStyle(
      fontSize: 14,
      color: textColor,
    );

    Widget textWidget;

    if (!isUser && !isSystem && onWordTap != null) {
      // Сообщение бота: каждое слово кликабельно, пробелы сохраняем вручную
      final words = message.text.split(' ');
      final spans = <InlineSpan>[];

      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        final clean = word.replaceAll(RegExp(r'[.,!?;:()"«»\[\]]'), '');

        spans.add(
          TextSpan(
            text: word,
            style: textStyle.copyWith(
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (clean.trim().isNotEmpty) {
                  onWordTap!(clean);
                }
              },
          ),
        );

        // Добавляем пробел между словами (кроме последнего)
        if (i < words.length - 1) {
          spans.add(TextSpan(text: ' ', style: textStyle));
        }
      }

      textWidget = RichText(
        text: TextSpan(children: spans),
      );
    } else {

      // пользователь или системное сообщение — обычный текст
      textWidget = Text(
        message.text,
        style: textStyle,
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.sender, style: senderStyle),
            const SizedBox(height: 2),
            textWidget,
          ],
        ),
      ),
    );
  }
}
