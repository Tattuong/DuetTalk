import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/talk.dart';
import '../providers/shop_provider.dart';
import '../providers/talk_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';

class PhrasesScreen extends StatelessWidget {
  const PhrasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final talk = context.watch<TalkProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Quick phrases')),
      body: Column(
        children: [
          Expanded(
            child: talk.phrases.isEmpty
                ? Center(child: Text('No saved phrases yet.', style: AppTypography.body(size: 16, context: context)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    itemCount: talk.phrases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final phrase = talk.phrases[index];
                      return Material(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          title: Text(phrase.text, style: AppTypography.labelBold(size: 16, context: context)),
                          trailing: IconButton(
                            onPressed: () => talk.deletePhrase(phrase.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add),
                label: const Text('Add a phrase', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
              ),
            ),
          ),
          const AdBannerSlot(),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final talk = context.read<TalkProvider>();
    final shop = context.read<ShopProvider>();
    if (talk.phrases.length >= shop.maxArchive) {
      AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
      return;
    }
    final text = await showDialog<String>(context: context, builder: (_) => const _NewPhraseDialog());
    if (text == null || !context.mounted) return;
    if (text.trim().isEmpty) {
      AppToast.show(context, title: 'Type a phrase first');
      return;
    }
    final result = talk.savePhrase(text);
    if (result == PhraseSave.duplicate) {
      AppToast.show(context, title: 'That phrase is already saved');
    }
  }
}

class _NewPhraseDialog extends StatefulWidget {
  const _NewPhraseDialog();

  @override
  State<_NewPhraseDialog> createState() => _NewPhraseDialogState();
}

class _NewPhraseDialogState extends State<_NewPhraseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New phrase'),
      content: TextField(controller: _controller, autofocus: true, decoration: const InputDecoration(hintText: 'Yes, please')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Save')),
      ],
    );
  }
}
