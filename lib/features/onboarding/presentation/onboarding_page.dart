import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefOnboardingDone = 'onboarding_done';

Future<bool> isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_prefOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefOnboardingDone, true);
}

void showOnboardingIfNeeded(BuildContext context) async {
  final done = await isOnboardingDone();
  if (!done && context.mounted) {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const OnboardingSheet(),
    );
  }
}

class OnboardingSheet extends StatefulWidget {
  const OnboardingSheet({super.key});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      emoji: '🧙',
      title: 'Welcome to the Hood.',
      body: 'This is not Google Maps.\nThis is YOUR hood.\nMark it. Own it.',
    ),
    _Slide(
      emoji: '📍',
      title: 'Drop Markers.',
      body: 'Long-press the map or tap ＋\nLeave notes & CTAs for your crew.\nOthers in the same lobby see them.',
    ),
    _Slide(
      emoji: '🤝',
      title: 'Invite Your Crew.',
      body: 'Tap the share button 🔗 on the map.\nSend the link.\nThey join – they see the same map.',
    ),
    _Slide(
      emoji: '⚡',
      title: 'Level Up. Get Legendary.',
      body: 'Every marker earns XP.\nHigher level = more epic marker pins.\nReach "The Hoodini" if you dare.',
    ),
    _Slide(
      emoji: '🚨',
      title: 'Dein Hood. Deine Verantwortung.',
      body: 'Die Community-Lobby\n"Rechtsextreme Symbole melden"\nist immer sichtbar – egal wo du bist.\n\nDokumentiere Hakenkreuze, Nazi-Sticker\nund rechte Symbole in deiner Umgebung.\nGemeinsam gegen Rechtspopulismus.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _page == _slides.length - 1;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Slides
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _slides.length,
              itemBuilder: (ctx, i) => _SlideWidget(slide: _slides[i]),
            ),
          ),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? cs.primary : cs.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Button
          FilledButton(
            onPressed: isLast
                ? _finish
                : () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
            child: Text(isLast ? '[ ENTER THE HOOD ]' : 'NEXT →'),
          ),
        ],
      ),
    );
  }
}

class _SlideWidget extends StatelessWidget {
  const _SlideWidget({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(slide.emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 20),
        Text(
          slide.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: cs.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          slide.body,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: cs.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Slide {
  const _Slide({
    required this.emoji,
    required this.title,
    required this.body,
  });
  final String emoji;
  final String title;
  final String body;
}
