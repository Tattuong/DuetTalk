import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_navigator.dart';
import '../models/talk.dart';
import '../providers/talk_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_ui.dart';
import '../widgets/coin_balance_chip.dart';
import 'phrases_screen.dart';
import 'talk_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final talk = context.watch<TalkProvider>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: [
                  Row(
                    children: [
                      const _LogoMark(),
                      const SizedBox(width: 8),
                      Text('DuetTalk', style: AppTypography.title(size: 22, context: context)),
                      const Spacer(),
                      const CoinBalanceChip(variant: CoinChipVariant.header),
                      const SizedBox(width: 2),
                      const IconButton(visualDensity: VisualDensity.compact, onPressed: AppTabs.goSettings, icon: Icon(Icons.settings_outlined)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Two people.\nOne screen.', style: AppTypography.display(size: 34, context: context)),
                  const SizedBox(height: 8),
                  Text('Type what you want to say, so the other person can read it.', style: AppTypography.body(size: 16, context: context)),
                  const SizedBox(height: 16),
                  const _PhoneArt(),
                  const SizedBox(height: 16),
                  Material(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: Text('How you talk', style: AppTypography.labelBold(size: 16, context: context)),
                        ),
                        _ModeCard(
                          selected: talk.mode == TalkMode.face,
                          icon: Icons.sync_rounded,
                          title: 'Face to face',
                          subtitle: 'Two halves, turned around',
                          onTap: () => talk.setMode(TalkMode.face),
                        ),
                        _ModeCard(
                          selected: talk.mode == TalkMode.pass,
                          icon: Icons.swap_horiz_rounded,
                          title: 'Pass the phone',
                          subtitle: 'Same way up, take turns typing',
                          onTap: () => talk.setMode(TalkMode.pass),
                        ),
                        SwitchListTile(
                          value: talk.wipeOnExit,
                          onChanged: talk.setWipeOnExit,
                          activeThumbColor: AppColors.onPrimaryOf(context),
                          activeTrackColor: AppColors.primaryOf(context),
                          title: Text('Delete the chat when you finish', style: AppTypography.labelBold(size: 14, context: context)),
                          subtitle: Text('Saved phrases stay', style: AppTypography.body(size: 13, context: context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await talk.beginSession();
                    if (!context.mounted) return;
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TalkScreen()));
                  },
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  child: const Text('Start talking  →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhrasesScreen())),
              icon: Icon(Icons.bookmark_border, color: AppColors.primaryOf(context)),
              label: Text('Quick phrases', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryOf(context))),
            ),
            const AdBannerSlot(),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.primaryOf(context), borderRadius: BorderRadius.circular(8)),
      child: const CustomPaint(size: Size(18, 14), painter: _MarkPainter()),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.personADot : AppColors.mutedInk(context)),
              const SizedBox(width: 10),
              Icon(icon, color: ink),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelBold(size: 15, context: context)),
                    Text(subtitle, style: AppTypography.body(size: 13, context: context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()..color = const Color(0xFF5B8DEF);
    final peach = Paint()..color = const Color(0xFFF6C48A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 1, size.width * 0.58, size.height * 0.7), const Radius.circular(5)), blue);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.42, 1, size.width * 0.58, size.height * 0.7), const Radius.circular(5)), peach);
    final white = Paint()..color = Colors.white;
    final ink = Paint()..color = const Color(0xFF1B2744);
    for (final dx in [0.22, 0.38, 0.54]) {
      canvas.drawCircle(Offset(size.width * dx, size.height * 0.36), 1.3, white);
    }
    for (final dx in [0.58, 0.72, 0.86]) {
      canvas.drawCircle(Offset(size.width * dx, size.height * 0.36), 1.2, ink);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhoneArt extends StatelessWidget {
  const _PhoneArt();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 132, child: CustomPaint(painter: _PhonePainter()));
  }
}

class _PhonePainter extends CustomPainter {
  const _PhonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final phone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 210, height: 112),
      const Radius.circular(22),
    );
    canvas.drawRRect(phone, Paint()..color = const Color(0xFF1B2744));
    canvas.save();
    canvas.clipRRect(phone);
    final inner = phone.outerRect.deflate(8);
    canvas.drawRect(Rect.fromLTRB(inner.left, inner.top, inner.center.dx, inner.bottom), Paint()..color = AppColors.personA);
    canvas.drawRect(Rect.fromLTRB(inner.center.dx, inner.top, inner.right, inner.bottom), Paint()..color = AppColors.personB);
    final blue = Paint()..color = const Color(0xFF4C7CFF);
    final peach = Paint()..color = const Color(0xFFF6C48A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(inner.left + 48, inner.center.dy), width: 54, height: 36), const Radius.circular(12)), blue);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(inner.right - 48, inner.center.dy), width: 54, height: 36), const Radius.circular(12)), peach);
    final dots = Paint()..color = Colors.white;
    for (final dx in [-12.0, 0.0, 12.0]) {
      canvas.drawCircle(Offset(inner.left + 48 + dx, inner.center.dy), 3, dots);
    }
    final darkDots = Paint()..color = const Color(0xFF1B2744);
    for (final dx in [-12.0, 0.0, 12.0]) {
      canvas.drawCircle(Offset(inner.right - 48 + dx, inner.center.dy), 3, darkDots);
    }
    final arrow = Paint()
      ..color = const Color(0xFF1B2744)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final right = Offset(inner.center.dx + 14, inner.center.dy - 8);
    final left = Offset(inner.center.dx - 14, inner.center.dy + 8);
    canvas.drawLine(Offset(inner.center.dx - 14, inner.center.dy - 8), right, arrow);
    canvas.drawLine(right, right + const Offset(-6, -4), arrow);
    canvas.drawLine(right, right + const Offset(-6, 4), arrow);
    canvas.drawLine(Offset(inner.center.dx + 14, inner.center.dy + 8), left, arrow);
    canvas.drawLine(left, left + const Offset(6, -4), arrow);
    canvas.drawLine(left, left + const Offset(6, 4), arrow);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
