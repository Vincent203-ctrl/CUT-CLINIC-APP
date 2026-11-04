import 'dart:async';

import 'package:flutter/material.dart';

import '../core/brand.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.text, this.colors);

  final IconData icon;
  final String title;
  final String text;
  final List<Color> colors;
}

/// Auto-sliding banner: Easy booking, Live status, Reminders.
/// Slides every 4 seconds; swiping by hand works too.
class FeatureCarousel extends StatefulWidget {
  const FeatureCarousel({super.key, this.height = 112});

  final double height;

  @override
  State<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends State<FeatureCarousel> {
  static const _slides = <_Slide>[
    _Slide(
      Icons.edit_calendar_rounded,
      'Easy booking',
      'Request a clinic visit in under a minute. Pick a service and send.',
      [CutColors.blueDark, Color(0xFF0B5CAD)],
    ),
    _Slide(
      Icons.track_changes_rounded,
      'Live status',
      'Follow your request from pending to approved, in real time.',
      [CutColors.blue, Color(0xFF1565C0)],
    ),
    _Slide(
      Icons.notifications_active_rounded,
      'Reminders',
      'Get SMS or email updates, plus a reminder the day before.',
      [Color(0xFF0A4F94), Color(0xFF2A7BD1)],
    ),
  ];

  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
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
          height: widget.height,
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
              itemBuilder: (context, i) => _SlideCard(slide: _slides[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: i == _index ? 20 : 6,
                decoration: BoxDecoration(
                  color: i == _index ? CutColors.blue : CutColors.border,
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
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.colors,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -18,
            child: Icon(slide.icon, size: 96, color: Colors.white.withAlpha(24)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
          ),
        ],
      ),
    );
  }
}