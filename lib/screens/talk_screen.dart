import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_colors.dart';
import '../models/shop_item.dart';
import '../models/talk.dart';
import '../providers/shop_provider.dart';
import '../providers/talk_provider.dart';
import '../widgets/app_ui.dart';
import 'compose_screen.dart';
import 'enlarge_screen.dart';

class TalkScreen extends StatefulWidget {
  const TalkScreen({super.key});

  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends State<TalkScreen> {
  var _awake = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (context.read<ShopProvider>().featureOn(ShopCatalog.featAwake)) {
        _awake = true;
        await WakelockPlus.enable();
      }
    });
  }

  @override
  void dispose() {
    if (_awake) WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _leave() async {
    await context.read<TalkProvider>().finishSession();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    final talk = context.read<TalkProvider>();
    if (talk.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to clear')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this chat?'),
        content: const Text('Saved phrases stay.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) await talk.clearChat();
  }

  @override
  Widget build(BuildContext context) {
    final talk = context.watch<TalkProvider>();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) talk.finishSession();
      },
      child: Scaffold(
        backgroundColor: AppColors.personA,
        body: SafeArea(
          child: talk.mode == TalkMode.face ? _Face(onLeave: _leave, onClear: _clear) : _Pass(onLeave: _leave, onClear: _clear),
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.onLeave, required this.onClear});

  final VoidCallback onLeave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Transform.rotate(
                angle: math.pi,
                child: const _Pane(speaker: 'b'),
              ),
            ),
            const Expanded(child: _Pane(speaker: 'a')),
          ],
        ),
        Center(child: _TalkBar(onLeave: onLeave, onClear: onClear)),
      ],
    );
  }
}

class _Pass extends StatelessWidget {
  const _Pass({required this.onLeave, required this.onClear});

  final VoidCallback onLeave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final talk = context.watch<TalkProvider>();
    return Column(
      children: [
        Expanded(child: _Pane(speaker: talk.turn, pass: true)),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TalkBar(onLeave: onLeave, onClear: onClear),
        ),
      ],
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.speaker, this.pass = false});

  final String speaker;
  final bool pass;

  @override
  Widget build(BuildContext context) {
    final talk = context.watch<TalkProvider>();
    final mine = talk.lastOf(speaker);
    final shown = pass ? (talk.latest) : mine;
    final color = speaker == 'b' ? AppColors.personB : AppColors.personA;
    final dot = speaker == 'b' ? AppColors.personBDot : AppColors.personADot;
    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(speakerName(speaker).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.ink)),
              ],
            ),
            if (pass && talk.latest != null && talk.latest!.speaker != speaker)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Pass the phone to ${speakerName(speaker)}', textAlign: TextAlign.center, style: AppTypography.body(size: 14, color: AppColors.ink)),
              ),
            Expanded(
              child: shown == null
                  ? _SparkPrompt(speaker: speaker)
                  : GestureDetector(
                      onTap: () => _openLarge(context, shown.id),
                      child: _ScrollText(
                        text: shown.text,
                        caption: pass && shown.speaker != speaker ? speakerName(shown.speaker) : null,
                        waiting: false,
                      ),
                    ),
            ),
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(child: Center(child: _WriteButton(speaker: speaker, rotated: !pass && speaker == 'b'))),
                IconButton(
                  onPressed: shown == null ? null : () => _openLarge(context, shown.id),
                  icon: Icon(Icons.open_in_full, size: 18, color: shown == null ? AppColors.ink.withValues(alpha: 0.25) : AppColors.ink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _openLarge(BuildContext context, String id) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => EnlargeScreen(lineId: id)));
}

class _SparkPrompt extends StatefulWidget {
  const _SparkPrompt({required this.speaker});

  final String speaker;

  @override
  State<_SparkPrompt> createState() => _SparkPromptState();
}

class _SparkPromptState extends State<_SparkPrompt> {
  var _index = 0;
  var _busy = false;

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    final sent = await context.read<TalkProvider>().send(widget.speaker, talkSparks[_index]);
    if (!mounted || sent == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EnlargeScreen(lineId: sent.id)));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Try this', style: AppTypography.labelBold(size: 12, color: AppColors.ink.withValues(alpha: 0.55))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _busy ? null : _send,
          child: Text(
            talkSparks[_index],
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: AppTypography.outfitFamily, fontWeight: FontWeight.w800, fontSize: 26, height: 1.15, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : () => setState(() => _index = (_index + 1) % talkSparks.length),
          icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.ink),
          label: const Text('Another spark', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
      ],
    );
  }
}

class _ScrollText extends StatelessWidget {
  const _ScrollText({required this.text, required this.waiting, this.caption});

  final String text;
  final bool waiting;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (caption != null) ...[
                  Text(caption!.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 12, color: AppColors.ink)),
                  const SizedBox(height: 8),
                ],
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.outfitFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: waiting ? 18 : 32,
                    height: 1.15,
                    color: waiting ? AppColors.ink.withValues(alpha: 0.45) : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WriteButton extends StatelessWidget {
  const _WriteButton({required this.speaker, this.rotated = false});

  final String speaker;
  final bool rotated;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComposeScreen(speaker: speaker, rotated: rotated))),
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Write a message', style: TextStyle(fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _TalkBar extends StatelessWidget {
  const _TalkBar({required this.onLeave, required this.onClear});

  final VoidCallback onLeave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final talk = context.read<TalkProvider>();
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: onLeave, icon: const Icon(Icons.close, color: AppColors.ink)),
            IconButton(onPressed: onClear, icon: const Icon(Icons.refresh_rounded, color: AppColors.personADot)),
            IconButton(
              onPressed: () {
                final text = talk.latest?.text ?? '';
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to save yet')));
                  return;
                }
                final result = talk.savePhrase(text);
                final message = switch (result) {
                  PhraseSave.added => 'Phrase saved',
                  PhraseSave.duplicate => 'That phrase is already saved',
                  PhraseSave.limit => 'Unlock DuetTalk Pro to keep more phrases',
                };
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
              },
              icon: const Icon(Icons.bookmark_border, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
