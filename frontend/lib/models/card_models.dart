class CardVisual {
  const CardVisual({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.issuerLabel,
    required this.brandLabel,
  });

  factory CardVisual.fromJson(Map<String, dynamic>? json) {
    return CardVisual(
      backgroundColor: json?['backgroundColor'] ?? '#1F2937',
      textColor: json?['textColor'] ?? '#FFFFFF',
      accentColor: json?['accentColor'] ?? '#22C55E',
      issuerLabel: json?['issuerLabel'] ?? '',
      brandLabel: json?['brandLabel'] ?? '',
    );
  }

  final String backgroundColor;
  final String textColor;
  final String accentColor;
  final String issuerLabel;
  final String brandLabel;
}

class CatalogCard {
  const CatalogCard({
    required this.id,
    required this.name,
    required this.issuer,
    required this.networkOptions,
    required this.visual,
  });

  factory CatalogCard.fromJson(Map<String, dynamic> json) {
    return CatalogCard(
      id: json['_id'],
      name: json['name'],
      issuer: json['issuer'],
      networkOptions: List<String>.from(json['networkOptions'] ?? const []),
      visual: CardVisual.fromJson(json['visual']),
    );
  }

  final String id;
  final String name;
  final String issuer;
  final List<String> networkOptions;
  final CardVisual visual;
}

class UserCard {
  const UserCard({
    required this.id,
    required this.card,
    required this.nickname,
    required this.last4,
    required this.network,
  });

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      id: json['_id'],
      card: CatalogCard.fromJson(json['cardId']),
      nickname: json['nickname'] ?? '',
      last4: json['last4'] ?? '',
      network: json['network'] ?? '',
    );
  }

  final String id;
  final CatalogCard card;
  final String nickname;
  final String last4;
  final String network;
}
