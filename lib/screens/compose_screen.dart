import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/services/keyboard_picker.dart';
import '../models/shop_item.dart';
import '../models/talk.dart';
import '../providers/shop_provider.dart';
import '../providers/talk_provider.dart';
import '../widgets/app_toast.dart';
import 'enlarge_screen.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, required this.speaker, this.lineId, this.initialText = '', this.rotated = false});

  final String speaker;
  final String? lineId;
  final String initialText;
  final bool rotated;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  late final TextEditingController _text;
  var _busy = false;
  var _shift = false;
  var _spark = 0;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final raw = _text.text.trim();
    if (raw.isEmpty) {
      AppToast.show(context, title: 'Type a message first');
      return;
    }
    setState(() => _busy = true);
    final shop = context.read<ShopProvider>();
    if (shop.featureOn(ShopCatalog.featSound)) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
    final talk = context.read<TalkProvider>();
    if (widget.lineId == null) {
      final sent = await talk.send(widget.speaker, raw);
      if (!mounted || sent == null) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EnlargeScreen(lineId: sent.id)));
      return;
    }
    await talk.edit(widget.lineId!, raw);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _insert(String value) {
    final text = _text.text;
    final selection = _text.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final next = text.replaceRange(start, end, value);
    _text.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + value.length));
  }

  void _backspace() {
    final text = _text.text;
    final selection = _text.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    if (start != end) {
      _insert('');
      return;
    }
    if (start == 0) return;
    final next = text.replaceRange(start - 1, start, '');
    _text.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start - 1));
  }

  @override
  Widget build(BuildContext context) {
    final talk = context.watch<TalkProvider>();
    final language = languageByCode(talk.languageCode);
    final color = widget.speaker == 'b' ? AppColors.personB : AppColors.personA;
    final page = Scaffold(
      resizeToAvoidBottomInset: !widget.rotated,
      backgroundColor: color,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: AppColors.ink,
        title: Text(widget.lineId == null ? 'Write a message' : 'Edit message'),
        actions: [
          TextButton(
            onPressed: () => widget.rotated ? _cycleLanguage(talk) : _pickLanguage(talk),
            child: Text(language.code.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          IconButton(
            onPressed: () => KeyboardPicker.show(context),
            icon: const Icon(Icons.keyboard_alt_outlined),
            tooltip: 'Keyboard',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _text,
                autofocus: !widget.rotated,
                readOnly: widget.rotated,
                showCursor: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: language.hint,
                  hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.35), fontSize: 28, fontWeight: FontWeight.w600),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          if (talk.phrases.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final phrase in talk.phrases)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(phrase.text, overflow: TextOverflow.ellipsis),
                        ),
                        onPressed: () {
                          _text.text = phrase.text;
                          _text.selection = TextSelection.collapsed(offset: _text.text.length);
                        },
                      ),
                    ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () {
              setState(() => _spark = (_spark + 1) % talkSparks.length);
              _text.text = talkSparks[_spark];
              _text.selection = TextSelection.collapsed(offset: _text.text.length);
            },
            icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.ink),
            label: const Text('Try a spark', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(widget.lineId == null ? 'Send' : 'Save', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ),
          if (widget.rotated)
            _KeyPad(
              shift: _shift,
              language: language.code,
              onShift: () => setState(() => _shift = !_shift),
              onLanguage: () => _cycleLanguage(talk),
              onKey: _typeKey,
              onBackspace: _backspace,
            ),
        ],
      ),
    );
    if (!widget.rotated) return page;
    return SafeArea(child: Transform.rotate(angle: math.pi, child: page));
  }

  void _cycleLanguage(TalkProvider talk) {
    final index = talkLanguages.indexWhere((item) => item.code == talk.languageCode);
    final next = talkLanguages[(index + 1) % talkLanguages.length];
    talk.setLanguage(next.code);
  }

  void _typeKey(String key) {
    final letter = _shift ? key.toUpperCase() : key;
    _insert(letter);
    if (_shift) setState(() => _shift = false);
  }

  Future<void> _pickLanguage(TalkProvider talk) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final language in talkLanguages)
              ListTile(
                title: Text(language.label),
                trailing: language.code == talk.languageCode ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, language.code),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await talk.setLanguage(picked);
  }
}

class _KeyPad extends StatelessWidget {
  const _KeyPad({
    required this.shift,
    required this.language,
    required this.onShift,
    required this.onLanguage,
    required this.onKey,
    required this.onBackspace,
  });

  final bool shift;
  final String language;
  final VoidCallback onShift;
  final VoidCallback onLanguage;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Column(
        children: [
          for (final row in rows)
            Row(
              children: [
                for (final key in row.split(''))
                  Expanded(child: _Key(label: shift ? key.toUpperCase() : key, onTap: () => onKey(key))),
              ],
            ),
          Row(
            children: [
              Expanded(child: _Key(label: shift ? 'ABC' : 'abc', onTap: onShift)),
              Expanded(flex: 4, child: _Key(label: 'space', onTap: () => onKey(' '))),
              Expanded(child: _Key(label: language.toUpperCase(), onTap: onLanguage)),
              Expanded(child: _Key(label: '⌫', onTap: onBackspace)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink))),
          ),
        ),
      ),
    );
  }
}
