import 'package:cardwise_ai/models/card_models.dart';
import 'package:cardwise_ai/models/recommendation.dart';
import 'package:cardwise_ai/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<ChangeNotifierProvider<ChangeNotifier>> buildProviders(ApiClient api) {
  return [
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(api)..restoreSession(),
    ),
    ChangeNotifierProvider<CardsProvider>(create: (_) => CardsProvider(api)),
    ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider(api)),
    ChangeNotifierProvider<ProfileProvider>(
      create: (_) => ProfileProvider(api),
    ),
  ];
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  final ApiClient _api;
  bool ready = false;
  bool loading = false;
  String? token;
  Map<String, dynamic>? user;
  String? error;

  bool get isAuthenticated => token != null;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    _api.token = token;
    if (token != null) {
      try {
        final response = await _api.get('/api/auth/me');
        user = response['user'];
      } catch (_) {
        await prefs.remove('token');
        token = null;
        _api.token = null;
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> submit({
    required String email,
    required String password,
    required bool register,
    String name = '',
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.post(
        register ? '/api/auth/register' : '/api/auth/login',
        {'email': email, 'password': password, 'name': name},
      );
      token = response['token'];
      user = response['user'];
      _api.token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token!);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    token = null;
    user = null;
    _api.token = null;
    notifyListeners();
  }

  void setUser(Map<String, dynamic> nextUser) {
    user = nextUser;
    notifyListeners();
  }
}

class CardsProvider extends ChangeNotifier {
  CardsProvider(this._api);

  final ApiClient _api;
  List<CatalogCard> catalog = [];
  List<UserCard> userCards = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _api.post('/api/cards/catalog/seed');
      final catalogResponse = await _api.get('/api/cards/catalog');
      final mineResponse = await _api.get('/api/cards/mine');
      catalog = (catalogResponse['cards'] as List<dynamic>)
          .map((json) => CatalogCard.fromJson(json))
          .toList();
      userCards = (mineResponse['cards'] as List<dynamic>)
          .map((json) => UserCard.fromJson(json))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addCard(CatalogCard card) async {
    final network = card.networkOptions.isNotEmpty
        ? card.networkOptions.first
        : '';
    await _api.post('/api/cards/mine', {'cardId': card.id, 'network': network});
    await load();
  }

  Future<List<CatalogCard>> searchCatalog(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return catalog;

    final response = await _api.get(
      '/api/cards/catalog?q=${Uri.encodeQueryComponent(trimmed)}',
    );
    return (response['cards'] as List<dynamic>)
        .map((json) => CatalogCard.fromJson(json))
        .toList();
  }

  Future<void> removeCard(UserCard card) async {
    await _api.delete('/api/cards/mine/${card.id}');
    await load();
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    this.recommendation,
  });

  final String text;
  final bool fromUser;
  final RecommendationResult? recommendation;
}

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._api);

  final ApiClient _api;
  final List<ChatMessage> messages = [];
  bool loading = false;
  String? error;

  List<Map<String, dynamic>> _recommendationContext() => messages
      .where((message) => message.recommendation != null)
      .map((message) {
        final result = message.recommendation!;
        return {
          'amount': result.amount,
          'merchant': result.merchant,
          'category': result.category,
          'recommendedCard': result.recommendedCard.cardName,
          'estimatedReward': result.recommendedCard.estimatedReward,
        };
      })
      .toList();

  void clear() {
    messages.clear();
    error = null;
    notifyListeners();
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    messages.add(ChatMessage(text: text.trim(), fromUser: true));
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.post('/api/recommendations/chat', {
        'message': text,
        'sessionContext': {'recommendations': _recommendationContext()},
      });
      if (response['needsManualInput'] == true) {
        messages.add(ChatMessage(text: response['message'], fromUser: false));
      } else if (response['type'] == 'assistant_reply') {
        messages.add(ChatMessage(text: response['message'], fromUser: false));
      } else {
        final result = RecommendationResult.fromJson(
          response['recommendation'],
        );
        messages.add(
          ChatMessage(
            text:
                'Use ${result.recommendedCard.cardName} for ${result.merchant}.',
            fromUser: false,
            recommendation: result,
          ),
        );
      }
    } catch (e) {
      error = e.toString();
      messages.add(ChatMessage(text: error!, fromUser: false));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> confirmUsed(RecommendationResult result, bool used) async {
    final card = result.recommendedCard;
    await _api.post('/api/recommendations/confirm', {
      'merchant': result.merchant,
      'category': result.category,
      'amount': result.amount,
      'recommendedUserCardId': card.userCardId,
      'recommendedCatalogCardId': card.cardId,
      'estimatedReward': card.estimatedReward,
      'usedRecommendedCard': used,
      'source': 'chat',
    });
    messages.add(
      ChatMessage(
        text: used
            ? 'Saved. This reward now counts toward your CardWise profit.'
            : 'Noted. This recommendation will not count toward your rewards.',
        fromUser: false,
      ),
    );
    notifyListeners();
  }
}

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._api);

  final ApiClient _api;
  Map<String, dynamic>? stats;
  bool loading = false;

  Future<void> loadStats([String period = 'month']) async {
    loading = true;
    notifyListeners();
    final response = await _api.get('/api/profile/reward-stats?period=$period');
    stats = response['stats'];
    loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String avatarUrl,
    required String avatarSvg,
  }) async {
    final response = await _api.patch('/api/profile', {
      'name': name,
      'avatarUrl': avatarUrl,
      'avatarSvg': avatarSvg,
    });
    return response['user'];
  }
}
