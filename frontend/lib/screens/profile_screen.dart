import 'package:cardwise_ai/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  String _avatarValue = '';
  String _initialName = '';
  String _initialAvatarValue = '';
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    _name.addListener(_handleProfileDraftChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final profile = auth.user?['profile'] ?? {};
      final name = profile['name'] ?? '';
      final avatarValue = (profile['avatarSvg'] ?? '').toString().isNotEmpty
          ? profile['avatarSvg']
          : profile['avatarUrl'] ?? '';
      _initialName = name;
      _initialAvatarValue = avatarValue;
      _name.text = name;
      _avatarValue = avatarValue;
      context.read<ProfileProvider>().loadStats(_period);
    });
  }

  @override
  void dispose() {
    _name.removeListener(_handleProfileDraftChanged);
    _name.dispose();
    super.dispose();
  }

  void _handleProfileDraftChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final stats = profile.stats;
    final total = ((stats?['totalEstimatedRewards'] ?? 0) as num).toDouble();
    final hasProfileChanges =
        _name.text.trim() != _initialName.trim() ||
        _avatarValue.trim() != _initialAvatarValue.trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: _EditableAvatar(
            value: _avatarValue,
            fallbackText:
                (_name.text.isEmpty ? (auth.user?['email'] ?? 'C') : _name.text)
                    .substring(0, 1)
                    .toUpperCase(),
            onEdit: _showAvatarDialog,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          readOnly: true,
          initialValue: auth.user?['email'] ?? '',
          decoration: const InputDecoration(labelText: 'Email'),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: hasProfileChanges
                ? () async {
                    final parsedAvatar = _parseAvatarValue(_avatarValue);
                    final user = await context
                        .read<ProfileProvider>()
                        .updateProfile(
                          name: _name.text,
                          avatarUrl: parsedAvatar.url,
                          avatarSvg: parsedAvatar.svg,
                        );
                    if (!context.mounted) return;
                    context.read<AuthProvider>().setUser(user);
                    setState(() {
                      _initialName = _name.text;
                      _initialAvatarValue = _avatarValue;
                    });
                  }
                : null,
            child: const Text('Save profile'),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CardWise profit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'week', label: Text('Week')),
                    ButtonSegment(value: 'month', label: Text('Month')),
                    ButtonSegment(value: 'year', label: Text('Year')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (value) {
                    setState(() => _period = value.first);
                    context.read<ProfileProvider>().loadStats(_period);
                  },
                ),
                const SizedBox(height: 16),
                _RewardBars(
                  points: List<Map<String, dynamic>>.from(
                    stats?['points'] ?? const [],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: auth.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ),
      ],
    );
  }

  Future<void> _showAvatarDialog() async {
    final controller = TextEditingController(text: _avatarValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: const Text('Edit profile logo'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(320.0, 560.0),
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Enter Image URL or SVG code',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _avatarValue = result);
  }

  _ParsedAvatar _parseAvatarValue(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('<svg')) return _ParsedAvatar(svg: trimmed, url: '');
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _ParsedAvatar(svg: '', url: trimmed);
    }
    return const _ParsedAvatar(svg: '', url: '');
  }
}

class _ParsedAvatar {
  const _ParsedAvatar({required this.svg, required this.url});

  final String svg;
  final String url;
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.value,
    required this.fallbackText,
    required this.onEdit,
  });

  final String value;
  final String fallbackText;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final parsed = _parse(value);

    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: ClipOval(
              child: SizedBox(
                width: 72,
                height: 72,
                child: parsed.svg.isNotEmpty
                    ? SvgPicture.string(parsed.svg, fit: BoxFit.cover)
                    : parsed.url.isNotEmpty
                    ? Image.network(parsed.url, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          fallbackText,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            right: 3,
            bottom: 3,
            child: SizedBox(
              width: 26,
              height: 26,
              child: IconButton.filled(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 13),
                tooltip: 'Edit logo',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(26, 26),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ParsedAvatar _parse(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('<svg')) return _ParsedAvatar(svg: trimmed, url: '');
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _ParsedAvatar(svg: '', url: trimmed);
    }
    return const _ParsedAvatar(svg: '', url: '');
  }
}

class _RewardBars extends StatelessWidget {
  const _RewardBars({required this.points});

  final List<Map<String, dynamic>> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: Text('Confirmed recommendations will appear here.'),
        ),
      );
    }
    final maxValue = points
        .map((point) => (point['estimatedReward'] as num).toDouble())
        .fold<double>(0, (max, value) => value > max ? value : max);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.take(12).map((point) {
          final value = (point['estimatedReward'] as num).toDouble();
          final height = maxValue == 0 ? 0.0 : (value / maxValue) * 96;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: height + 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
