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

class CharacterLook {
  final Color primaryColor; // background tint
  final Color accentColor;
  final Color hairColor;
  final Color outfitColor;
  final Color skinColor;
  final bool narrowEyes;
  final bool longHair;
  final String badgeText;

  const CharacterLook({
    required this.primaryColor,
    required this.accentColor,
    required this.hairColor,
    required this.outfitColor,
    required this.skinColor,
    required this.narrowEyes,
    required this.longHair,
    required this.badgeText,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterLook &&
        other.primaryColor == primaryColor &&
        other.accentColor == accentColor &&
        other.hairColor == hairColor &&
        other.outfitColor == outfitColor &&
        other.skinColor == skinColor &&
        other.narrowEyes == narrowEyes &&
        other.longHair == longHair &&
        other.badgeText == badgeText;
  }

  @override
  int get hashCode => Object.hash(
        primaryColor,
        accentColor,
        hairColor,
        outfitColor,
        skinColor,
        narrowEyes,
        longHair,
        badgeText,
      );
}

CharacterLook characterLookFor(String language, String gender) {
  final isMale = gender.toLowerCase() == 'male';
  final cleanLang = language.trim().isEmpty ? 'Language' : language.trim();
  final shortCode =
      cleanLang.length >= 2 ? cleanLang.substring(0, 2).toUpperCase() : cleanLang.toUpperCase();
  switch (language) {
    case 'Korean':
      return CharacterLook(
        primaryColor: const Color(0xFFFFF3E0),
        accentColor: const Color(0xFFFFB74D),
        hairColor: const Color(0xFF4E342E),
        outfitColor: const Color(0xFF90CAF9),
        skinColor: kFairSkin,
        narrowEyes: true,
        longHair: !isMale,
        badgeText: 'KR',
      );
    case 'German':
      return CharacterLook(
        primaryColor: const Color(0xFFE3F2FD),
        accentColor: const Color(0xFF64B5F6),
        hairColor: isMale ? const Color(0xFF3E2723) : const Color(0xFF6D4C41),
        outfitColor: const Color(0xFFFFD54F),
        skinColor: kFairSkin,
        narrowEyes: false,
        longHair: !isMale,
        badgeText: 'DE',
      );
    case 'French':
      return CharacterLook(
        primaryColor: const Color(0xFFFFEBEE),
        accentColor: const Color(0xFFF06292),
        hairColor: const Color(0xFF4E342E),
        outfitColor: const Color(0xFF90A4AE),
        skinColor: kFairSkin,
        narrowEyes: false,
        longHair: true,
        badgeText: 'FR',
      );
    case 'Spanish':
      return CharacterLook(
        primaryColor: const Color(0xFFFFF8E1),
        accentColor: const Color(0xFFFFD54F),
        hairColor: const Color(0xFF5D4037),
        outfitColor: const Color(0xFFD32F2F),
        skinColor: kFairSkin,
        narrowEyes: false,
        longHair: !isMale,
        badgeText: 'ES',
      );
    case 'Italian':
      return CharacterLook(
        primaryColor: const Color(0xFFE8F5E9),
        accentColor: const Color(0xFF66BB6A),
        hairColor: const Color(0xFF3E2723),
        outfitColor: const Color(0xFF1E88E5),
        skinColor: kFairSkin,
        narrowEyes: false,
        longHair: !isMale,
        badgeText: 'IT',
      );
    default:
      return CharacterLook(
        primaryColor: const Color(0xFFEDE7F6),
        accentColor: const Color(0xFF9575CD),
        hairColor: isMale ? const Color(0xFF5D4037) : const Color(0xFF4E342E),
        outfitColor: const Color(0xFF4DB6AC),
        skinColor: kFairSkin,
        narrowEyes: false,
        longHair: !isMale,
        badgeText: shortCode,
      );
  }
}

Color lighten(Color color, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(color);
  final lighter =
      hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return lighter.toColor();
}

Color darken(Color color, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(color);
  final darker =
      hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return darker.toColor();
}

const Color kFairSkin = Color(0xFFFFF6E8);

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

