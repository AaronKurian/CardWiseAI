class RecommendationResult {
  const RecommendationResult({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.recommendedCard,
    required this.alternatives,
    required this.disclaimer,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    final input = json['input'] as Map<String, dynamic>;
    return RecommendationResult(
      amount: (input['amount'] as num).toDouble(),
      merchant: input['merchant'],
      category: input['category'],
      recommendedCard: RecommendationCard.fromJson(json['recommendedCard']),
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((item) => RecommendationCard.fromJson(item))
          .toList(),
      disclaimer: json['disclaimer'] ?? '',
    );
  }

  final double amount;
  final String merchant;
  final String category;
  final RecommendationCard recommendedCard;
  final List<RecommendationCard> alternatives;
  final String disclaimer;
}

class RecommendationCard {
  const RecommendationCard({
    required this.userCardId,
    required this.cardId,
    required this.cardName,
    required this.issuer,
    required this.estimatedReward,
    required this.reason,
  });

  factory RecommendationCard.fromJson(Map<String, dynamic> json) {
    return RecommendationCard(
      userCardId: json['userCardId'],
      cardId: json['cardId'],
      cardName: json['cardName'],
      issuer: json['issuer'],
      estimatedReward: (json['estimatedReward'] as num).toDouble(),
      reason: json['reason'] ?? '',
    );
  }

  final String userCardId;
  final String cardId;
  final String cardName;
  final String issuer;
  final double estimatedReward;
  final String reason;
}
