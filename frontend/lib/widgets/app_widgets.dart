import 'dart:ui';

import 'package:cardwise_ai/models/card_models.dart';
import 'package:cardwise_ai/models/recommendation.dart';
import 'package:cardwise_ai/providers/app_providers.dart';
import 'package:cardwise_ai/widgets/card_visual_parts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Color parseColor(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

class CreditCardTile extends StatelessWidget {
  const CreditCardTile({
    super.key,
    required this.card,
    this.userCard,
    this.trailing,
  });

  final CatalogCard card;
  final UserCard? userCard;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bg = parseColor(card.visual.backgroundColor);
    final fg = parseColor(card.visual.textColor);
    final accent = parseColor(card.visual.accentColor);
    final bgEnd = _gradientEnd(bg);
    final issuerText = card.visual.issuerLabel.isEmpty
        ? card.issuer
        : card.visual.issuerLabel;
    final brandText = card.visual.brandLabel.isEmpty
        ? card.name
        : card.visual.brandLabel;
    final nameText = userCard?.nickname.isNotEmpty == true
        ? userCard!.nickname
        : card.name;
    final network = userCard?.network ?? '';

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bgEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: const DiagonalTexturePainter()),
            ),
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -70,
              bottom: -90,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          issuerText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _dim(fg, 0.82),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (trailing != null)
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              iconTheme: IconThemeData(color: _dim(fg, 0.85)),
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: trailing,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CardChip(),
                      const SizedBox(width: 12),
                      ContactlessIcon(color: fg, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    brandText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nameText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _dim(fg, 0.75),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '•••• XXXX',
                              style: TextStyle(
                                color: _dim(fg, 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      NetworkBadge(network: network, color: fg),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _gradientEnd(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
}

Color _dim(Color fg, double alpha) => fg.withValues(alpha: alpha);

class RecommendationCardView extends StatelessWidget {
  const RecommendationCardView({super.key, required this.result});

  final RecommendationResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Best card', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              result.recommendedCard.cardName,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated reward: ₹${result.recommendedCard.estimatedReward.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            Text(result.recommendedCard.reason),
            const Divider(height: 24),
            Text('Alternatives', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ...result.alternatives
                .skip(1)
                .take(3)
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${card.cardName}: ₹${card.estimatedReward.toStringAsFixed(0)}',
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        context.read<ChatProvider>().confirmUsed(result, true),
                    child: const Text('Used this card'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.read<ChatProvider>().confirmUsed(result, false),
                    child: const Text('Didn’t use'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
