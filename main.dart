import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';


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
      home: const AgeScreen(),
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
  final shortCode = cleanLang.length >= 2
      ? cleanLang.substring(0, 2).toUpperCase()
      : cleanLang.toUpperCase();
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
  final lighter = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return lighter.toColor();
}

Color darken(Color color, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(color);
  final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return darker.toColor();
}

const Color kFairSkin = Color(0xFFFFF6E8);

// ============ ONBOARDING ============

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  double _age = 24;

  void _continue() {
    final age = _age.round();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GenderScreen(userAge: age)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFE0F7FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Сколько вам лет?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Укажите возраст ползунком — так быстрее и удобнее.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Возраст',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => setState(
                                  () => _age = (_age - 1).clamp(5, 80),
                                ),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_age.round()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(
                                  () => _age = (_age + 1).clamp(5, 80),
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: _age,
                        min: 5,
                        max: 80,
                        divisions: 75,
                        label: '${_age.round()}',
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (v) => setState(() => _age = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [Text('5'), Text('80')],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    CharacterAvatar(
                      look: characterLookFor('English', 'female'),
                      size: 70,
                    ),
                    const SizedBox(width: 12),
                    CharacterAvatar(
                      look: characterLookFor('Spanish', 'male'),
                      size: 70,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: _continue,
                        child: const Text('Далее'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GenderScreen extends StatefulWidget {
  final int userAge;
  const GenderScreen({super.key, required this.userAge});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String _gender = 'unspecified';

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatListScreen(userAge: widget.userAge, userGender: _gender),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFDE7F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Укажите ваш пол',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Возраст: ${widget.userAge} • Это поможет подобрать обращение.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выбор',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _genderTile(
                            label: 'Не важно',
                            value: 'unspecified',
                            icon: Icons.all_inclusive,
                            color: Colors.grey.shade600,
                          ),
                          _genderTile(
                            label: 'Мужской',
                            value: 'male',
                            icon: Icons.male,
                            color: const Color(0xFF1E88E5),
                          ),
                          _genderTile(
                            label: 'Женский',
                            value: 'female',
                            icon: Icons.female,
                            color: const Color(0xFFD81B60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    CharacterAvatar(
                      look: characterLookFor('German', 'male'),
                      size: 70,
                    ),
                    const SizedBox(width: 12),
                    CharacterAvatar(
                      look: characterLookFor('French', 'female'),
                      size: 70,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: _continue,
                        child: const Text('Далее'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final selected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ ЧАТЫ ============

class ChatListScreen extends StatelessWidget {
  final int userAge;
  final String userGender;

  const ChatListScreen({
    super.key,
    required this.userAge,
    required this.userGender,
  });

  @override
  Widget build(BuildContext context) {
    final chats = [
      {
        'name': 'Emily',
        'language': 'English',
        'partnerGender': 'female',
        'color': const Color(0xFF6C63FF),
      },
      {
        'name': 'Hans',
        'language': 'German',
        'partnerGender': 'male',
        'color': const Color(0xFF00BFA6),
      },
      {
        'name': 'Marie',
        'language': 'French',
        'partnerGender': 'female',
        'color': const Color(0xFFFF6584),
      },
      {
        'name': 'Sofia',
        'language': 'Spanish',
        'partnerGender': 'female',
        'color': const Color(0xFFFFB300),
      },
      {
        'name': 'Luca',
        'language': 'Italian',
        'partnerGender': 'male',
        'color': const Color(0xFF29B6F6),
      },
      {
        'name': 'Kim',
        'language': 'Korean',
        'partnerGender': 'female',
        'color': const Color(0xFF8E24AA),
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Диалоги'), centerTitle: true),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final chat = chats[i];
                final name = chat['name'] as String;
                final lang = chat['language'] as String;
                final partnerGender = chat['partnerGender'] as String;
                final color = chat['color'] as Color;
                final look = characterLookFor(lang, partnerGender);

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final level = await _pickLevel(context);
                      if (level == null) return;
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            language: lang,
                            level: level,
                            topic: 'General conversation',
                            userGender: userGender,
                            userAge: userAge,
                            partnerGender: partnerGender,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: CharacterAvatar(look: look, size: 48),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$name ($lang)',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Нажмите чтобы начать диалог',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5F7FB), Color(0xFFE8EAF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Выберите чат слева',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickLevel(BuildContext context) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите уровень языка'),
        children: [
          for (final lvl in levels)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(lvl),
              child: Text(lvl),
            ),
        ],
      ),
    );
  }
}

// ============ CHAT SCREEN ============

class LoopingPngAnimation extends StatefulWidget {
  final List<String> frames; // список путей к кадрам
  final Duration frameDuration; // длительность одного кадра
  final BoxFit fit;

  const LoopingPngAnimation({
    super.key,
    required this.frames,
    this.frameDuration = const Duration(milliseconds: 80),
    this.fit = BoxFit.contain,
  });

  @override
  State<LoopingPngAnimation> createState() => _LoopingPngAnimationState();
}

class _LoopingPngAnimationState extends State<LoopingPngAnimation> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();

    if (widget.frames.isEmpty) return;

    _timer = Timer.periodic(widget.frameDuration, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.frames.length;
      });
    });
  }

  @override
  void didUpdateWidget(covariant LoopingPngAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frames != widget.frames) {
      _index = 0;
      _timer?.cancel();

      if (widget.frames.isNotEmpty) {
        _timer = Timer.periodic(widget.frameDuration, (_) {
          if (!mounted) return;
          setState(() {
            _index = (_index + 1) % widget.frames.length;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Image.asset(
      widget.frames[_index],
      fit: widget.fit,
      gaplessPlayback: true, // важно: без мерцания при смене кадров
    );
  }
}

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

  // плеер для озвучки слов
  late final AudioPlayer _audioPlayer;
  late final List<String> _characterFrames;

  
  // рекордер для голосового ввода
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void dispose() {
    _inputController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }


  // прогресс по словам пользователя
  int _userWordCount = 0;
  int _currentLevel = 1;
  final List<int> _levelTargets = [50, 150, 300, 500, 1000];

  CharacterLook get _characterLook =>
      characterLookFor(widget.language, widget.partnerGender);
  List<String> _buildCharacterFrames() {
    final folder = switch (widget.language) {
      'French' => 'french',
      'German' => 'german',
      'Italian' => 'italian',
      'Korean' => 'korean',
      'Spanish' => 'spanish',
      _ => 'default',
    };

    final frameCount = (folder == 'default') ? 450 : 419;

    return List.generate(frameCount, (i) {
      final n = i + 1; // 1..frameCount
      final name = n.toString().padLeft(4, '0'); // "0001"
      return 'assets/anim/$folder/$name.png';
    });
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _characterFrames = _buildCharacterFrames();
    _startConversation();
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
      final uri = Uri.parse('http://144.172.116.101:8000/chat');

      final messagesPayload = initial
          ? []
          : _messages
                .where(
                  (m) => !m.isCorrections,
                ) // в историю не отправляем сообщения с ошибками
                .map((m) => {'role': m.role, 'content': m.text})
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
            _messages.add(
              ChatMessage(
                role: 'assistant',
                text: correctionsText.trim(),
                isCorrections: true,
              ),
            );
          }
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              text:
                  'System: error ${resp.statusCode} from server. Please try again.',
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(role: 'assistant', text: 'System: connection error: $e'),
        );
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _startRecording() async {
    final hasPerm = await _audioRecorder.hasPermission();
    debugPrint('STT: hasPermission = $hasPerm');
    if (!hasPerm) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/input_${DateTime.now().millisecondsSinceEpoch}.wav';

    final config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );

    await _audioRecorder.start(config, path: path);

  // 🟣 КРИТИЧЕСКОЕ ДОПОЛНЕНИЕ ДЛЯ macOS !!!
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      _isRecording = true;
    });
  }




  Future<void> _stopRecordingAndSend() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final path = await _audioRecorder.stop(); // вернёт путь к файлу
    setState(() {
      _isRecording = false;
    });

    if (path == null) {
      debugPrint('STT: stop() returned null path');
      return;
    }

    debugPrint('STT: recorded file = $path');



    // После прослушивания отправляем на backend
    await _sendAudioToBackend(File(path));
  }


    String _languageCodeFromName(String language) {
    switch (language) {
      case 'English':
        return 'en';
      case 'German':
        return 'de';
      case 'French':
        return 'fr';
      case 'Spanish':
        return 'es';
      case 'Italian':
        return 'it';
      case 'Korean':
        return 'ko';
      case 'Russian':
        return 'ru';
      default:
        return 'en';
    }
  }


  Future<void> _sendAudioToBackend(File file) async {
    final langCode = _languageCodeFromName(widget.language);

    final uri = Uri.parse(
      'http://144.172.116.101:8000/stt?language_code=$langCode',
    );

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

    try {
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        final recognized = (jsonMap['text'] ?? '') as String;

        if (!mounted) return;
        setState(() {
          _inputController.text = recognized;
        });

        // Если хочешь сразу отправлять после распознавания:
        // await _sendUserMessage();
      } else {
        print('STT error: ${streamed.statusCode} $body');
      }
    } catch (e) {
      print('STT exception: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndSend();
    } else {
      await _startRecording();
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
              'Great! You finished level ${_currentLevel - 1}. Level $_currentLevel unlocked!',
            ),
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${word.word} добавлено в словарь')));
  }

  void _removeSavedWord(String word) {
    if (!_isWordSaved(word)) return;

    setState(() {
      _savedWords.removeWhere(
        (entry) => entry.word.toLowerCase() == word.toLowerCase(),
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$word удалено из словаря')));
  }

  // ------ перевод слова по нажатию ------

  Future<void> _onWordTap(String rawWord) async {
    // убираем пунктуацию по краям
    final word = rawWord.replaceAll(
      RegExp(r"[^\p{Letter}']", unicode: true),
      '',
    );
    if (word.isEmpty) return;

    try {
      final uri = Uri.parse('http://144.172.116.101:8000/translate-word');

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

      // ---------- АУДИО: base64 -> байты -> временный mp3 ----------
      final audioBase64 = data['audio_base64'] as String?;
      String? audioFilePath;

      if (audioBase64 != null && audioBase64.isNotEmpty) {
        try {
          // 1) декодируем base64
          final Uint8List audioBytes = base64Decode(audioBase64);
          debugPrint('AUDIO BYTES LENGTH: ${audioBytes.length}');

          // 2) получаем и создаём (на всякий случай) временную папку
          final tempDir = await getTemporaryDirectory();
          await Directory(
            tempDir.path,
          ).create(recursive: true); // ← важная строка

          // 3) создаём файл внутри этой папки
          final file = File(
            '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
          );

          // 4) пишем байты в файл
          await file.writeAsBytes(audioBytes, flush: true);
          audioFilePath = file.path;
          debugPrint('AUDIO FILE PATH: $audioFilePath');
        } catch (e) {
          debugPrint('ERROR while decoding/writing audio: $e');
          audioFilePath = null;
        }
      }

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
                  // 🔊 КНОПКА ОЗВУЧКИ
                  if (audioFilePath != null)
                    IconButton(
                      tooltip: 'Произнести слово',
                      icon: const Icon(Icons.volume_up),
                      onPressed: () async {
                        try {
                          await _audioPlayer.stop();
                          await _audioPlayer.play(
                            DeviceFileSource(audioFilePath!),
                          );
                        } catch (e) {
                          debugPrint('AUDIO PLAY ERROR: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Не удалось воспроизвести аудио'),
                            ),
                          );
                        }
                      },
                    ),
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
      debugPrint('TRANSLATE ERROR: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Translation error: $e')));
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
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
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
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
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
          Expanded(
            flex: 1, // можно 2, 3, 4 — чем больше, тем шире правая часть
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
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: CharacterBackgroundPainter(look)),
            ),

            // Анимация теперь занимает ВСЮ правую панель
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(
                  8,
                ), // маленький отступ, чтобы не липло к краям
                child: LoopingPngAnimation(
                  frames: _characterFrames,
                  frameDuration: const Duration(milliseconds: 80),
                  fit: BoxFit
                      .cover, // если хочешь прям во весь рост с обрезкой — поставь cover
                ),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
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
              Text('Пример:', style: Theme.of(context).textTheme.labelMedium),
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
          // Кнопка микрофона
          IconButton(
            icon: Icon(_isRecording ? Icons.mic : Icons.mic_none),
            color: _isRecording
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
            onPressed: _isSending ? null : _toggleRecording,
          ),
          const SizedBox(width: 4),
          // Кнопка отправки текста
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
          CharacterAvatar(look: look, size: 56),
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
      child: CustomPaint(painter: CharacterFacePainter(look)),
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
      Rect.fromCenter(
        center: Offset(tx(35), ty(75)),
        width: 18 * scale,
        height: 12 * scale,
      ),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(tx(85), ty(75)),
        width: 18 * scale,
        height: 12 * scale,
      ),
      cheekPaint,
    );

    final eyeColor = Colors.black87;
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(
          center: Offset(tx(40), ty(60)),
          width: 18 * scale,
          height: 10 * scale,
        ),
        5 * scale,
        5 * scale,
      ),
      Paint()..color = eyeColor,
    );
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(
          center: Offset(tx(78), ty(60)),
          width: 18 * scale,
          height: 10 * scale,
        ),
        5 * scale,
        5 * scale,
      ),
      Paint()..color = eyeColor,
    );

    canvas.drawCircle(
      Offset(tx(46), ty(56)),
      3 * scale,
      Paint()..color = Colors.white70,
    );
    canvas.drawCircle(
      Offset(tx(84), ty(56)),
      3 * scale,
      Paint()..color = Colors.white70,
    );

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
    canvas.drawLine(
      Offset(tx(50), ty(118)),
      Offset(tx(70), ty(118)),
      seamPaint,
    );
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
        size.width * 0.2,
        size.height * 0.6,
        size.width * 0.45,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.92,
        size.width,
        size.height * 0.78,
      )
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
