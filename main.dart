import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const LanguageTutorApp());
}

// ============ ROOT APP ============

class LanguageTutorApp extends StatelessWidget {
  const LanguageTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Tutor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B5BB5)),
        useMaterial3: true,
        fontFamily: 'SF Pro Text',
      ),
      home: const SetupScreen(),
    );
  }
}

// ============ MODELS ============

class ChatMessage {
  final String role; // "user" или "assistant"
  final String text;
  final bool isCorrections; // отдельное сообщение с ошибками

  ChatMessage({
    required this.role,
    required this.text,
    this.isCorrections = false,
  });
}

class SavedWord {
  final String word;
  final String translation;
  final String example;
  final String exampleTranslation;

  const SavedWord({
    required this.word,
    required this.translation,
    required this.example,
    required this.exampleTranslation,
  });
}

// ============ SETUP SCREEN (шаги выбора) ============

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _step = 0;

  // шаг 1 — язык
  String _language = 'English';

  // шаг 2 — уровень
  String _level = 'B1';

  // шаг 3 — пользователь и собеседник
  String _userGender = 'unspecified';
  int? _userAge;
  String _partnerGender = 'female';

  // шаг 4 — тема
  final TextEditingController _topicController =
      TextEditingController(text: 'General conversation');

  final List<String> _topicSuggestions = const [
    'Daily life',
    'Travel',
    'Work & study',
    'Relationships',
    'Hobbies',
    'Movies & series',
    'Culture & society',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      if (_step < 3) {
        _step++;
      } else {
        _openChat();
      }
    });
  }

  void _prevStep() {
    setState(() {
      if (_step > 0) _step--;
    });
  }

  void _openChat() {
    final topic = _topicController.text.trim().isEmpty
        ? 'General conversation'
        : _topicController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          language: _language,
          level: _level,
          topic: topic,
          userGender: _userGender,
          userAge: _userAge,
          partnerGender: _partnerGender,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildLanguageStep(),
      _buildLevelStep(),
      _buildProfileStep(),
      _buildTopicStep(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Tutor setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // индикатор шагов
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  steps.length,
                  (index) => Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _step
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: steps[_step]),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      child: Text(_step < steps.length - 1 ? 'Next' : 'Start chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- шаг 1: язык -----

  Widget _buildLanguageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose language',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        _languageTile('English'),
        _languageTile('German'),
        _languageTile('French'),
        _languageTile('Spanish'),
        _languageTile('Italian'),
        _languageTile('Korean'),
      ],
    );
  }

  Widget _languageTile(String lang) {
    final selected = _language == lang;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(lang),
      trailing: selected
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: () {
        setState(() {
          _language = lang;
        });
      },
    );
  }

  // ----- шаг 2: уровень -----

  Widget _buildLevelStep() {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your language level',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((lvl) {
            final selected = _level == lvl;
            return ChoiceChip(
              label: Text(lvl),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _level = lvl;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Choose approximately how confident you feel in this language. '
          'The tutor will adapt to this level.',
        ),
      ],
    );
  }

  // ----- шаг 3: профиль -----

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About you',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('Your gender'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Not important'),
                selected: _userGender == 'unspecified',
                onSelected: (_) {
                  setState(() {
                    _userGender = 'unspecified';
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Male'),
                selected: _userGender == 'male',
                onSelected: (_) {
                  setState(() {
                    _userGender = 'male';
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Female'),
                selected: _userGender == 'female',
                onSelected: (_) {
                  setState(() {
                    _userGender = 'female';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Your age (optional)'),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 20',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                if (value.trim().isEmpty) {
                  _userAge = null;
                } else {
                  _userAge = int.tryParse(value.trim());
                }
              });
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Who do you want to talk to?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Woman'),
                selected: _partnerGender == 'female',
                onSelected: (_) {
                  setState(() {
                    _partnerGender = 'female';
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Man'),
                selected: _partnerGender == 'male',
                onSelected: (_) {
                  setState(() {
                    _partnerGender = 'male';
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----- шаг 4: тема -----

  Widget _buildTopicStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a topic',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'Topic',
              hintText: 'For example: Travel, work, hobbies…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Suggestions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topicSuggestions.map((t) {
              final selected = _topicController.text.trim() == t;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _topicController.text = t;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'You can type your own topic or tap one of the suggestions. '
            'The tutor will start the conversation with a question related to this topic.',
          ),
        ],
      ),
    );
  }
}

// ============ CHAT SCREEN ============

class ChatScreen extends StatefulWidget {
  final String language;
  final String level;
  final String topic;
  final String userGender;
  final int? userAge;
  final String partnerGender;

  const ChatScreen({
    super.key,
    required this.language,
    required this.level,
    required this.topic,
    required this.userGender,
    required this.userAge,
    required this.partnerGender,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  bool _isSending = false;
  final List<SavedWord> _savedWords = [];

  // прогресс по словам пользователя
  int _userWordCount = 0;
  int _currentLevel = 1;
  final List<int> _levelTargets = [50, 150, 300, 500, 1000];

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _startConversation() async {
    await _sendToBackend(initial: true);
  }

  Future<void> _sendUserMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _userWordCount += text.split(RegExp(r'\s+')).length;
      _inputController.clear();
    });

    _updateProgress();
    await _sendToBackend(initial: false);
  }

  Future<void> _sendToBackend({required bool initial}) async {
    setState(() {
      _isSending = true;
    });

    try {
      final uri = Uri.parse('http://172.86.88.21:8000/chat');

      final messagesPayload = initial
          ? []
          : _messages
              .where((m) => !m.isCorrections) // в историю не отправляем сообщения с ошибками
              .map((m) => {
                    'role': m.role,
                    'content': m.text,
                  })
              .toList();

      final body = jsonEncode({
        'messages': messagesPayload,
        'language': widget.language,
        'topic': widget.topic,
        'level': widget.level,
        'user_gender': widget.userGender,
        'user_age': widget.userAge,
        'partner_gender': widget.partnerGender,
      });

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final reply = data['reply'] as String? ?? '';
        final correctionsText = data['corrections_text'] as String? ?? '';

        setState(() {
          if (reply.trim().isNotEmpty) {
            _messages.add(ChatMessage(role: 'assistant', text: reply.trim()));
          }
          if (correctionsText.trim().isNotEmpty) {
            _messages.add(ChatMessage(
              role: 'assistant',
              text: correctionsText.trim(),
              isCorrections: true,
            ));
          }
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant',
            text: 'System: error ${resp.statusCode} from server. Please try again.',
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          text: 'System: connection error: $e',
        ));
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _updateProgress() {
    while (_currentLevel <= _levelTargets.length &&
        _userWordCount >= _levelTargets[_currentLevel - 1]) {
      _currentLevel++;
      if (_currentLevel > _levelTargets.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amazing! You completed all 5 progress levels 🎉'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Great! You finished level ${_currentLevel - 1}. Level $_currentLevel unlocked!'),
          ),
        );
      }
    }
  }

  double get _progressValue {
    if (_currentLevel > _levelTargets.length) return 1.0;
    final target = _levelTargets[_currentLevel - 1].toDouble();
    return (_userWordCount / target).clamp(0.0, 1.0);
  }

  String get _progressLabel {
    if (_currentLevel > _levelTargets.length) {
      return 'All levels completed: $_userWordCount words';
    }
    return 'Level $_currentLevel · ${_userWordCount}/${_levelTargets[_currentLevel - 1]} words';
  }

  bool _isWordSaved(String word) {
    return _savedWords.any(
      (entry) => entry.word.toLowerCase() == word.toLowerCase(),
    );
  }

  void _saveWord(SavedWord word) {
    setState(() {
      final index = _savedWords.indexWhere(
        (entry) => entry.word.toLowerCase() == word.word.toLowerCase(),
      );
      if (index >= 0) {
        _savedWords[index] = word;
      } else {
        _savedWords.add(word);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${word.word} добавлено в словарь')),
    );
  }

  void _removeSavedWord(String word) {
    if (!_isWordSaved(word)) return;

    setState(() {
      _savedWords.removeWhere(
        (entry) => entry.word.toLowerCase() == word.toLowerCase(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$word удалено из словаря')),
    );
  }

  // ------ перевод слова по нажатию ------

  Future<void> _onWordTap(String rawWord) async {
    // убираем пунктуацию по краям
    final word =
        rawWord.replaceAll(RegExp(r"[^\p{Letter}']", unicode: true), '');
    if (word.isEmpty) return;

    try {
      final uri = Uri.parse('http://172.86.88.21:8000/translate-word');

      final body = jsonEncode({
        'word': word,
        'language': widget.language,
        'target_language': 'Russian',
      });

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: ${resp.statusCode}')),
        );
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final translation = data['translation'] as String? ?? 'нет данных';
      final example = data['example'] as String? ?? 'нет примера';
      final exampleTranslation =
        data['example_translation'] as String? ?? 'нет перевода примера';


      if (!mounted) return;

      final savedWord = SavedWord(
        word: word,
        translation: translation,
        example: example,
        exampleTranslation: exampleTranslation,
      );

      bool isSaved = _isWordSaved(word);

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(child: Text(word)),
                  IconButton(
                    tooltip: isSaved
                        ? 'Удалить из словаря'
                        : 'Добавить в словарь',
                    icon: Icon(
                      isSaved ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                    ),
                    onPressed: () {
                      dialogSetState(() {
                        if (isSaved) {
                          _removeSavedWord(word);
                          isSaved = false;
                        } else {
                          _saveWord(savedWord);
                          isSaved = true;
                        }
                      });
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Перевод: $translation'),
                  const SizedBox(height: 8),
                  Text(
                    'Пример:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(example),
                  const SizedBox(height: 8),
                  Text(
                    'Перевод примера:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(exampleTranslation),
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
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation error: $e')),
      );
    }
  }

  // ------ UI ------

  @override
  Widget build(BuildContext context) {
    final partnerName = _detectPartnerNameFromMessages();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat with $partnerName'),
              Text(
                '${widget.language} · level ${widget.level}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Dictionary'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SafeArea(child: _buildChatTab()),
            SafeArea(child: _buildDictionaryTab()),
          ],
        ),
      ),
    );
  }

  String _detectPartnerNameFromMessages() {
    if (widget.language == 'German') {
      return widget.partnerGender == 'male' ? 'Lukas' : 'Anna';
    }
    if (widget.language == 'French') {
      return widget.partnerGender == 'male' ? 'Pierre' : 'Marie';
    }
    if (widget.language == 'Spanish') {
      return widget.partnerGender == 'male' ? 'Carlos' : 'Sofia';
    }
    if (widget.language == 'Italian') {
      return widget.partnerGender == 'male' ? 'Marco' : 'Giulia';
    }
    if (widget.language == 'Korean') {
      return widget.partnerGender == 'male' ? 'Minjun' : 'Jisoo';
    }
    return widget.partnerGender == 'male' ? 'James' : 'Emily';
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isUser) {
    final alignment =
        isUser ? Alignment.centerRight : Alignment.centerLeft;

    Color bgColor;
    Color textColor;
    String name;

    if (msg.isCorrections) {
      bgColor = const Color(0xFFFFF3CD); // жёлтый для ошибок
      textColor = const Color(0xFF665200);
      name = 'Corrections';
    } else if (isUser) {
      bgColor = const Color(0xFF4B5BB5);
      textColor = Colors.white;
      name = 'You';
    } else {
      bgColor = const Color(0xFFE4E7FF);
      textColor = const Color(0xFF222222);
      name = _detectPartnerNameFromMessages();
    }

// содержимое: для пользователя и блока ошибок — обычный Text,
// для обычных ответов бота — кликабельные слова
Widget content;
if (!isUser && !msg.isCorrections) {
  final words = msg.text.split(RegExp(r'\s+'));
  content = Wrap(
    children: [
      for (int i = 0; i < words.length; i++)
        GestureDetector(
          onTap: () => _onWordTap(words[i]),
          child: Text(
            (i == 0 ? '' : ' ') + words[i], // ЯВНО добавляем пробел
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
        ),
    ],
  );
} else {
  content = Text(
    msg.text,
    style: TextStyle(color: textColor, fontSize: 14),
  );
}


    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: msg.isCorrections
                    ? Colors.black54
                    : (isUser ? Colors.white70 : Colors.grey.shade700),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _progressValue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                _progressLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg.role == 'user';
              return _buildMessageBubble(msg, isUser);
            },
          ),
        ),
        const Divider(height: 1),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildDictionaryTab() {
    if (_savedWords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Вы ещё не добавили слова. Нажмите на слово в чате и выделите его звездой, чтобы сохранить.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _savedWords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final saved = _savedWords[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${saved.word} — ${saved.translation}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Удалить из словаря',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeSavedWord(saved.word),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Пример:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(saved.example),
              const SizedBox(height: 8),
              Text(
                'Перевод примера:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(saved.exampleTranslation),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write a message…',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendUserMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _isSending ? null : _sendUserMessage,
          ),
        ],
      ),
    );
  }
}
