import 'dart:async';

import 'package:cardwise_ai/models/card_models.dart';
import 'package:cardwise_ai/providers/app_providers.dart';
import 'package:cardwise_ai/widgets/app_widgets.dart';
import 'package:cardwise_ai/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  bool _addSheetOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cards = context.read<CardsProvider>();
      if (cards.catalog.isEmpty && !cards.loading) cards.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsProvider>();

    if (!_addSheetOpened &&
        !cards.loading &&
        cards.userCards.isEmpty &&
        cards.catalog.isNotEmpty) {
      _addSheetOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAddCard(context, cards.catalog, onboarding: true);
      });
    }

    return LoadingOverlay(
      visible: cards.loading,
      child: RefreshIndicator(
        onRefresh: cards.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My cards',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.icon(
                  onPressed: cards.catalog.isEmpty
                      ? null
                      : () => _showAddCard(context, cards.catalog),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cards.error != null)
              Text(
                cards.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (!cards.loading && cards.userCards.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text('Add your first card to unlock recommendations.'),
                ),
              ),
            ...cards.userCards.map(
              (userCard) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: CreditCardTile(
                  card: userCard.card,
                  userCard: userCard,
                  trailing: IconButton(
                    tooltip: 'Remove',
                    onPressed: () =>
                        context.read<CardsProvider>().removeCard(userCard),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCard(
    BuildContext context,
    List<CatalogCard> catalog, {
    bool onboarding = false,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AddCardSheet(
        catalog: catalog,
        onboarding: onboarding,
        onAdd: (card) {
          Navigator.pop(context);
          this.context.read<CardsProvider>().addCard(card);
        },
      ),
    );
  }
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet({
    required this.catalog,
    required this.onboarding,
    required this.onAdd,
  });

  final List<CatalogCard> catalog;
  final bool onboarding;
  final ValueChanged<CatalogCard> onAdd;

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<CatalogCard> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _results = widget.catalog;
    _controller.addListener(_queueSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_queueSearch)
      ..dispose();
    super.dispose();
  }

  void _queueSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _results = widget.catalog;
          _searching = false;
        });
      }
      return;
    }

    setState(() => _searching = true);
    try {
      final cards = await context.read<CardsProvider>().searchCatalog(query);
      if (!mounted) return;
      setState(() {
        _results = cards;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = _localSearch(query);
        _searching = false;
      });
    }
  }

  List<CatalogCard> _localSearch(String query) {
    final normalized = _normalize(query);
    final tokens = normalized.split(' ').where((token) => token.isNotEmpty);
    final scored = <({CatalogCard card, int score})>[];

    for (final card in widget.catalog) {
      final target = _normalize('${card.name} ${card.issuer}');
      var score = 0;
      for (final token in tokens) {
        if (target.contains(token)) {
          score += 3;
        } else if (target.split(' ').any((part) => _isNear(token, part))) {
          score += 1;
        } else {
          score = 0;
          break;
        }
      }
      if (score > 0) scored.add((card: card, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((item) => item.card).take(50).toList();
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  bool _isNear(String left, String right) {
    if (left.length < 3 || right.length < 3) return false;
    final distance = _editDistance(left, right);
    return distance <= (left.length <= 5 ? 1 : 2);
  }

  int _editDistance(String left, String right) {
    final previous = List<int>.generate(right.length + 1, (index) => index);
    final current = List<int>.filled(right.length + 1, 0);

    for (var i = 1; i <= left.length; i += 1) {
      current[0] = i;
      for (var j = 1; j <= right.length; j += 1) {
        final cost = left.codeUnitAt(i - 1) == right.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = [
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (var j = 0; j <= right.length; j += 1) {
        previous[j] = current[j];
      }
    }

    return previous[right.length];
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.onboarding ? 'Add your first card' : 'Add card',
                style: theme.textTheme.titleLarge,
              ),
              if (widget.onboarding) ...[
                const SizedBox(height: 6),
                const Text(
                  'CardWise needs your owned cards before it can recommend one.',
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search card or bank',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: _controller.clear,
                        ),
                ),
              ),
              const SizedBox(height: 10),
              if (_searching) const LinearProgressIndicator(minHeight: 2),
              if (!_searching) const SizedBox(height: 2),
              const SizedBox(height: 8),
              Expanded(
                child: _results.isEmpty
                    ? const Center(child: Text('No matching cards found.'))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final card = _results[index];
                          return ListTile(
                            title: Text(card.name),
                            subtitle: Text(card.issuer),
                            trailing: const Icon(Icons.add),
                            onTap: () => widget.onAdd(card),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
