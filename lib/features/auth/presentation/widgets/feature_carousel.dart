import 'package:flutter/material.dart';

class FeatureCarousel extends StatefulWidget {
  const FeatureCarousel({super.key});

  @override
  State<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends State<FeatureCarousel> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startCarouselScroll();
  }

  void _startCarouselScroll() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _animateToNextCard();
    });
  }

  void _animateToNextCard() {
    if (!mounted) return;

    // Calculate card width based on screen width minus padding
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 48.0; // 24px padding on each side
    final cardGap = 12.0;
    final cardWithGap = cardWidth + cardGap;

    // Current scroll position
    double currentScroll = _scrollController.offset;
    double nextScroll = currentScroll + cardWithGap;

    // Check if we've reached the end, if so reset
    if (nextScroll >= _scrollController.position.maxScrollExtent) {
      nextScroll = 0;
    }

    // Animate to next card over 500ms
    _scrollController
        .animateTo(
          nextScroll,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        )
        .then((_) {
          // Wait 1 second then scroll to next card
          Future.delayed(const Duration(seconds: 1), () {
            _animateToNextCard();
          });
        });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: const _FeatureCard(
                    icon: Icons.groups_rounded,
                    title: 'Group Riding',
                    description: 'Perfect for riding together',
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: cardWidth,
                  child: const _FeatureCard(
                    icon: Icons.location_on_rounded,
                    title: 'Friend Location',
                    description: 'Get friends\' location in real-time',
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: cardWidth,
                  child: const _FeatureCard(
                    icon: Icons.chat_rounded,
                    title: 'Stay Connected',
                    description: 'Communicate on long trips',
                  ),
                ),
                const SizedBox(width: 12),
                // Loop back to first item for continuous scroll
                SizedBox(
                  width: cardWidth,
                  child: const _FeatureCard(
                    icon: Icons.groups_rounded,
                    title: 'Group Riding',
                    description: 'Perfect for riding together',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon and title in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description below
          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