  CharacterLook get _characterLook =>
      characterLookFor(widget.language, widget.partnerGender);

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
          leadingWidth: 120,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              _buildCharacterAvatar(),
            ],
          ),
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
    final look = _characterLook;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lighten(look.primaryColor, 0.25),
            Colors.white,
            lighten(look.accentColor, 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
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
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildInputBar(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 260,
            child: _buildCharacterStage(look),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildCharacterStage(CharacterLook look) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final figureWidth = width * 0.9;
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: CharacterBackgroundPainter(look)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: figureWidth,
                height: height * 0.9,
                child: CustomPaint(painter: CharacterScenePainter(look)),
              ),
            ),
          ],
        );
      },
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

  Widget _buildCharacterAvatar() {
    final look = _characterLook;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CharacterAvatar(
            look: look,
            size: 56,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: look.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                look.badgeText,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterAvatar extends StatelessWidget {
  final CharacterLook look;
  final double size;

  const CharacterAvatar({super.key, required this.look, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CharacterFacePainter(look),
      ),
    );
  }
}

class CharacterFacePainter extends CustomPainter {
  final CharacterLook look;

  CharacterFacePainter(this.look);

  @override
  void paint(Canvas canvas, Size size) {
    const double baseWidth = 120;
    const double baseHeight = 120;
    double scale = size.width / baseWidth;
    final heightScale = size.height / baseHeight;
    if (heightScale < scale) scale = heightScale;
    final dx = (size.width - baseWidth * scale) / 2;
    final dy = (size.height - baseHeight * scale) / 2;

    double tx(double x) => dx + x * scale;
    double ty(double y) => dy + y * scale;

    final skin = look.skinColor;
    final skinShade = darken(skin, 0.12);
    final skinHighlight = lighten(skin, 0.08);
    final hair = look.hairColor;
    final hairShade = darken(hair, 0.12);
    final hairHighlight = lighten(hair, 0.1);
    final shirt = look.outfitColor;
    final shirtShade = darken(shirt, 0.18);
    final shirtHighlight = lighten(shirt, 0.15);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, ty(110)),
        width: 70 * scale,
        height: 18 * scale,
      ),
      Paint()..color = Colors.black.withOpacity(0.08),
    );

    final neckRect = Rect.fromLTWH(tx(50), ty(90), 20 * scale, 18 * scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(neckRect, Radius.circular(6 * scale)),
      Paint()..color = skinShade,
    );

    final collarLeft = Path()
      ..moveTo(tx(35), ty(95))
      ..lineTo(tx(55), ty(95))
      ..lineTo(tx(48), ty(120))
      ..lineTo(tx(28), ty(120))
      ..close();
    canvas.drawPath(collarLeft, Paint()..color = shirt);

    final collarRight = Path()
      ..moveTo(tx(85), ty(95))
      ..lineTo(tx(65), ty(95))
      ..lineTo(tx(72), ty(120))
      ..lineTo(tx(92), ty(120))
      ..close();
    canvas.drawPath(collarRight, Paint()..color = shirtShade);

    final headFront = Path()
      ..moveTo(tx(20), ty(20))
      ..lineTo(tx(100), ty(20))
      ..lineTo(tx(110), ty(65))
      ..lineTo(tx(80), ty(110))
      ..lineTo(tx(40), ty(110))
      ..lineTo(tx(10), ty(65))
      ..close();
    canvas.drawPath(headFront, Paint()..color = skin);

    final headSide = Path()
      ..moveTo(tx(60), ty(20))
      ..lineTo(tx(100), ty(20))
      ..lineTo(tx(110), ty(65))
      ..lineTo(tx(80), ty(110))
      ..lineTo(tx(60), ty(100))
      ..close();
    canvas.drawPath(headSide, Paint()..color = skinShade.withOpacity(0.6));

    final chin = Path()
      ..moveTo(tx(30), ty(85))
      ..lineTo(tx(90), ty(85))
      ..lineTo(tx(75), ty(115))
      ..lineTo(tx(45), ty(115))
      ..close();
    canvas.drawPath(chin, Paint()..color = skinHighlight);

    final hairTop = Path()
      ..moveTo(tx(10), ty(35))
      ..lineTo(tx(105), ty(35))
      ..lineTo(tx(95), ty(5))
      ..lineTo(tx(60), ty(0))
      ..lineTo(tx(25), ty(12))
      ..close();
    canvas.drawPath(hairTop, Paint()..color = hair);

    final hairSide = Path()
      ..moveTo(tx(105), ty(35))
      ..lineTo(tx(120), ty(60))
      ..lineTo(tx(95), ty(95))
      ..lineTo(tx(85), ty(60))
      ..close();
    canvas.drawPath(hairSide, Paint()..color = hairShade);

    final hairHighlightPath = Path()
      ..moveTo(tx(30), ty(18))
      ..lineTo(tx(70), ty(5))
      ..lineTo(tx(85), ty(25))
      ..lineTo(tx(50), ty(30))
      ..close();
    canvas.drawPath(hairHighlightPath, Paint()..color = hairHighlight);

    final leftEar = Path()
      ..moveTo(tx(5), ty(50))
      ..lineTo(tx(15), ty(40))
      ..lineTo(tx(18), ty(70))
      ..lineTo(tx(10), ty(80))
      ..close();
    canvas.drawPath(leftEar, Paint()..color = skin);
    canvas.drawPath(
      Path()
        ..moveTo(tx(12), ty(55))
        ..lineTo(tx(16), ty(50))
        ..lineTo(tx(18), ty(65))
        ..lineTo(tx(12), ty(70))
        ..close(),
      Paint()..color = skinHighlight,
    );

    final rightEar = Path()
      ..moveTo(tx(105), ty(40))
      ..lineTo(tx(115), ty(50))
      ..lineTo(tx(112), ty(80))
      ..lineTo(tx(100), ty(70))
      ..close();
    canvas.drawPath(rightEar, Paint()..color = skinShade);

    final cheekPaint = Paint()..color = look.accentColor.withOpacity(0.25);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(tx(35), ty(75)), width: 18 * scale, height: 12 * scale),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(tx(85), ty(75)), width: 18 * scale, height: 12 * scale),
      cheekPaint,
    );

    final eyeColor = Colors.black87;
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(center: Offset(tx(40), ty(60)), width: 18 * scale, height: 10 * scale),
        5 * scale,
        5 * scale,
      ),
      Paint()..color = eyeColor,
    );
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(center: Offset(tx(78), ty(60)), width: 18 * scale, height: 10 * scale),
        5 * scale,
        5 * scale,
      ),
      Paint()..color = eyeColor,
    );

    canvas.drawCircle(Offset(tx(46), ty(56)), 3 * scale, Paint()..color = Colors.white70);
    canvas.drawCircle(Offset(tx(84), ty(56)), 3 * scale, Paint()..color = Colors.white70);

    final browPaint = Paint()
      ..color = hairShade
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(tx(28), ty(48)), Offset(tx(48), ty(44)), browPaint);
    canvas.drawLine(Offset(tx(70), ty(44)), Offset(tx(90), ty(48)), browPaint);

    final nose = Path()
      ..moveTo(tx(56), ty(70))
      ..lineTo(tx(62), ty(82))
      ..lineTo(tx(54), ty(82))
      ..close();
    canvas.drawPath(nose, Paint()..color = skinShade.withOpacity(0.8));

    final mouth = Path()
      ..moveTo(tx(40), ty(90))
      ..quadraticBezierTo(tx(60), ty(98), tx(80), ty(90))
      ..lineTo(tx(80), ty(94))
      ..quadraticBezierTo(tx(60), ty(102), tx(40), ty(94))
      ..close();
    canvas.drawPath(mouth, Paint()..color = Colors.black.withOpacity(0.6));

    final lipShine = Path()
      ..moveTo(tx(45), ty(92))
      ..quadraticBezierTo(tx(60), ty(96), tx(75), ty(92))
      ..lineTo(tx(75), ty(94))
      ..quadraticBezierTo(tx(60), ty(98), tx(45), ty(94))
      ..close();
    canvas.drawPath(lipShine, Paint()..color = Colors.black.withOpacity(0.25));

    final seamPaint = Paint()
      ..color = shirtHighlight
      ..strokeWidth = 2 * scale;
    canvas.drawLine(Offset(tx(50), ty(118)), Offset(tx(70), ty(118)), seamPaint);
  }

  @override
  bool shouldRepaint(covariant CharacterFacePainter oldDelegate) =>
      oldDelegate.look != look;
}

