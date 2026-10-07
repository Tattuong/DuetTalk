enum TalkMode { face, pass }

enum PhraseSave { added, duplicate, limit }

class TalkLine {
  TalkLine({required this.id, required this.speaker, required this.text});

  final String id;
  final String speaker;
  String text;

  Map<String, dynamic> toJson() => {'id': id, 'speaker': speaker, 'text': text};

  factory TalkLine.fromJson(Map<String, dynamic> json) => TalkLine(
        id: json['id'] as String? ?? '',
        speaker: json['speaker'] as String? ?? 'a',
        text: json['text'] as String? ?? '',
      );
}

class SavedPhrase {
  SavedPhrase({required this.id, required this.text});

  final String id;
  final String text;

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory SavedPhrase.fromJson(Map<String, dynamic> json) => SavedPhrase(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}

class TalkLanguage {
  const TalkLanguage(this.code, this.label, this.hint);

  final String code;
  final String label;
  final String hint;
}

const talkSparks = <String>[
  'What do you feel like?',
  'Tell me one good thing.',
  'Ask me anything.',
  'Want to trade a secret?',
  'What should we do next?',
  'Say it in one sentence.',
];

const talkLanguages = <TalkLanguage>[
  TalkLanguage('en', 'English', 'Type what you want to say'),
  TalkLanguage('vi', 'Tiếng Việt', 'Gõ lời muốn nói'),
  TalkLanguage('ja', '日本語', '伝えたいことを入力'),
  TalkLanguage('ko', '한국어', '하고 싶은 말을 입력하세요'),
  TalkLanguage('es', 'Español', 'Escribe lo que quieres decir'),
  TalkLanguage('fr', 'Français', 'Écris ce que tu veux dire'),
];

TalkLanguage languageByCode(String code) =>
    talkLanguages.firstWhere((language) => language.code == code, orElse: () => talkLanguages.first);

String speakerName(String speaker) => speaker == 'b' ? 'Person B' : 'Person A';
