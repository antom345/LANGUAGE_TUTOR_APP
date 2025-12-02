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


class LessonPlan {
  final String id;
  final String title;
  final String type;
  final String description;

  LessonPlan({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
  });

  factory LessonPlan.fromJson(Map<String, dynamic> json) {
    return LessonPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
    );
  }
}

class LessonExercise {
  final String id;

  /// multiple_choice / translate_sentence / fill_in_blank / reorder_words
  final String type;

  /// Общий текст вопроса / задания
  final String? instruction;
  final String question;

  /// Объяснение после проверки
  final String explanation;

  /// Только для multiple_choice
  final List<String>? options;
  final int? correctIndex;

  /// Для translate_sentence и fill_in_blank
  final String? correctAnswer;
  final String? sentenceWithGap;

  /// Для reorder_words
  final List<String>? reorderWords;
  final List<String>? reorderCorrect;

  LessonExercise({
    required this.id,
    required this.type,
    required this.question,
    required this.explanation,
    this.instruction,
    this.options,
    this.correctIndex,
    this.correctAnswer,
    this.sentenceWithGap,
    this.reorderWords,
    this.reorderCorrect,
  });

  factory LessonExercise.fromJson(Map<String, dynamic> json) {
    return LessonExercise(
      id: json['id'] as String,
      type: json['type'] as String,
      question: json['question'] as String,
      explanation: json['explanation'] as String,
      instruction: json['instruction'] as String?,
      options: (json['options'] as List?)?.cast<String>(),
      correctIndex: json['correct_index'] as int?,
      correctAnswer: json['correct_answer'] as String?,
      sentenceWithGap: json['sentence_with_gap'] as String?,
      reorderWords: (json['reorder_words'] as List?)?.cast<String>(),
      reorderCorrect: (json['reorder_correct'] as List?)?.cast<String>(),
    );
  }
}



class LessonContentModel {
  final String lessonId;
  final String lessonTitle;
  final String description;
  final List<LessonExercise> exercises;

  LessonContentModel({
    required this.lessonId,
    required this.lessonTitle,
    required this.description,
    required this.exercises,
  });

  factory LessonContentModel.fromJson(Map<String, dynamic> json) {
    final exList = (json['exercises'] as List).cast<Map<String, dynamic>>();
    return LessonContentModel(
      lessonId: json['lesson_id'] as String,
      lessonTitle: json['lesson_title'] as String,
      description: json['description'] as String,
      exercises: exList.map((e) => LessonExercise.fromJson(e)).toList(),
    );
  }
}


class CourseLevelPlan {
  final int levelIndex;
  final String title;
  final String description;
  final List<String> targetGrammar;
  final List<String> targetVocab;
  final List<LessonPlan> lessons;

  CourseLevelPlan({
    required this.levelIndex,
    required this.title,
    required this.description,
    required this.targetGrammar,
    required this.targetVocab,
    required this.lessons,
  });

  factory CourseLevelPlan.fromJson(Map<String, dynamic> json) {
    final grammar = (json['target_grammar'] as List).cast<String>();
    final vocab = (json['target_vocab'] as List).cast<String>();
    final lessonsJson = (json['lessons'] as List).cast<Map<String, dynamic>>();

    return CourseLevelPlan(
      levelIndex: json['level_index'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      targetGrammar: grammar,
      targetVocab: vocab,
      lessons: lessonsJson.map((e) => LessonPlan.fromJson(e)).toList(),
    );
  }
}

class CoursePlan {
  final String language;
  final String overallLevel;
  final List<CourseLevelPlan> levels;

  CoursePlan({
    required this.language,
    required this.overallLevel,
    required this.levels,
  });

  factory CoursePlan.fromJson(Map<String, dynamic> json) {
    final levelsJson = (json['levels'] as List).cast<Map<String, dynamic>>();
    return CoursePlan(
      language: json['language'] as String,
      overallLevel: json['overall_level'] as String,
      levels: levelsJson.map((e) => CourseLevelPlan.fromJson(e)).toList(),
    );
  }
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
          gradient: RadialGradient(
            colors: [
              Color(0xFFEFF3FF),
              Color(0xFFE9F7F5),
              Color(0xFFFDF1FF),
            ],
            center: Alignment(-0.6, -0.6),
            radius: 1.2,
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
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF7FAFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
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
                    Expanded(child: _languageAvatarStrip()),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 160,
                      child: PrimaryCtaButton(label: 'Далее', onTap: _continue),
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

  Widget _languageAvatarStrip() {
    final samples = [
      characterLookFor('English', 'female'),
      characterLookFor('German', 'male'),
      characterLookFor('French', 'female'),
      characterLookFor('Spanish', 'male'),
      characterLookFor('Italian', 'male'),
      characterLookFor('Korean', 'female'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final look in samples)
          CharacterAvatar(
            look: look,
            size: 56,
          ),
      ],
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
          gradient: RadialGradient(
            colors: [
              Color(0xFFEAF4FF),
              Color(0xFFFDF2F8),
              Color(0xFFE7FFF9),
            ],
            center: Alignment(0.6, -0.6),
            radius: 1.1,
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
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF8FBFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
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
                    Expanded(child: _languageAvatarStrip()),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 160,
                      child: PrimaryCtaButton(label: 'Далее', onTap: _continue),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: 1.2,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
          ],
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

  Widget _languageAvatarStrip() {
    final samples = [
      characterLookFor('English', 'female'),
      characterLookFor('German', 'male'),
      characterLookFor('French', 'female'),
      characterLookFor('Spanish', 'female'),
      characterLookFor('Italian', 'male'),
      characterLookFor('Korean', 'female'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final look in samples)
          CharacterAvatar(
            look: look,
            size: 56,
          ),
      ],
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
    'name': 'Michael',
    'language': 'English',
    'partnerGender': 'male',
    'color': const Color(0xFF6C63FF),
  },
  {
    'name': 'Hans',
    'language': 'German',
    'partnerGender': 'male',
    'color': const Color(0xFF00BFA6),
  },
  {
    'name': 'Jack',
    'language': 'French',
    'partnerGender': 'male',
    'color': const Color(0xFFFF6584),
  },
  {
    'name': 'Pablo',
    'language': 'Spanish',
    'partnerGender': 'male',
    'color': const Color(0xFFFFB300),
  },
  {
    'name': 'Marco',
    'language': 'Italian',
    'partnerGender': 'male',
    'color': const Color(0xFF29B6F6),
  },
  {
    'name': 'Kim',
    'language': 'Korean',
    'partnerGender': 'male',
    'color': const Color(0xFF8E24AA),
  },
];


    return Scaffold(
      appBar: AppBar(title: const Text('Диалоги'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFFF2F5FF), Color(0xFFE8F7F4), Color(0xFFFDF2FF)],
            center: Alignment(-0.4, -0.2),
            radius: 1.4,
          ),
        ),
        child: Row(
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
                  final flag = _flagForLanguage(lang);

                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                    splashColor: color.withOpacity(0.12),
                    highlightColor: color.withOpacity(0.06),
                    onTap: () async {
                      final level = await _pickLevel(context);
                      if (level == null) return;
                      if (!context.mounted) return;

                      final chosenLevel =
                          await _offerPlacementChoice(context, lang, level);
                      if (!context.mounted) return;

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            language: lang,
                            level: chosenLevel,
                            topic: 'General conversation',
                            userGender: userGender,
                            userAge: userAge,
                            partnerGender: partnerGender,
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.12),
                              Colors.white.withOpacity(0.95),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _DialogAvatar(
                              look: look,
                              accent: color,
                              flag: flag,
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
                                    ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                              color: color.withOpacity(0.8),
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
                margin: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9FBFF), Color(0xFFE8EAF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
      ),
    );
  }

