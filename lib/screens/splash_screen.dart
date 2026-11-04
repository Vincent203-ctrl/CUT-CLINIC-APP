import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/brand.dart';
import '../widgets/cut_logo.dart';
import '../widgets/home_hero.dart' show kCampusAsset;

/// First screen: CUT building header, slogan, sliding feature cards and a
/// Get Started button.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final topInset = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: CutColors.blue,
        body: LayoutBuilder(
          builder: (context, c) {
            final heroH = (c.maxHeight * 0.52).clamp(300.0, 520.0);

            return Stack(
              children: [
                // CUT building photo, fading into the CUT-blue lower section
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: heroH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        kCampusAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stack) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [CutColors.blueDark, CutColors.blue],
                            ),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              CutColors.blueDark.withAlpha(170),
                              CutColors.blue.withAlpha(110),
                              CutColors.blue,
                            ],
                            stops: const [0, 0.5, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - v)),
                              child: child,
                            ),
                          ),
                          child: Column(
                            children: [
                              // ---- header area over the building photo ----
                              SizedBox(
                                height: heroH - topInset,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CutLogoBadge(size: 96),
                                    const SizedBox(height: 18),
                                    Text(
                                      'CUT CLINIC',
                                      textAlign: TextAlign.center,
                                      style: t.headlineLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 4,
                                        fontSize: 32,
                                        shadows: const [
                                          Shadow(color: Colors.black38, blurRadius: 10),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      height: 3,
                                      width: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white70,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'YOUR HEALTH, OUR PRIORITY',
                                      textAlign: TextAlign.center,
                                      style: t.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2.2,
                                        fontSize: 14,
                                        shadows: const [
                                          Shadow(color: Colors.black38, blurRadius: 8),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ---- sliding features ----
                              const _WelcomeSlides(),
                              const SizedBox(height: 22),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: _GetStartedButton(onPressed: onContinue),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Central University of Technology, Free State',
                                textAlign: TextAlign.center,
                                style: t.bodySmall?.copyWith(color: Colors.white60),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

/// Auto-sliding cards: Easy booking, Live status, Reminders.
class _WelcomeSlides extends StatefulWidget {
  const _WelcomeSlides();

  @override
  State<_WelcomeSlides> createState() => _WelcomeSlidesState();
}

class _WelcomeSlidesState extends State<_WelcomeSlides> {
  static const _slides = <_Slide>[
    _Slide(Icons.edit_calendar_rounded, 'Easy booking',
        'Request a clinic visit in under a minute. Pick a service and send.'),
    _Slide(Icons.track_changes_rounded, 'Live status',
        'Follow your request from pending to approved, in real time.'),
    _Slide(Icons.notifications_active_rounded, 'Reminders',
        'Get SMS or email updates, plus a reminder the day before.'),
  ];

  final _controller = PageController(viewportFraction: 0.86);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % _slides.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 116,
          child: NotificationListener<UserScrollNotification>(
            // restart the timer after the student swipes
            onNotification: (_) {
              _startTimer();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => AnimatedScale(
                scale: i == _index ? 1 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: _SlideCard(slide: _slides[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: i == _index ? 22 : 6,
                decoration: BoxDecoration(
                  color: i == _index ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(40),
            ),
            child: Icon(slide.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slide.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(31),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(31),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: [
                  const SizedBox(width: 44),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: CutColors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      color: CutColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}