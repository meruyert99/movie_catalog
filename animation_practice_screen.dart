import 'package:flutter/material.dart';

class AnimationPracticeScreen extends StatefulWidget {
  const AnimationPracticeScreen({super.key});

  @override
  State<AnimationPracticeScreen> createState() =>
      _AnimationPracticeScreenState();
}

class _AnimationPracticeScreenState extends State<AnimationPracticeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _scale = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(curved);

    _offset = Tween<Offset>(
      begin: const Offset(-100, 0),
      end: const Offset(100, 0),
    ).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose(); // ОБЯЗАТЕЛЬНО
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animation practice')),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          child: Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'BOX',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          builder: (context, child) {
            return Transform.translate(
              offset: _offset.value,
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _controller.forward(),
                child: const Text('Start'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _controller.stop(),
                child: const Text('Stop'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _controller.reverse(),
                child: const Text('Reverse'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