  String _flagForLanguage(String lang) {
    switch (lang) {
      case 'English':
        return '🇺🇸';
      case 'German':
        return '🇩🇪';
      case 'French':
        return '🇫🇷';
      case 'Spanish':
        return '🇪🇸';
      case 'Italian':
        return '🇮🇹';
      case 'Korean':
        return '🇰🇷';
      default:
        return '🏳️';
    }
  }

  Future<String?> _pickLevel(BuildContext context) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final accent = theme.colorScheme.primary;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.emoji_objects_outlined,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Выберите уровень языка',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          splashRadius: 20,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final lvl in levels)
                          _LevelChip(
                            label: lvl,
                            accent: accent,
                            onTap: () => Navigator.of(context).pop(lvl),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _offerPlacementChoice(
      BuildContext context, String language, String currentLevel) async {
    String? action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Хотите пройти короткий тест?'),
        content: const Text(
          'Это займет пару минут и поможет точнее подобрать курс. Можно пропустить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('skip'),
            child: const Text('Пропустить'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('test'),
            child: const Text('Пройти тест'),
          ),
        ],
      ),
    );

    if (action == 'test') {
      final testedLevel = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PlacementTestScreen(language: language),
        ),
      );
      return testedLevel ?? currentLevel;
    }

    return currentLevel;
  }
}

class _DialogAvatar extends StatelessWidget {
  final CharacterLook look;
  final Color accent;
  final String flag;

