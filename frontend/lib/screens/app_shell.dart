import 'package:cardwise_ai/screens/cards_screen.dart';
import 'package:cardwise_ai/screens/home_screen.dart';
import 'package:cardwise_ai/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_providers.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _checkedWallet = false;

  final _screens = const [HomeScreen(), CardsScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialState());
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsProvider>();

    if (_checkedWallet &&
        !cards.loading &&
        cards.userCards.isEmpty &&
        _index != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = 1);
      });
    }

    return Scaffold(
      body: SafeArea(child: _screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _loadInitialState() async {
    final cards = context.read<CardsProvider>();
    await cards.load();
    if (!mounted) return;
    setState(() {
      _checkedWallet = true;
      if (cards.userCards.isEmpty) _index = 1;
    });
  }
}
