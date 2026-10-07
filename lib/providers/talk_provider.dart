import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/storage_service.dart';
import '../models/talk.dart';
import 'shop_provider.dart';

class TalkProvider extends ChangeNotifier {
  TalkProvider(this.shop);

  static const _phrasesKey = 'dt_phrases';
  static const _linesKey = 'dt_lines';
  static const _modeKey = 'dt_talk_mode';
  static const _wipeKey = 'dt_wipe_on_exit';
  static const _langKey = 'dt_keyboard_lang';

  final ShopProvider shop;
  final _uuid = const Uuid();

  TalkMode mode = TalkMode.face;
  bool wipeOnExit = true;
  String languageCode = 'en';
  String turn = 'a';
  final List<TalkLine> _lines = [];
  final List<SavedPhrase> _phrases = [];

  List<TalkLine> get lines => List.unmodifiable(_lines);
  List<SavedPhrase> get phrases => List.unmodifiable(_phrases);

  TalkLine? lastOf(String speaker) {
    for (var i = _lines.length - 1; i >= 0; i--) {
      if (_lines[i].speaker == speaker) return _lines[i];
    }
    return null;
  }

  TalkLine? get latest => _lines.isEmpty ? null : _lines.last;

  TalkLine? find(String id) {
    for (final line in _lines) {
      if (line.id == id) return line;
    }
    return null;
  }

  Future<void> init() async {
    mode = (await StorageService.instance.getString(_modeKey)) == 'pass' ? TalkMode.pass : TalkMode.face;
    wipeOnExit = await StorageService.instance.getBool(_wipeKey) ?? true;
    languageCode = await StorageService.instance.getString(_langKey) ?? 'en';
    final phrases = await StorageService.instance.getDataList(_phrasesKey);
    _phrases
      ..clear()
      ..addAll((phrases ?? []).map(SavedPhrase.fromJson).where((phrase) => phrase.text.trim().isNotEmpty));
    if (!wipeOnExit) {
      final stored = await StorageService.instance.getDataList(_linesKey);
      _lines
        ..clear()
        ..addAll((stored ?? []).map(TalkLine.fromJson).where((line) => line.text.trim().isNotEmpty));
    }
    notifyListeners();
  }

  Future<void> setMode(TalkMode value) async {
    mode = value;
    await StorageService.instance.saveString(_modeKey, value == TalkMode.pass ? 'pass' : 'face');
    notifyListeners();
  }

  Future<void> setWipeOnExit(bool value) async {
    wipeOnExit = value;
    await StorageService.instance.saveBool(_wipeKey, value);
    if (value) await StorageService.instance.remove(_linesKey);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    languageCode = code;
    await StorageService.instance.saveString(_langKey, code);
    notifyListeners();
  }

  Future<void> beginSession() async {
    turn = 'a';
    if (wipeOnExit) {
      _lines.clear();
      await StorageService.instance.remove(_linesKey);
    }
    notifyListeners();
  }

  Future<TalkLine?> send(String speaker, String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final line = TalkLine(id: _uuid.v4(), speaker: speaker, text: text);
    _lines.add(line);
    turn = speaker == 'a' ? 'b' : 'a';
    await _persistLines();
    await shop.rewardForLine();
    notifyListeners();
    return line;
  }

  Future<void> edit(String id, String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    final line = find(id);
    if (line == null) return;
    line.text = text;
    await _persistLines();
    notifyListeners();
  }

  Future<void> clearChat() async {
    _lines.clear();
    turn = 'a';
    await StorageService.instance.remove(_linesKey);
    notifyListeners();
  }

  Future<void> finishSession() async {
    if (!wipeOnExit) return;
    _lines.clear();
    turn = 'a';
    await StorageService.instance.remove(_linesKey);
    notifyListeners();
  }

  PhraseSave savePhrase(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return PhraseSave.duplicate;
    final exists = _phrases.any((phrase) => phrase.text.toLowerCase() == text.toLowerCase());
    if (exists) return PhraseSave.duplicate;
    if (_phrases.length >= shop.maxArchive) return PhraseSave.limit;
    _phrases.insert(0, SavedPhrase(id: _uuid.v4(), text: text));
    _persistPhrases();
    notifyListeners();
    return PhraseSave.added;
  }

  Future<void> deletePhrase(String id) async {
    _phrases.removeWhere((phrase) => phrase.id == id);
    await _persistPhrases();
    notifyListeners();
  }

  Future<void> _persistLines() async {
    if (wipeOnExit) return;
    await StorageService.instance.saveDataList(_linesKey, _lines.map((line) => line.toJson()).toList());
  }

  Future<void> _persistPhrases() async {
    await StorageService.instance.saveDataList(_phrasesKey, _phrases.map((phrase) => phrase.toJson()).toList());
  }
}