class CharacterBackgroundPainter extends CustomPainter {
  final CharacterLook look;

  CharacterBackgroundPainter(this.look);

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lighten(look.primaryColor, 0.3),
          Colors.white,
          lighten(look.accentColor, 0.25),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    final sunRect = Rect.fromCircle(
      center: Offset(size.width * 0.18, size.height * 0.2),
      radius: size.width * 0.25,
    );
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.85),
          lighten(look.accentColor, 0.35).withOpacity(0.25),
          Colors.transparent,
        ],
      ).createShader(sunRect);
    canvas.drawCircle(sunRect.center, sunRect.width / 2, sunPaint);

    final hillPaint = Paint()..color = look.accentColor.withOpacity(0.12);
    final hillPath = Path()
      ..moveTo(0, size.height * 0.74)
      ..quadraticBezierTo(
          size.width * 0.2, size.height * 0.6, size.width * 0.45, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.7, size.height * 0.92, size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    final dotsPaint = Paint()..color = look.accentColor.withOpacity(0.18);
    for (int i = 0; i < 12; i++) {
      final dx = (i.isEven ? size.width * 0.15 : size.width * 0.33) + i * 20;
      final dy = size.height * 0.15 + (i % 4) * 30;
      canvas.drawCircle(Offset(dx % size.width, dy), 6, dotsPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CharacterBackgroundPainter oldDelegate) =>
      oldDelegate.look != look;
}

class CharacterScenePainter extends CustomPainter {
  final CharacterLook look;

  CharacterScenePainter(this.look);

  @override
  void paint(Canvas canvas, Size size) {
    const double figureWidth = 220;
    const double figureHeight = 420;

    double scale = size.width / figureWidth;
    double scaledHeight = figureHeight * scale;
    if (scaledHeight > size.height) {
      scale = size.height / figureHeight;
      scaledHeight = size.height;
    }
    final double actualWidth = figureWidth * scale;
    final double originX = (size.width - actualWidth) / 2;
    final double originY = size.height - scaledHeight;

    double tx(double x) => originX + x * scale;
    double ty(double y) => originY + y * scale;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, ty(figureHeight) - 5 * scale),
        width: actualWidth * 0.8,
        height: 20 * scale,
      ),
      Paint()..color = Colors.black.withOpacity(0.1),
    );

    final skin = look.skinColor;
    final skinShade = darken(skin, 0.12);
    final skinHighlight = lighten(skin, 0.08);
    final hair = look.hairColor;
    final hairShade = darken(hair, 0.1);
    final hairHighlight = lighten(hair, 0.08);
    final shirt = look.outfitColor;
    final shirtShade = darken(shirt, 0.18);
    final shirtHighlight = lighten(shirt, 0.12);
    final pants = darken(look.outfitColor, 0.45);
    final pantsShade = darken(pants, 0.15);
    final pantsHighlight = lighten(pants, 0.12);
    final shoeColor = darken(pants, 0.3);

    // Torso front
    final torso = Path()
      ..moveTo(tx(40), ty(180))
      ..lineTo(tx(180), ty(180))
      ..lineTo(tx(165), ty(290))
      ..lineTo(tx(55), ty(290))
      ..close();
    canvas.drawPath(torso, Paint()..color = shirt);

    // Torso right side
    final torsoSide = Path()
      ..moveTo(tx(180), ty(180))
      ..lineTo(tx(200), ty(205))
      ..lineTo(tx(185), ty(300))
      ..lineTo(tx(165), ty(290))
      ..close();
    canvas.drawPath(torsoSide, Paint()..color = shirtShade);

    // Torso highlight
    final torsoHighlight = Path()
      ..moveTo(tx(55), ty(290))
      ..lineTo(tx(165), ty(290))
      ..lineTo(tx(155), ty(315))
      ..lineTo(tx(65), ty(315))
      ..close();
    canvas.drawPath(torsoHighlight, Paint()..color = shirtHighlight);

    final torsoCenter = Path()
      ..moveTo(tx(110), ty(190))
      ..lineTo(tx(118), ty(300))
      ..lineTo(tx(102), ty(300))
      ..lineTo(tx(95), ty(190))
      ..close();
    canvas.drawPath(torsoCenter, Paint()..color = shirtShade.withOpacity(0.4));

    final leftShoulder = Path()
      ..moveTo(tx(40), ty(180))
      ..lineTo(tx(70), ty(200))
      ..lineTo(tx(60), ty(230))
      ..lineTo(tx(30), ty(205))
      ..close();
    canvas.drawPath(leftShoulder, Paint()..color = shirtHighlight.withOpacity(0.8));

    final rightShoulder = Path()
      ..moveTo(tx(150), ty(200))
      ..lineTo(tx(180), ty(180))
      ..lineTo(tx(190), ty(205))
      ..lineTo(tx(165), ty(230))
      ..close();
    canvas.drawPath(rightShoulder, Paint()..color = shirtShade.withOpacity(0.7));

    // Arms
    final leftArm = Path()
      ..moveTo(tx(35), ty(185))
      ..lineTo(tx(15), ty(275))
      ..lineTo(tx(40), ty(300))
      ..lineTo(tx(55), ty(210))
      ..close();
    canvas.drawPath(leftArm, Paint()..color = shirtShade);

    final rightArm = Path()
      ..moveTo(tx(185), ty(185))
      ..lineTo(tx(210), ty(210))
      ..lineTo(tx(195), ty(300))
      ..lineTo(tx(170), ty(275))
      ..close();
    canvas.drawPath(rightArm, Paint()..color = shirtHighlight);

    final leftHand = Path()
      ..moveTo(tx(18), ty(275))
      ..lineTo(tx(5), ty(320))
      ..lineTo(tx(30), ty(330))
      ..lineTo(tx(40), ty(300))
      ..close();
    canvas.drawPath(leftHand, Paint()..color = skin);

    final rightHand = Path()
      ..moveTo(tx(195), ty(300))
      ..lineTo(tx(185), ty(330))
      ..lineTo(tx(210), ty(320))
      ..lineTo(tx(200), ty(285))
      ..close();
    canvas.drawPath(rightHand, Paint()..color = skinShade);

    // Belt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tx(50), ty(300), tx(150 - 50), 12 * scale),
        Radius.circular(6 * scale),
      ),
      Paint()..color = darken(pants, 0.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(tx(110), ty(306)),
          width: 50 * scale,
          height: 14 * scale,
        ),
        Radius.circular(4 * scale),
      ),
      Paint()..color = lighten(pants, 0.2),
    );

    // Legs
    final leftLeg = Path()
      ..moveTo(tx(70), ty(312))
      ..lineTo(tx(105), ty(312))
      ..lineTo(tx(95), ty(430))
      ..lineTo(tx(60), ty(430))
      ..close();
    canvas.drawPath(leftLeg, Paint()..color = pantsHighlight);

    final leftLegSide = Path()
      ..moveTo(tx(105), ty(312))
      ..lineTo(tx(118), ty(330))
      ..lineTo(tx(108), ty(430))
      ..lineTo(tx(95), ty(430))
      ..close();
    canvas.drawPath(leftLegSide, Paint()..color = pantsShade.withOpacity(0.7));

    final rightLeg = Path()
      ..moveTo(tx(115), ty(312))
      ..lineTo(tx(150), ty(312))
      ..lineTo(tx(160), ty(430))
      ..lineTo(tx(125), ty(430))
      ..close();
    canvas.drawPath(rightLeg, Paint()..color = pantsShade);

    final rightLegHighlight = Path()
      ..moveTo(tx(115), ty(312))
      ..lineTo(tx(135), ty(312))
      ..lineTo(tx(140), ty(430))
      ..lineTo(tx(122), ty(430))
      ..close();
    canvas.drawPath(rightLegHighlight, Paint()..color = pantsHighlight.withOpacity(0.6));

    final leftCuff = Path()
      ..moveTo(tx(60), ty(400))
      ..lineTo(tx(95), ty(400))
      ..lineTo(tx(92), ty(410))
      ..lineTo(tx(63), ty(410))
      ..close();
    canvas.drawPath(leftCuff, Paint()..color = lighten(pantsHighlight, 0.2));

    final rightCuff = Path()
      ..moveTo(tx(125), ty(400))
      ..lineTo(tx(160), ty(400))
      ..lineTo(tx(157), ty(410))
      ..lineTo(tx(128), ty(410))
      ..close();
    canvas.drawPath(rightCuff, Paint()..color = lighten(pantsShade, 0.15));

    // Shoes
    final leftShoe = Path()
      ..moveTo(tx(55), ty(430))
      ..lineTo(tx(98), ty(430))
      ..lineTo(tx(110), ty(450))
      ..lineTo(tx(45), ty(450))
      ..close();
    canvas.drawPath(leftShoe, Paint()..color = shoeColor);
    canvas.drawRect(
      Rect.fromLTWH(tx(45), ty(448), 65 * scale, 5 * scale),
      Paint()..color = darken(shoeColor, 0.1),
    );

    final rightShoe = Path()
      ..moveTo(tx(120), ty(430))
      ..lineTo(tx(165), ty(430))
      ..lineTo(tx(175), ty(450))
      ..lineTo(tx(110), ty(450))
      ..close();
    canvas.drawPath(rightShoe, Paint()..color = darken(shoeColor, 0.1));
    canvas.drawRect(
      Rect.fromLTWH(tx(110), ty(448), 65 * scale, 5 * scale),
      Paint()..color = darken(shoeColor, 0.2),
    );

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tx(95), ty(150), 30 * scale, 35 * scale),
        Radius.circular(8 * scale),
      ),
      Paint()..color = skinShade,
    );

    // Head
    final head = Path()
      ..moveTo(tx(50), ty(60))
      ..lineTo(tx(160), ty(60))
      ..lineTo(tx(185), ty(150))
      ..lineTo(tx(135), ty(215))
      ..lineTo(tx(75), ty(215))
      ..lineTo(tx(25), ty(150))
      ..close();
    canvas.drawPath(head, Paint()..color = skin);

    final headShadow = Path()
      ..moveTo(tx(110), ty(60))
      ..lineTo(tx(160), ty(60))
      ..lineTo(tx(185), ty(150))
      ..lineTo(tx(135), ty(215))
      ..lineTo(tx(110), ty(205))
      ..close();
    canvas.drawPath(headShadow, Paint()..color = skinShade.withOpacity(0.5));

    final chin = Path()
      ..moveTo(tx(70), ty(205))
      ..lineTo(tx(135), ty(205))
      ..lineTo(tx(112), ty(235))
      ..lineTo(tx(93), ty(235))
      ..close();
    canvas.drawPath(chin, Paint()..color = skinHighlight);

    // Hair layers
    final hairFront = Path()
      ..moveTo(tx(35), ty(70))
      ..lineTo(tx(170), ty(70))
      ..lineTo(tx(150), ty(30))
      ..lineTo(tx(95), ty(15))
      ..lineTo(tx(45), ty(35))
      ..close();
    canvas.drawPath(hairFront, Paint()..color = hair);

    final hairSide = Path()
      ..moveTo(tx(170), ty(70))
      ..lineTo(tx(195), ty(110))
      ..lineTo(tx(170), ty(150))
      ..lineTo(tx(150), ty(90))
      ..close();
    canvas.drawPath(hairSide, Paint()..color = hairShade);

    final hairTop = Path()
      ..moveTo(tx(60), ty(30))
      ..lineTo(tx(115), ty(0))
      ..lineTo(tx(150), ty(20))
      ..lineTo(tx(110), ty(45))
      ..close();
    canvas.drawPath(hairTop, Paint()..color = hairHighlight);

    // Eyes
    final eyePaint = Paint()..color = Colors.black87;
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(center: Offset(tx(85), ty(140)), width: 22 * scale, height: 14 * scale),
        6 * scale,
        6 * scale,
      ),
      eyePaint,
    );
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(center: Offset(tx(135), ty(140)), width: 22 * scale, height: 14 * scale),
        6 * scale,
        6 * scale,
      ),
      eyePaint,
    );

    // Brows
    final browPaint = Paint()
      ..color = hairShade
      ..strokeWidth = 6 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(tx(70), ty(125)), Offset(tx(100), ty(118)), browPaint);
    canvas.drawLine(Offset(tx(120), ty(118)), Offset(tx(150), ty(125)), browPaint);

    // Nose
    final nose = Path()
      ..moveTo(tx(110), ty(150))
      ..lineTo(tx(105), ty(170))
      ..lineTo(tx(115), ty(170))
      ..close();
    canvas.drawPath(nose, Paint()..color = skinShade.withOpacity(0.8));

    // Mouth
    final mouth = Path()
      ..moveTo(tx(85), ty(190))
      ..quadraticBezierTo(tx(110), ty(205), tx(135), ty(190))
      ..lineTo(tx(135), ty(195))
      ..quadraticBezierTo(tx(110), ty(210), tx(85), ty(195))
      ..close();
    canvas.drawPath(mouth, Paint()..color = Colors.black.withOpacity(0.6));

    // Cheeks
    final cheekPaint = Paint()..color = look.accentColor.withOpacity(0.25);
    canvas.drawOval(Rect.fromCenter(center: Offset(tx(75), ty(165)), width: 25 * scale, height: 18 * scale), cheekPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(tx(145), ty(165)), width: 25 * scale, height: 18 * scale), cheekPaint);

    // Shoulder dots
    final shoulderFacetLeft = Path()
      ..moveTo(tx(45), ty(195))
      ..lineTo(tx(60), ty(210))
      ..lineTo(tx(40), ty(218))
      ..close();
    canvas.drawPath(shoulderFacetLeft, Paint()..color = shirtHighlight.withOpacity(0.7));

    final shoulderFacetRight = Path()
      ..moveTo(tx(165), ty(210))
      ..lineTo(tx(185), ty(195))
      ..lineTo(tx(180), ty(218))
      ..close();
    canvas.drawPath(shoulderFacetRight, Paint()..color = shirtShade.withOpacity(0.6));
  }

  @override
  bool shouldRepaint(covariant CharacterScenePainter oldDelegate) =>
      oldDelegate.look != look;
}