  const _DialogAvatar({
    required this.look,
    required this.accent,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.22), accent.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: CharacterAvatar(look: look, size: 52),
        ),
        Positioned(
          bottom: -6,
          left: -6,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              flag,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoursePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CoursePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: darken(color, 0.18)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: darken(color, 0.18),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatefulWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _LevelChip({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_LevelChip> createState() => _LevelChipState();
}

class _LevelChipState extends State<_LevelChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.accent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.accent.withOpacity(0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: darken(widget.accent, 0.24),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
  Timer? _recordingTimeoutTimer;
  DateTime? _recordingStartedAt;
  String? _currentRecordingPath;
  static const Duration _maxRecordingDuration = Duration(seconds: 20);
  static const Duration _minRecordingDuration = Duration(milliseconds: 700);
  static const int _minRecordingBytes = 2000;

  @override
  void dispose() {
    _inputController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _recordingTimeoutTimer?.cancel();
    super.dispose();
  }


  // прогресс по словам пользователя
  int _userWordCount = 0;
  int _currentLevel = 1;
  final List<int> _levelTargets = [50, 150, 300, 500, 1000];
  final Set<String> _completedLessons = {};
  final List<String> _userInterests = [];
  bool _interestsAsked = false;
  static const List<String> _interestOptions = [
    'Путешествия',
    'Работа / Карьера',
    'Учёба',
    'Фильмы и сериалы',
    'Музыка',
    'Спорт',
    'Технологии и IT',
    'Еда и кулинария',
    'Отношения и общение',
    'Игры',
  ];

    // план курса
  CoursePlan? _coursePlan;
  bool _isLoadingCourse = false;
  String? _courseError;


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

    final frameCount = (folder == 'default') ? 419 : 419;

    return List.generate(frameCount, (i) {
      final n = i + 1;
      final name = n.toString().padLeft(4, '0');
      return 'assets/anim/$folder/$name.webp';
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
          : (() {
              final items = _messages
                  .where((m) => !m.isCorrections)
                  .map((m) => {'role': m.role, 'content': m.text})
                  .toList();

              if (items.length <= 5) return items;
              return items.sublist(items.length - 5);
            })();

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

  Future<void> _ensureInterestsCollected() async {
    if (_userInterests.isNotEmpty || _interestsAsked) return;

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        final chosen = <String>{..._userInterests};
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Что вам интересно?'),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final interest in _interestOptions)
                      FilterChip(
                        label: Text(interest),
                        selected: chosen.contains(interest),
                        onSelected: (val) {
                          setStateDialog(() {
                            if (val) {
                              chosen.add(interest);
                            } else {
                              chosen.remove(interest);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(<String>[]),
                  child: const Text('Пропустить'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(chosen.toList()),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    setState(() {
      _interestsAsked = true;
      if (selected != null) {
        _userInterests
          ..clear()
          ..addAll(selected);
      }
    });
  }

Future<void> _loadCoursePlan({String? overrideLevelHint}) async {
  if (_isLoadingCourse || _coursePlan != null) return;

  setState(() {
    _isLoadingCourse = true;
    _courseError = null;
  });

  try {
    await _ensureInterestsCollected();

    final uri = Uri.parse('http://144.172.116.101:8000/generate_course_plan');

    final gender =
        widget.userGender == 'unspecified' ? null : widget.userGender;

    final body = jsonEncode({
      "language": widget.language,
      // если тест вернул уровень – используем его, иначе старый widget.level
      "level_hint": overrideLevelHint ?? widget.level,
      "age": widget.userAge,
      "gender": gender,
      "goals":
          "Improve ${widget.language} through conversation and vocabulary.",
      "interests": _userInterests,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _coursePlan = CoursePlan.fromJson(data);
      });
    } else {
      setState(() {
        _courseError = 'Server error: ${response.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      _courseError = 'Error: $e';
    });
  } finally {
    setState(() {
      _isLoadingCourse = false;
    });
  }
}



  Future<void> _startRecording() async {
    if (_isRecording || _isSending) return;

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

    _recordingStartedAt = DateTime.now();
    _currentRecordingPath = path;
    _recordingTimeoutTimer?.cancel();
    _recordingTimeoutTimer = Timer(_maxRecordingDuration, () {
      if (_isRecording) {
        debugPrint('STT: auto stopping after $_maxRecordingDuration');
        _stopRecordingAndSend(autoStop: true);
      }
    });

    setState(() {
      _isRecording = true;
    });
  }




  Future<void> _stopRecordingAndSend({bool autoStop = false}) async {
    if (!_isRecording) return;

    _recordingTimeoutTimer?.cancel();

    await Future.delayed(const Duration(milliseconds: 200));
    final startedAt = _recordingStartedAt;
    final pathFromRecorder = await _audioRecorder.stop(); // вернёт путь к файлу
    final path = pathFromRecorder ?? _currentRecordingPath;

    _recordingStartedAt = null;
    _currentRecordingPath = null;

    setState(() {
      _isRecording = false;
    });

    if (path == null) {
      debugPrint('STT: stop() returned null path');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      debugPrint('STT: recorded file does not exist');
      return;
    }

    final bytes = await file.length();
    final durationMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;

    final tooShortByTime =
        durationMs < _minRecordingDuration.inMilliseconds && !autoStop;
    final tooShortBySize = bytes < _minRecordingBytes;

    if (tooShortByTime || tooShortBySize) {
      debugPrint(
          'STT: skip sending audio (duration=${durationMs}ms, bytes=$bytes)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись слишком короткая — удерживайте дольше')),
        );
      }
    } else {
      debugPrint('STT: recorded file = $path (duration=${durationMs}ms)');
      await _sendAudioToBackend(file);
    }
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


  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordingTimeoutTimer?.cancel();
    _recordingStartedAt = null;
    _currentRecordingPath = null;
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });
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

  Future<String?> _saveAudioBase64(String audioBase64) async {
    try {
      final Uint8List audioBytes = base64Decode(audioBase64);
      debugPrint('AUDIO BYTES LENGTH: ${audioBytes.length}');

      final tempDir = await getTemporaryDirectory();
      await Directory(tempDir.path).create(recursive: true);

      final file = File(
        '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );

      await file.writeAsBytes(audioBytes, flush: true);
      debugPrint('AUDIO FILE PATH: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('ERROR while decoding/writing audio: $e');
      return null;
    }
  }

  Future<String?> _fetchWordAudio(String word) async {
    try {
      final uri = Uri.parse('http://144.172.116.101:8000/translate-word');
      final body = jsonEncode({
        'word': word,
        'language': widget.language,
        'with_audio': true,
      });

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode != 200) {
        debugPrint('AUDIO fetch error: ${resp.statusCode} ${resp.body}');
        return null;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final audioBase64 = data['audio_base64'] as String?;
      if (audioBase64 == null || audioBase64.isEmpty) {
        return null;
      }

      return await _saveAudioBase64(audioBase64);
    } catch (e) {
      debugPrint('AUDIO FETCH EXCEPTION: $e');
      return null;
    }
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
        'with_audio': false,
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
        audioFilePath = await _saveAudioBase64(audioBase64);
      }

      if (!mounted) return;

      final savedWord = SavedWord(
        word: word,
        translation: translation,
        example: example,
        exampleTranslation: exampleTranslation,
      );

      bool isSaved = _isWordSaved(word);
      bool isAudioLoading = false;

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(child: Text(word)),
                  // 🔊 КНОПКА ОЗВУЧКИ
                  // 🔊 КНОПКА ОЗВУЧКИ
IconButton(
  tooltip: 'Произнести слово',
  icon: isAudioLoading
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.volume_up),
  onPressed: () async {
    if (isAudioLoading) return;

    // показываем спиннер
    dialogSetState(() {
      isAudioLoading = true;
    });

    // если аудио ещё нет — тянем с бэка
    if (audioFilePath == null) {
      final fetchedPath = await _fetchWordAudio(word);

      if (!context.mounted) return;

      dialogSetState(() {
        isAudioLoading = false;
        audioFilePath = fetchedPath;
      });

      if (fetchedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аудио недоступно, попробуйте позже'),
          ),
        );
        return;
      }
    } else {
      // если файл уже был — просто убираем спиннер
      dialogSetState(() {
        isAudioLoading = false;
      });
    }

    // На этом этапе audioFilePath точно не null – пробуем воспроизвести
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
      length: 3,
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
              Text(partnerName),
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
              Tab(text: 'Course'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SafeArea(child: _buildChatTab()),
            SafeArea(child: _buildDictionaryTab()),
            SafeArea(child: _buildCourseTab()),
          ],
        ),
      ),
    );
  }


  String _detectPartnerNameFromMessages() {
  if (widget.language == 'English') {
    return 'Michael';
  }
  if (widget.language == 'German') {
    return 'Hans';
  }
  if (widget.language == 'French') {
    return 'Jack';
  }
  if (widget.language == 'Spanish') {
    return 'Pablo';
  }
  if (widget.language == 'Italian') {
    return 'Marco';
  }
  if (widget.language == 'Korean') {
    return 'Kim';
  }
  // запасной вариант по умолчанию
  return 'Michael';
}


  Widget _buildMessageBubble(ChatMessage msg, bool isUser) {
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    Color bgColor;
    Color textColor;
    String name;
    final accent = _characterLook.accentColor;
    final userBg = const Color(0xFFE8F0FF);
    final userText = const Color(0xFF0F1C3F);

    if (msg.isCorrections) {
      bgColor = const Color(0xFFFFF7E0);
      textColor = const Color(0xFF6A4A00);
      name = 'Corrections';
    } else if (isUser) {
      bgColor = userBg;
      textColor = userText;
      name = 'You';
    } else {
      bgColor = accent.withOpacity(0.16);
      textColor = const Color(0xFF1C1C1C);
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isCorrections
              ? bgColor
              : isUser
                  ? bgColor
                  : null,
          gradient: !isUser && !msg.isCorrections
              ? LinearGradient(
                  colors: [
                    lighten(accent, 0.2).withOpacity(0.65),
                    bgColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: isUser
              ? Border.all(color: darken(userBg, 0.08).withOpacity(0.6))
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 8),
            bottomRight: Radius.circular(isUser ? 8 : 22),
          ),
          boxShadow: [
            if (isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            if (!isUser && !msg.isCorrections)
              BoxShadow(
                color: accent.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
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
                    : Colors.grey.shade700,
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


  Widget _buildTypingIndicator() {
    final accent = _characterLook.accentColor;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => AnimatedContainer(
              duration: Duration(milliseconds: 400 + (i * 120)),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: _isSending ? 12 : 8,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.9 - i * 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          lighten(look.accentColor, 0.25),
                          Colors.white,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: look.accentColor.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rate_rounded,
                            color: look.accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: _progressValue,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(8),
                                backgroundColor:
                                    Colors.white.withOpacity(0.6),
                                color: look.accentColor,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _progressLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_userWordCount}/${_currentLevel > _levelTargets.length ? _userWordCount : _levelTargets[_currentLevel - 1]}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
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
                      itemCount: _messages.length +
                          ((_isSending && _messages.isNotEmpty) ? 1 : 0),
                      itemBuilder: (context, index) {
                        final showTyping =
                            _isSending && _messages.isNotEmpty;
                        if (showTyping && index == _messages.length) {
                          return _buildTypingIndicator();
                        }
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
    horizontal: 8,
    vertical: 6,
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
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    Positioned(
                      top: constraints.maxHeight * 0.08,
                      left: constraints.maxWidth * 0.1,
                      child: Container(
                        width: constraints.maxWidth * 0.32,
                        height: constraints.maxWidth * 0.32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              lighten(look.primaryColor, 0.4)
                                  .withOpacity(0.35),
                              Colors.white.withOpacity(0.0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: look.primaryColor.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: constraints.maxHeight * 0.12,
                      right: constraints.maxWidth * 0.05,
                      child: Container(
                        width: constraints.maxWidth * 0.28,
                        height: constraints.maxWidth * 0.28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              lighten(look.accentColor, 0.35)
                                  .withOpacity(0.4),
                              Colors.white.withOpacity(0.0),
                            ],
                            begin: Alignment.bottomRight,
                            end: Alignment.topLeft,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: constraints.maxWidth * 0.82,
                  height: constraints.maxWidth * 0.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        lighten(look.primaryColor, 0.35).withOpacity(0.5),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.08,
              child: Container(
                width: constraints.maxWidth * 0.38,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.1,
              child: Container(
                width: constraints.maxWidth * 0.52,
                height: constraints.maxHeight * 0.22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.65),
                      lighten(look.accentColor, 0.28).withOpacity(0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(
                  8,
                ),
                child: LoopingPngAnimation(
                  frames: _characterFrames,
                  frameDuration: const Duration(milliseconds: 80),
                  fit: BoxFit.cover,
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

      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      saved.word,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Удалить из словаря',
                    onPressed: () => _removeSavedWord(saved.word),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                saved.translation,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              if (saved.example.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  saved.example,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (saved.exampleTranslation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  saved.exampleTranslation,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}


  Widget _buildCourseTab() {
  final look = _characterLook;

  // 1) Загрузка курса – показываем красивый лоадер
  if (_isLoadingCourse && _coursePlan == null) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              lighten(look.primaryColor, 0.25),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const CircularProgressIndicator(),
      ),
    );
  }

  // 2) Курс ещё не сгенерирован – красивая карточка-приглашение
  if (_coursePlan == null) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lighten(look.primaryColor, 0.3),
                  lighten(look.accentColor, 0.2),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_graph_rounded,
                        color: look.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Личный курс по ${widget.language}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Текущий уровень: ${widget.level}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CoursePill(
                      icon: Icons.psychology_alt_outlined,
                      label: 'Учитываем вводный тест',
                      color: look.accentColor,
                    ),
                    _CoursePill(
                      icon: Icons.menu_book_outlined,
                      label: 'Грамматика + словарь',
                      color: look.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Сгенерируйте курс из нескольких уровней, адаптированный под ваш возраст, цели и результат теста. '
                  'Каждый уровень содержит уроки с упражнениями как в тренажёре.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade800),
                ),
                if (_courseError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _courseError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 200,
                    child: PrimaryCtaButton(
                      label: 'Сгенерировать курс',
                      onTap: _loadCoursePlan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3) Курс уже есть – показываем «дорожку уровней» как в Duolingo
  final plan = _coursePlan!;
  final levels = plan.levels;

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white,
          lighten(look.primaryColor, 0.10),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Шапка курса
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              CharacterAvatar(look: look, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Курс ${plan.language}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Общий уровень: ${plan.overallLevel}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: look.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          '${levels.length} уровней • ${levels.fold<int>(0, (sum, l) => sum + l.lessons.length)} уроков',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
                    ),
                    const SizedBox(height: 20),

        // Список уровней по «дорожке»
        for (int i = 0; i < levels.length; i++) ...[
          _buildCourseLevelNode(
            context: context,
            level: levels[i],
            index: i,
            total: levels.length,
            look: look,
            completedLessons: _completedLessons,
          ),
          const SizedBox(height: 10),
        ],
      ],
    ),
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
              decoration: InputDecoration(
                hintText: 'Write a message…',
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              onSubmitted: (_) => _sendUserMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Кнопка микрофона: запись только пока удерживается
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _isSending ? null : (_) => _startRecording(),
            onTapUp: _isSending ? null : (_) => _stopRecordingAndSend(),
            onTapCancel: _isSending ? null : _cancelRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red.withOpacity(0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isRecording
                      ? Colors.redAccent
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.4),
                ),
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
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

Widget _buildCourseLevelNode({
  required BuildContext context,
  required CourseLevelPlan level,
  required int index,
  required int total,
  required CharacterLook look,
  required Set<String> completedLessons,
}) {
  // Пока все уровни считаем «открытыми»
  final Color nodeColor = look.accentColor;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Левая часть – «столбик прогресса»
      Column(
        children: [
          if (index != 0)
            Container(
              width: 3,
              height: 22,
              color: Colors.grey.shade300,
            ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor.withOpacity(0.12),
              border: Border.all(color: nodeColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: nodeColor,
                fontSize: 13,
              ),
            ),
          ),
          if (index != total - 1)
            Container(
              width: 3,
              height: 40,
              color: Colors.grey.shade300,
            ),
        ],
      ),
      const SizedBox(width: 12),

      // Правая часть – карточка уровня с уроками
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, size: 18, color: nodeColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Уровень ${level.levelIndex}: ${level.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                level.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),

              // Плашки с грамматикой/лексикой
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (level.targetGrammar.isNotEmpty)
                    _CoursePill(
                      icon: Icons.rule_folder_outlined,
                      label: 'Grammar: ${level.targetGrammar.join(', ')}',
                      color: look.accentColor,
                    ),
                  if (level.targetVocab.isNotEmpty)
                    _CoursePill(
                      icon: Icons.auto_stories_outlined,
                      label: 'Vocab: ${level.targetVocab.join(', ')}',
                      color: look.primaryColor,
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Список уроков
              Column(
                children: [
                  for (int i = 0; i < level.lessons.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: (() {
                        final lesson = level.lessons[i];
                        final lessonKey = '${level.title}-${lesson.title}';
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LessonScreen(
                                  language: widget.language,
                                  level: widget.level,
                                  lesson: lesson,
                                  grammarTopics: level.targetGrammar,
                                  vocabTopics: level.targetVocab,
                                  userInterests: _userInterests,
                                  onComplete: (total, done) {
                                    setState(() {
                                      _completedLessons.add(lessonKey);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: completedLessons.contains(lessonKey)
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.grey.shade50,
                              border: Border.all(
                                color: completedLessons.contains(lessonKey)
                                    ? Colors.green
                                    : nodeColor.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: nodeColor.withOpacity(0.12),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: nodeColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        lesson.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey.shade700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  completedLessons.contains(lessonKey)
                                      ? Icons.check_circle
                                      : Icons.play_arrow_rounded,
                                  color: completedLessons.contains(lessonKey)
                                      ? Colors.green
                                      : nodeColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      })(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
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

class PrimaryCtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const PrimaryCtaButton({super.key, required this.label, required this.onTap});

  @override
  State<PrimaryCtaButton> createState() => _PrimaryCtaButtonState();
}

class _PrimaryCtaButtonState extends State<PrimaryCtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _pressed ? 0.9 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, darken(color, 0.12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
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
    final gradient = LinearGradient(
      colors: [
        lighten(look.primaryColor, 0.12),
        lighten(look.accentColor, 0.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: look.accentColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            look.badgeText,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: darken(look.accentColor, 0.28),
              fontSize: size * 0.32,
            ),
          ),
          Positioned(
            bottom: size * 0.16,
            right: size * 0.2,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: size * 0.16,
                color: darken(look.accentColor, 0.15),
              ),
            ),
          ),
        ],
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

class PlacementQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  PlacementQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// Единый набор тестов по языкам
final Map<String, List<PlacementQuestion>> kPlacementTests = {
  'English': [
    PlacementQuestion(
      question: 'Choose the correct sentence (Present Simple):',
      options: [
        'He go to school every day.',
        'He goes to school every day.',
        'He going to school every day.',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Translate: "Я люблю читать книги."',
      options: [
        'I love to reading books.',
        'I like reading books.',
        'I am loving read books.',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Gap-fill: "Yesterday I ___ to the cinema."',
      options: [
        'go',
        'went',
        'gone',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Which word is NOT a verb?',
      options: [
        'run',
        'happy',
        'sleep',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Choose the correct preposition: "I am interested ___ music."',
      options: [
        'in',
        'on',
        'about',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Choose the closest in meaning to "rapid":',
      options: [
        'slow',
        'fast',
        'boring',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Similar sounding: "I left my book over ___."',
      options: [
        'their',
        'there',
        "they\'re",
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Phrasal verb: "to look up" in a dictionary means…',
      options: [
        'to admire someone',
        'to search for information',
        'to visit someone',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Choose the correct phrasal verb: "He finally ___ smoking last year."',
      options: [
        'gave up',
        'gave in',
        'gave out',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Conditional: "If I ___ time, I will call you."',
      options: [
        'will have',
        'have',
        'had',
      ],
      correctIndex: 1,
    ),
  ],

  'German': [
    PlacementQuestion(
      question: 'Wähle den richtigen Satz (Präsens):',
      options: [
        'Er gehen jeden Tag zur Schule.',
        'Er geht jeden Tag zur Schule.',
        'Er geht jeden Tag zu Schule.',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Lücke ausfüllen: "Gestern ___ ich ins Kino."',
      options: [
        'gehe',
        'ging',
        'gegangen',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Welcher Artikel passt? "___ Tisch ist neu."',
      options: [
        'Der',
        'Die',
        'Das',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Welche Form ist richtig? "Ich ___ nach Hause gegangen."',
      options: [
        'bin',
        'habe',
        'werde',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Wähle das Wort, das NICHT zum Verb "sprechen" passt:',
      options: [
        'mit Freunden',
        'laut',
        'leise',
        'schnell',
      ],
      correctIndex: 3,
    ),
    PlacementQuestion(
      question: 'Präposition: "Ich warte ___ den Bus."',
      options: [
        'auf',
        'für',
        'an',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Ähnliche Bedeutung: Welches Wort ist am nächsten zu "traurig"?',
      options: [
        'glücklich',
        'froh',
        'unglücklich',
      ],
      correctIndex: 2,
    ),
    PlacementQuestion(
      question: 'Trennbares Verb: "Ich ___ morgen früh ___." (aufstehen)',
      options: [
        'aufstehe auf',
        'stehe morgen auf',
        'stehe auf morgen',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Lücke: "Kannst du mir bitte ___?"',
      options: [
        'hilfen',
        'helfen',
        'geholfen',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Welche Form ist korrekt? "Wir ___ gestern Fußball."',
      options: [
        'spielen',
        'spielten',
        'gespielt',
      ],
      correctIndex: 1,
    ),
  ],

  'French': [
    PlacementQuestion(
      question: 'Choisis la phrase correcte (présent):',
      options: [
        'Il va à l\'école tous les jours.',
        'Il allez à l\'école tous les jours.',
        'Il aller à l\'école tous les jours.',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Complète: "Hier, je ___ au cinéma."',
      options: [
        'vais',
        'suis allé',
        'allé',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Quel mot est un adjectif ?',
      options: [
        'manger',
        'heureux',
        'vite',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Préposition: "Je pense ___ toi."',
      options: [
        'à',
        'de',
        'sur',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Choisis le mot le plus proche de "rapide":',
      options: [
        'lent',
        'vite',
        'triste',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Complète: "Si j\'ai le temps, je ___."',
      options: [
        'viens',
        'viendrai',
        'viendrais',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Quel mot n\'a PAS le même son initial que les autres ?',
      options: [
        'gare',
        'gros',
        'chat',
      ],
      correctIndex: 2,
    ),
    PlacementQuestion(
      question: 'Choisis la bonne forme de "être": "Nous ___ contents."',
      options: [
        'sommes',
        'êtes',
        'sont',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Complète: "Je ___ français depuis trois ans."',
      options: [
        'apprends',
        'appris',
        'apprendre',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Quel est le contraire de "grand" ?',
      options: [
        'petit',
        'fort',
        'joli',
      ],
      correctIndex: 0,
    ),
  ],

  'Spanish': [
    PlacementQuestion(
      question: 'Elige la frase correcta:',
      options: [
        'Yo va a la escuela.',
        'Yo voy a la escuela.',
        'Yo voy a escuela.',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Completa: "Ayer ___ al cine."',
      options: [
        'voy',
        'fui',
        'iba',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: '¿Cuál palabra NO es un verbo?',
      options: [
        'correr',
        'feliz',
        'leer',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Preposición: "Pienso ___ ti."',
      options: [
        'en',
        'a',
        'de',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Palabra parecida: ¿Qué palabra suena diferente?',
      options: [
        'casa',
        'caza',
        'cosa',
      ],
      correctIndex: 2,
    ),
    PlacementQuestion(
      question: 'Completa: "Si tengo tiempo, te ___."',
      options: [
        'llamé',
        'llamaré',
        'llamo',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Escoge el sinónimo de "rápido":',
      options: [
        'lento',
        ' veloz',
        'triste',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Completa: "He ___ español durante dos años."',
      options: [
        'estudiado',
        'estudiar',
        'estudio',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: '¿Cuál forma es correcta? "Nosotros ___ fútbol ayer."',
      options: [
        'jugamos',
        'jugaron',
        'jugué',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: '¿Cuál es el contrario de "grande"?',
      options: [
        'pequeño',
        'rápido',
        'alto',
      ],
      correctIndex: 0,
    ),
  ],

  'Italian': [
    PlacementQuestion(
      question: 'Scegli la frase corretta:',
      options: [
        'Io vado a scuola ogni giorno.',
        'Io va a scuola ogni giorno.',
        'Io andare a scuola ogni giorno.',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Completa: "Ieri ___ al cinema."',
      options: [
        'vado',
        'sono andato',
        'andato',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Quale parola NON è un verbo?',
      options: [
        'correre',
        'felice',
        'leggere',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Preposizione: "Penso ___ te."',
      options: [
        'a',
        'di',
        'su',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Scegli il sinonimo di "veloce":',
      options: [
        'lento',
        'rapido',
        'triste',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Completa: "Se ho tempo, ti ___."',
      options: [
        'chiamo',
        'chiamerò',
        'chiamato',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Quale parola suona diversa?',
      options: [
        'cane',
        'casa',
        'cava',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Completa: "Studio italiano ___ tre anni."',
      options: [
        'da',
        'per',
        'in',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: 'Qual è la forma corretta? "Noi ___ calcio ieri."',
      options: [
        'giochiamo',
        'abbiamo giocato',
        'giocato',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: 'Contrario di "grande":',
      options: [
        'piccolo',
        'alto',
        'forte',
      ],
      correctIndex: 0,
    ),
  ],

  'Korean': [
    PlacementQuestion(
      question: '어느 문장이 맞습니까?',
      options: [
        '저는 학교를 가요.',
        '저는 학교에 가요.',
        '저는 학교 가요에.',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: '빈칸 채우기: "어제 영화를 ___."',
      options: [
        '가요',
        '봤어요',
        '봤다',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: '어느 단어가 형용사입니까?',
      options: [
        '먹다',
        '예쁘다',
        '읽다',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: '비슷한 발음: 다른 단어는?',
      options: [
        '눈 (eye)',
        '눈 (snow)',
        '문 (door)',
      ],
      correctIndex: 2,
    ),
    PlacementQuestion(
      question: '조사: "학교___ 가요."',
      options: [
        '가',
        '에',
        '을',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: '빈칸 채우기: "시간이 ___ 도와줄게."',
      options: [
        '있으면',
        '있어서',
        '있다',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: '어느 단어가 동사가 아닙니까?',
      options: [
        '가다',
        '작다',
        '오다',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: '알맞은 표현: "만나서 ___."',
      options: [
        '고마워요',
        '반가워요',
        '주세요',
      ],
      correctIndex: 1,
    ),
    PlacementQuestion(
      question: '문장을 완성하세요: "한국어를 ___ 있어요."',
      options: [
        '공부해',
        '공부하고',
        '공부할',
      ],
      correctIndex: 0,
    ),
    PlacementQuestion(
      question: '반대말: "크다"의 반대는?',
      options: [
        '작다',
        '많다',
        '빠르다',
      ],
      correctIndex: 0,
    ),
  ],
};


class PlacementTestScreen extends StatefulWidget {
  final String language;

  const PlacementTestScreen({super.key, required this.language});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  late final List<PlacementQuestion> _questions;
  final Map<int, int> _answers = {}; // вопрос -> выбранный вариант

  @override
  void initState() {
    super.initState();
    // Берём тест по языку, если для этого языка нет —
    // используем английский как запасной
    _questions = kPlacementTests[widget.language] ?? kPlacementTests['English']!;
  }

  Future<void> _finishTest() async {
    int correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      final answer = _answers[i];
      if (answer != null && answer == _questions[i].correctIndex) {
        correct++;
      }
    }

    final score = correct / _questions.length;
    String level;
    if (score < 0.3) {
      level = 'A1';
    } else if (score < 0.6) {
      level = 'A2';
    } else if (score < 0.8) {
      level = 'B1';
    } else {
      level = 'B2';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Результаты теста'),
        content: Text(
          'Вы ответили правильно на $correct из ${_questions.length} вопросов.\n'
          'Рекомендованный уровень: $level.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );

    Navigator.pop(context, level);
  }

  Widget _buildHeaderProgress(BuildContext context) {
    final total = _questions.length;
    final answered = _answers.length;
    final progress = total == 0 ? 0.0 : answered / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Прогресс теста',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  i < answered ? Icons.star : Icons.star_border,
                  size: 18,
                  color: i < answered
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                ),
              ),
            const Spacer(),
            Text(
              '$answered / $total отвечено',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionCard({
    required BuildContext context,
    required int index,
    required PlacementQuestion question,
    required int? selectedIndex,
  }) {
    final questionNumber = index + 1;
    final total = _questions.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Вопрос $questionNumber из $total',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selectedIndex == null
                        ? Icons.help_outline
                        : Icons.check_circle_outline,
                    size: 20,
                    color: selectedIndex == null
                        ? Colors.grey.shade400
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.question,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Column(
                children: List.generate(question.options.length, (optionIndex) {
                  final optionText = question.options[optionIndex];
                  final isSelected = selectedIndex == optionIndex;
                  final letter =
                      String.fromCharCode(65 + optionIndex); // 'A', 'B', 'C'...

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _answers[index] = optionIndex;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.12)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                optionText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAnswered = _answers.length == _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вводный тест'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeaderProgress(context),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      final selectedIndex = _answers[index];
                      return _buildQuestionCard(
                        context: context,
                        index: index,
                        question: question,
                        selectedIndex: selectedIndex,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: allAnswered ? _finishTest : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      allAnswered
                          ? 'Закончить тест и посмотреть результат'
                          : 'Ответьте на все вопросы',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class LessonScreen extends StatefulWidget {
  final String language;
  final String level;
  final LessonPlan lesson;
  final List<String> grammarTopics;
  final List<String> vocabTopics;
  final List<String> userInterests;
  final void Function(int total, int completed)? onComplete;

  const LessonScreen({
    super.key,
    required this.language,
    required this.level,
    required this.lesson,
    required this.grammarTopics,
    required this.vocabTopics,
    this.userInterests = const [],
    this.onComplete,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  LessonContentModel? _content;
  bool _isLoading = false;
  String? _error;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _finished = false;

  /// Для multiple_choice: индекс выбранного варианта
  final Map<int, int> _selectedOption = {};

  /// Для текстовых заданий (translate_sentence, fill_in_blank)
  final Map<int, String> _textAnswers = {};

  /// Для reorder_words: порядок, который выбрал пользователь
  final Map<int, List<String>> _reorderSelected = {};

  /// Какие вопросы уже проверены
  final Set<int> _checked = {};
  final Map<int, bool> _results = {};

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _normalizeText(String value) {
    final trimmed = value.trim().toLowerCase();
    final withoutPunctuation = trimmed.replaceAll(RegExp(r'[.,!?;:]+$'), '');
    return withoutPunctuation.replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isAnswerCorrect(LessonExercise ex, int index) {
    switch (ex.type) {
      case 'multiple_choice':
        final selected = _selectedOption[index];
        return selected != null && selected == ex.correctIndex;
      case 'translate_sentence':
      case 'fill_in_blank':
        final user = _textAnswers[index] ?? '';
        final correct = ex.correctAnswer ?? '';
        if (user.trim().isEmpty || correct.trim().isEmpty) return false;
        return _normalizeText(user) == _normalizeText(correct);
      case 'reorder_words':
        final selectedOrder = _reorderSelected[index] ?? const <String>[];
        final correctOrder = ex.reorderCorrect ?? const <String>[];
        if (selectedOrder.isEmpty || correctOrder.isEmpty) return false;
        final normalizedSelected =
            selectedOrder.map((e) => e.trim()).toList(growable: false);
        final normalizedCorrect =
            correctOrder.map((e) => e.trim()).toList(growable: false);
        return _listsEqual(normalizedSelected, normalizedCorrect);
      default:
        return false;
    }
  }

  String? _correctAnswerText(LessonExercise ex) {
    switch (ex.type) {
      case 'multiple_choice':
        if (ex.correctIndex != null &&
            ex.options != null &&
            ex.correctIndex! >= 0 &&
            ex.correctIndex! < ex.options!.length) {
          return ex.options![ex.correctIndex!];
        }
        return null;
      case 'translate_sentence':
      case 'fill_in_blank':
        return ex.correctAnswer?.trim().isEmpty == true
            ? null
            : ex.correctAnswer;
      case 'reorder_words':
        final correct = ex.reorderCorrect;
        if (correct == null || correct.isEmpty) return null;
        return correct.join(' ');
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  Future<void> _loadLesson() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri =
          Uri.parse('http://144.172.116.101:8000/generate_lesson');

      final body = jsonEncode({
        "language": widget.language,
        "level_hint": widget.level,
        "lesson_title": widget.lesson.title,
        "grammar_topics": widget.grammarTopics,
        "vocab_topics": widget.vocabTopics,
        "interests": widget.userInterests,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _content = LessonContentModel.fromJson(data);
        });
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkQuestion(int index) {
  if (_content == null) return;
  final ex = _content!.exercises[index];

  switch (ex.type) {
    case 'multiple_choice':
      if (_selectedOption[index] == null) return;
      break;
    case 'translate_sentence':
    case 'fill_in_blank':
      final ans = (_textAnswers[index] ?? '').trim();
      if (ans.isEmpty) return;
      break;
    case 'reorder_words':
      final order = _reorderSelected[index] ?? const <String>[];
      if (order.isEmpty) return;
      break;
    default:
      return;
  }

  setState(() {
    _checked.add(index);
    _results[index] = _isAnswerCorrect(ex, index);
  });
}


  @override
  Widget build(BuildContext context) {
    final content = _content;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
      ),
      body: _isLoading && content == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && content == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadLesson,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : content == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemCount: content.exercises.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: _LessonIntroCard(
                                    title: widget.lesson.title,
                                    description: content.description,
                                    level: widget.level,
                                  ),
                                );
                              }

                              final exIndex = index - 1;
                              final ex = content.exercises[exIndex];
                              final selected = _selectedOption[exIndex];
                              final checked = _checked.contains(exIndex);
                              final isCorrect =
                                  checked && (_results[exIndex] ?? false);

                              return AnimatedPadding(
  duration: const Duration(milliseconds: 220),
  padding: const EdgeInsets.all(16),
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeInOut,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary.withOpacity(0.06),
          Colors.white,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
  // Номер упражнения
  Text(
    'Упражнение ${exIndex + 1}/${content.exercises.length}',
    style: Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
  ),

  const SizedBox(height: 8),

  // Текст задания (question)
  if (ex.instruction != null && ex.instruction!.trim().isNotEmpty) ...[
    Text(
      ex.instruction!,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
    ),
    const SizedBox(height: 6),
  ],
  Text(
    ex.question,
    style: Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(
          fontWeight: FontWeight.w600,
        ),
  ),

  // Если это fill_in_blank — показываем предложение с пропуском
  if (ex.type == 'fill_in_blank' && ex.sentenceWithGap != null) ...[
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ex.sentenceWithGap!,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  ],

  const SizedBox(height: 12),

  // --- тело упражнения в зависимости от типа ---
  if (ex.type == 'multiple_choice' && ex.options != null) ...[
    ...List.generate(ex.options!.length, (i) {
      return RadioListTile<int>(
        value: i,
        groupValue: selected,
        activeColor: Theme.of(context).colorScheme.primary,
        title: Text(ex.options![i]),
        onChanged: (val) {
          setState(() {
            _selectedOption[exIndex] = val!;
          });
        },
      );
    }),
  ]

  // Перевод предложения
  else if (ex.type == 'translate_sentence') ...[
    TextFormField(
      initialValue: _textAnswers[exIndex] ?? '',
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Введите перевод',
        border: OutlineInputBorder(),
        filled: true,
      ),
      onChanged: (value) {
        setState(() {
          _textAnswers[exIndex] = value;
        });
      },
    ),
  ]

  // Заполни пропуск правильной формой глагола
  else if (ex.type == 'fill_in_blank') ...[
    TextFormField(
      initialValue: _textAnswers[exIndex] ?? '',
      maxLines: 1,
      decoration: const InputDecoration(
        hintText: 'Введите пропущенное слово',
        border: OutlineInputBorder(),
        filled: true,
      ),
      onChanged: (value) {
        setState(() {
          _textAnswers[exIndex] = value;
        });
      },
    ),
  ]

  // Перестановка слов
  else if (ex.type == 'reorder_words' && ex.reorderWords != null) ...[
    Text(
      'Нажмите по словам в нужном порядке:',
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(
            color: Colors.grey,
          ),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ex.reorderWords!.map((word) {
        final current = _reorderSelected[exIndex] ?? <String>[];
        final isSelected = current.contains(word);

        return ChoiceChip(
          label: Text(word),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              final updated = List<String>.from(current);
              if (isSelected) {
                updated.remove(word);
              } else {
                updated.add(word);
              }
              _reorderSelected[exIndex] = updated;
            });
          },
        );
      }).toList(),
    ),
    if ((_reorderSelected[exIndex] ?? const <String>[])
        .isNotEmpty) ...[
      const SizedBox(height: 8),
      Text(
        (_reorderSelected[exIndex] ?? const <String>[])
            .join(' '),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  ],

  const SizedBox(height: 12),

  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      ElevatedButton.icon(
        onPressed: () => _checkQuestion(exIndex),
        icon: const Icon(Icons.check),
        label: const Text('Проверить'),
      ),
      if (checked)
        Icon(
          isCorrect ? Icons.check_circle : Icons.cancel_outlined,
          color: isCorrect ? Colors.green : Colors.red,
        ),
    ],
  ),

  if (checked) ...[
    const SizedBox(height: 10),
    Text(
      ex.explanation,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(
            color: Colors.grey.shade700,
          ),
    ),
    if (!isCorrect) ...[
      const SizedBox(height: 6),
      Text(
        'Правильный ответ: ${_correctAnswerText(ex) ?? '—'}',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
      ),
    ],
  ],
],

    ),
  ),
);

                            },
                          ),
                        ),
                        _LessonPager(
                          currentPage: _currentPage,
                          totalPages: (content.exercises.length + 1),
                          onNext: _goNextPage,
                          onPrev: _goPrevPage,
                        ),
                        if (_currentPage == content.exercises.length)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 16),
                            child: PrimaryCtaButton(
                              label: 'Завершить урок',
                              onTap: _finishLesson,
                            ),
                          ),
                      ],
                    ),
    );
  }

  void _goNextPage() {
    final content = _content;
    if (content == null) return;
    final total = content.exercises.length + 1;
    if (_currentPage < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goPrevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishLesson() {
    final content = _content;
    if (content == null) return;
    final total = content.exercises.length;
    final completed = _checked.length;
    if (_finished) return;

    setState(() {
      _finished = true;
    });

    widget.onComplete?.call(total, completed);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Отлично!'),
        content: Text('Вы завершили урок.\nВыполнено заданий: $completed из $total.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _LessonIntroCard extends StatelessWidget {
  final String title;
  final String description;
  final String level;

  const _LessonIntroCard({
    required this.title,
    required this.description,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Урок по уровню $level',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Сначала прочитай описание урока, потом листай вправо к заданиям.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _LessonPager extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const _LessonPager({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: currentPage == 0 ? null : onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (i) {
                final active = i == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: active ? 22 : 10,
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
          IconButton(
            onPressed: currentPage == totalPages - 1 ? null : onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
