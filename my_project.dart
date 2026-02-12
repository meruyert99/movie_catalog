import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Animations Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_DemoItem>[
      _DemoItem(
        title: '1) Staggered (Interval) demo',
        subtitle: 'Последовательные эффекты на 1 контроллере',
        builder: (_) => const StaggeredDemo(),
      ),
      _DemoItem(
        title: '2) Hero list → details',
        subtitle: 'Hero + fade-in деталей на detail экране',
        builder: (_) => const HeroListScreen(),
      ),
      _DemoItem(
        title: '3) Onboarding (PageView)',
        subtitle: '3 экрана + анимированные индикаторы',
        builder: (_) => const OnboardingScreen(),
      ),
      _DemoItem(
        title: '4) Lottie (loading/success)',
        subtitle: 'Lottie.network + переключение состояний',
        builder: (_) => const LottieDemo(),
      ),
      _DemoItem(
        title: '5) AnimatedList add/remove',
        subtitle: 'Появление/удаление элементов',
        builder: (_) => const AnimatedListDemo(),
      ),
      _DemoItem(
        title: '6) AnimatedSwitcher',
        subtitle: 'Разные transitionBuilder',
        builder: (_) => const AnimatedSwitcherDemo(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animations — Copy/Paste Demo'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final it = items[i];
          return Card(
            child: ListTile(
              title: Text(it.title),
              subtitle: Text(it.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  fadeSlideRoute(it.builder(context)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DemoItem {
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
  _DemoItem({required this.title, required this.subtitle, required this.builder});
}

/// Custom transition: Fade + Slide (PageRouteBuilder)
PageRouteBuilder<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final fade = FadeTransition(opacity: curve, child: child);

      final slide = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0.02),
          end: Offset.zero,
        ).animate(curve),
        child: fade,
      );

      return slide;
    },
  );
}

/// ------------------------------
/// 1) STAGGERED: Interval на одном контроллере
/// ------------------------------
class StaggeredDemo extends StatefulWidget {
  const StaggeredDemo({super.key});

  @override
  State<StaggeredDemo> createState() => _StaggeredDemoState();
}

class _StaggeredDemoState extends State<StaggeredDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _opacity = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.00, 0.35, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.25, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.45, 1.00, curve: Curves.easeOutCubic),
      ),
    );

    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staggered (Interval)')),
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Opacity(
              opacity: _opacity.value,
              child: SlideTransition(
                position: _slide,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Staggered card',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Opacity → Scale → Slide\n(через Interval на одном контроллере)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton(
                                onPressed: () => _c.forward(from: 0),
                                child: const Text('Replay'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: () => _c.reverse(),
                                child: const Text('Reverse'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ------------------------------
/// 2) HERO: список → details + fade-in деталей
/// ------------------------------
class HeroListScreen extends StatelessWidget {
  const HeroListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = List.generate(
      8,
      (i) => _HeroItem(
        id: 'item_$i',
        title: 'Movie #${i + 1}',
        subtitle: 'Tap to open details',
        seed: i + 10,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Hero list → details')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = data[i];
          return Card(
            child: ListTile(
              leading: Hero(
                tag: item.id,
                child: _Avatar(seed: item.seed, size: 46),
              ),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  fadeSlideRoute(HeroDetailsScreen(item: item)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HeroItem {
  final String id;
  final String title;
  final String subtitle;
  final int seed;
  _HeroItem({required this.id, required this.title, required this.subtitle, required this.seed});
}

class HeroDetailsScreen extends StatefulWidget {
  final _HeroItem item;
  const HeroDetailsScreen({super.key, required this.item});

  @override
  State<HeroDetailsScreen> createState() => _HeroDetailsScreenState();
}

class _HeroDetailsScreenState extends State<HeroDetailsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: item.id,
                child: _Avatar(seed: item.seed, size: 120),
              ),
            ),
            const SizedBox(height: 18),
            FadeTransition(
              opacity: _fade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Details appear smoothly after navigation.\n'
                    'Это просто FadeTransition на detail экране.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Genre', value: 'Sci-Fi / Drama'),
                  _InfoRow(label: 'Year', value: '20${item.seed}'),
                  _InfoRow(label: 'Rating', value: '${(item.seed % 10) + 1}.0 / 10'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final int seed;
  final double size;
  const _Avatar({required this.seed, required this.size});

  @override
  Widget build(BuildContext context) {
    // Без картинок: рисуем градиентный круг детерминированно по seed.
    final r = math.Random(seed);
    final c1 = Color.fromARGB(255, r.nextInt(255), r.nextInt(255), r.nextInt(255));
    final c2 = Color.fromARGB(255, r.nextInt(255), r.nextInt(255), r.nextInt(255));

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
        ),
        child: Center(
          child: Text(
            String.fromCharCode(65 + (seed % 26)),
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// 3) ONBOARDING: PageView + анимированные точки
/// ------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _index = 0;

  final _pages = const [
    _OnbPage(icon: Icons.auto_awesome, title: 'Welcome', text: '3 экрана PageView + индикаторы.'),
    _OnbPage(icon: Icons.layers, title: 'Learn', text: 'Делаем UI-эффекты аккуратно и просто.'),
    _OnbPage(icon: Icons.rocket_launch, title: 'Start', text: 'Готово! Можно идти в приложение.'),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _pc.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding (PageView)')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _pages[i],
            ),
          ),
          _Dots(count: _pages.length, index: _index),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => _pc.animateToPage(
                    _pages.length - 1,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                  ),
                  child: const Text('Skip'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _next,
                  child: Text(_index == _pages.length - 1 ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _OnbPage({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 72),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}

/// ------------------------------
/// 4) LOTTIE: loading/success
/// ------------------------------
class LottieDemo extends StatefulWidget {
  const LottieDemo({super.key});

  @override
  State<LottieDemo> createState() => _LottieDemoState();
}

enum _LottieState { idle, loading, success }

class _LottieDemoState extends State<LottieDemo> {
  _LottieState state = _LottieState.idle;

  // Lottie JSON по сети (чтобы всё работало без assets)
  static const _loadingUrl = 'https://assets9.lottiefiles.com/packages/lf20_usmfx6bp.json';
  static const _successUrl = 'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json';

  Future<void> _simulate() async {
    setState(() => state = _LottieState.loading);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => state = _LottieState.success);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => state = _LottieState.idle);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (state) {
      case _LottieState.idle:
        content = const Icon(Icons.play_circle, size: 90);
        break;
      case _LottieState.loading:
        content = Lottie.network(_loadingUrl, width: 160, height: 160);
        break;
      case _LottieState.success:
        content = Lottie.network(_successUrl, width: 160, height: 160, repeat: false);
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lottie loading/success')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: SizedBox(
                    key: ValueKey(state),
                    width: 180,
                    height: 180,
                    child: Center(child: content),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'State: $state',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: state == _LottieState.loading ? null : _simulate,
                  child: const Text('Run loading → success'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// 5) AnimatedList: add/remove
/// ------------------------------
class AnimatedListDemo extends StatefulWidget {
  const AnimatedListDemo({super.key});

  @override
  State<AnimatedListDemo> createState() => _AnimatedListDemoState();
}

class _AnimatedListDemoState extends State<AnimatedListDemo> {
  final _key = GlobalKey<AnimatedListState>();
  final List<int> _items = [1, 2, 3];

  void _add() {
    final next = (_items.isEmpty ? 1 : (_items.last + 1));
    _items.add(next);
    _key.currentState?.insertItem(_items.length - 1, duration: const Duration(milliseconds: 280));
  }

  void _remove(int index) {
    final removed = _items.removeAt(index);
    _key.currentState?.removeItem(
      index,
      (context, animation) => _animatedTile(removed, animation, removing: true),
      duration: const Duration(milliseconds: 280),
    );
  }

  Widget _animatedTile(int value, Animation<double> animation, {bool removing = false}) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          child: ListTile(
            title: Text('Item $value'),
            subtitle: Text(removing ? 'Removing...' : 'Swipe/tap delete'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: removing ? null : () {
                final idx = _items.indexOf(value);
                if (idx != -1) _remove(idx);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnimatedList add/remove'),
        actions: [
          IconButton(onPressed: _add, icon: const Icon(Icons.add)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedList(
          key: _key,
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) {
            final value = _items[index];
            return GestureDetector(
              onLongPress: () => _remove(index),
              child: _animatedTile(value, animation),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ------------------------------
/// 6) AnimatedSwitcher: разные transitionBuilder
/// ------------------------------
class AnimatedSwitcherDemo extends StatefulWidget {
  const AnimatedSwitcherDemo({super.key});

  @override
  State<AnimatedSwitcherDemo> createState() => _AnimatedSwitcherDemoState();
}

class _AnimatedSwitcherDemoState extends State<AnimatedSwitcherDemo> {
  bool _toggle = true;
  int _mode = 0;

  Widget _transition(Widget child, Animation<double> animation) {
    switch (_mode) {
      case 0:
        // Fade + Scale
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation), child: child),
        );
      case 1:
        // Slide from bottom + fade
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      default:
        // Rotation + fade
        return FadeTransition(
          opacity: animation,
          child: RotationTransition(turns: Tween<double>(begin: 0.98, end: 1.0).animate(animation), child: child),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetA = Container(
      key: const ValueKey('A'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Content A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    );

    final widgetB = Container(
      key: const ValueKey('B'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Content B', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('AnimatedSwitcher transitions')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: _transition,
                  child: _toggle ? widgetA : widgetB,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => setState(() => _toggle = !_toggle),
                      child: const Text('Toggle A/B'),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() => _mode = (_mode + 1) % 3),
                      child: Text('Mode: $_mode'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
