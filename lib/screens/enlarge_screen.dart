import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/talk.dart';
import '../providers/shop_provider.dart';
import '../providers/talk_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import 'compose_screen.dart';

class EnlargeScreen extends StatefulWidget {
  const EnlargeScreen({super.key, required this.lineId});

  final String lineId;

  @override
  State<EnlargeScreen> createState() => _EnlargeScreenState();
}

class _EnlargeScreenState extends State<EnlargeScreen> with TickerProviderStateMixin {
  var _scale = 1;
  var _showTurn = true;
  late final AnimationController _enter;
  late final AnimationController _spin;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    _pop = CurvedAnimation(parent: _enter, curve: Curves.easeOutBack);
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _enter.forward();
    Future<void>.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _showTurn = false);
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final talk = context.watch<TalkProvider>();
    final line = talk.find(widget.lineId);
    if (line == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Back')),
        body: const Center(child: Text('This message is gone.')),
      );
    }
    final color = line.speaker == 'b' ? AppColors.personB : AppColors.personA;
    final size = switch (_scale) {
      0 => 32.0,
      2 => 56.0,
      _ => 44.0,
    };
    return Scaffold(
      backgroundColor: color,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: AppColors.ink,
        title: const Text('Back'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _scale = (_scale + 1) % 3),
            child: const Text('Aa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
                child: Text("${speakerName(line.speaker).toUpperCase()}'S MESSAGE", style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 12, color: AppColors.ink)),
              ),
              const SizedBox(height: 10),
              AnimatedOpacity(
                opacity: _showTurn ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(turns: _spin, child: const Icon(Icons.screen_rotation_alt, size: 16, color: AppColors.ink)),
                    const SizedBox(width: 6),
                    const Text('Turn the phone toward them', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.82, end: 1).animate(_pop),
                            child: Text(
                              line.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: AppTypography.outfitFamily, fontWeight: FontWeight.w800, fontSize: size, height: 1.15, color: AppColors.ink),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComposeScreen(speaker: line.speaker, lineId: line.id, initialText: line.text))),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit message', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _ReplyButton(label: 'Yes', lineSpeaker: line.speaker)),
                  const SizedBox(width: 10),
                  Expanded(child: _ReplyButton(label: 'No', lineSpeaker: line.speaker)),
                ],
              ),
              TextButton.icon(
                onPressed: () => _save(talk, line.text),
                icon: const Icon(Icons.bookmark_border, color: AppColors.ink),
                label: const Text('Save this phrase', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save(TalkProvider talk, String text) {
    final result = talk.savePhrase(text);
    if (result == PhraseSave.limit) {
      final shop = context.read<ShopProvider>();
      AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
      return;
    }
    final message = result == PhraseSave.added ? 'Phrase saved' : 'That phrase is already saved';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReplyButton extends StatefulWidget {
  const _ReplyButton({required this.label, required this.lineSpeaker});

  final String label;
  final String lineSpeaker;

  @override
  State<_ReplyButton> createState() => _ReplyButtonState();
}

class _ReplyButtonState extends State<_ReplyButton> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              final reader = widget.lineSpeaker == 'a' ? 'b' : 'a';
              await context.read<TalkProvider>().send(reader, widget.label);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.15)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }
}
