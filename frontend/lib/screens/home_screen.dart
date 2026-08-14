import 'package:cardwise_ai/providers/app_providers.dart';
import 'package:cardwise_ai/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'CardWise',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: chat.clear,
                icon: const Icon(Icons.add),
                label: const Text('New chat'),
              ),
            ],
          ),
        ),
        Expanded(
          child: chat.messages.isEmpty
              ? const _EmptyChat()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chat.messages.length + (chat.loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chat.messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _TypingBubble(),
                        ),
                      );
                    }

                    final message = chat.messages[index];
                    return Align(
                      alignment: message.fromUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: message.recommendation == null
                              ? _Bubble(message: message)
                              : RecommendationCardView(
                                  result: message.recommendation!,
                                ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'I am spending ₹12,000 on Swiggy',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: chat.loading ? null : _send,
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _send() {
    final text = _controller.text;
    _controller.clear();
    context.read<ChatProvider>().send(text);
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final offset = ((_controller.value + (index * .18)) % 1 - .5)
                  .abs();
              return Transform.translate(
                offset: Offset(0, -6 * (1 - offset * 2).clamp(0, 1)),
                child: Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .72),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: message.fromUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.text,
        style: TextStyle(color: message.fromUser ? Colors.black : Colors.white),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.primary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              'Ask before you pay',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try: I am spending ₹12,000 on Amazon',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
