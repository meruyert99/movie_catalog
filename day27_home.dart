import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Day27AllInOneApp extends StatelessWidget {
  const Day27AllInOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const Day27Home(),
    );
  }
}


class Day27Home extends StatelessWidget {
  const Day27Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day 27: BLoC/Cubit (all-in-one)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NavButton(
              title: 'Cubit: Counter + History',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CounterScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _NavButton(
              title: 'Bloc: Login (loading/success/error)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _NavButton(
              title: 'Loading Screen (3 states + Retry)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoadScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _NavButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(title, textAlign: TextAlign.center),
      ),
    );
  }
}


  final int count;
  final List<String> history; // newest first, max 10
  const CounterState({required this.count, required this.history});

  CounterState copyWith({int? count, List<String>? history}) => CounterState(
        count: count ?? this.count,
        history: history ?? this.history,
      );
}

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(const CounterState(count: 0, history: []));

  void increment() {
    final next = state.count + 1;
    emit(state.copyWith(count: next, history: _push("Increment → $next")));
  }

  void decrement() {
    final next = state.count - 1;
    emit(state.copyWith(count: next, history: _push("Decrement → $next")));
  }

  void clear() {
    emit(const CounterState(count: 0, history: []));
  }

  List<String> _push(String event) {
    final updated = <String>[event, ...state.history];
    return updated.take(10).toList();
  }
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: const _CounterView(),
    );
  }
}

class _CounterView extends StatelessWidget {
  const _CounterView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CounterCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cubit Counter + History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _CounterValue(),
            const SizedBox(height: 16),
            _CounterButtons(
              onDec: cubit.decrement,
              onInc: cubit.increment,
              onClear: cubit.clear,
            ),
            const SizedBox(height: 16),
            const _HistoryTitle(),
            const SizedBox(height: 8),
            const Expanded(child: _HistoryList()),
          ],
        ),
      ),
    );
  }
}


class _CounterValue extends StatelessWidget {
  const _CounterValue();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterCubit, CounterState>(
      buildWhen: (prev, curr) => prev.count != curr.count,
      builder: (_, state) => Text(
        'Count: ${state.count}',
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CounterButtons extends StatelessWidget {
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onClear;

  const _CounterButtons({
    required this.onDec,
    required this.onInc,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(onPressed: onDec, icon: const Icon(Icons.remove)),
        const SizedBox(width: 12),
        IconButton.filled(onPressed: onInc, icon: const Icon(Icons.add)),
        const SizedBox(width: 12),
        IconButton(onPressed: onClear, icon: const Icon(Icons.delete_outline)),
      ],
    );
  }
}

class _HistoryTitle extends StatelessWidget {
  const _HistoryTitle();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text('Last 10 actions:', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// Rebuild only when history changes
class _HistoryList extends StatelessWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CounterCubit, CounterState, List<String>>(
      selector: (state) => state.history,
      builder: (_, history) {
        if (history.isEmpty) return const Center(child: Text('No actions yet.'));
        return ListView.separated(
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(dense: true, title: Text(history[i])),
        );
      },
    );
  }
}

abstract class LoginEvent {}

class EmailChanged extends LoginEvent {
  final String email;
  EmailChanged(this.email);
}

class PasswordChanged extends LoginEvent {
  final String password;
  PasswordChanged(this.password);
}

class LoginSubmitted extends LoginEvent {}

class LoginState {
  final String email;
  final String password;
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  bool get canSubmit => email.isNotEmpty && password.isNotEmpty && !isLoading;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<EmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, error: null, isSuccess: false));
    });

    on<PasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password, error: null, isSuccess: false));
    });

    on<LoginSubmitted>((event, emit) async {
      final email = state.email.trim();
      final password = state.password;

      if (!_isValidEmail(email)) {
        emit(state.copyWith(error: 'Enter a valid email (must contain @ and .)'));
        return;
      }
      if (password.length < 6) {
        emit(state.copyWith(error: 'Password must be at least 6 characters.'));
        return;
      }

      emit(state.copyWith(isLoading: true, error: null, isSuccess: false));

      await Future.delayed(const Duration(seconds: 2));

      // Demo rule: only "123456" succeeds
      if (password == '123456') {
        emit(state.copyWith(isLoading: false, isSuccess: true));
      } else {
        emit(state.copyWith(isLoading: false, error: 'Wrong password.'));
      }
    });
  }

  bool _isValidEmail(String email) => email.contains('@') && email.contains('.');
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bloc Login')),
      body: BlocListener<LoginBloc, LoginState>(
        listenWhen: (prev, curr) =>
            prev.isSuccess != curr.isSuccess || prev.error != curr.error,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login success ✅')),
            );
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: _LoginForm(),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _EmailField(),
        const SizedBox(height: 12),
        const _PasswordField(),
        const SizedBox(height: 16),
        const _SubmitButton(),
        const SizedBox(height: 16),
        const _LoginStatus(),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => context.read<LoginBloc>().add(EmailChanged(v)),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => context.read<LoginBloc>().add(PasswordChanged(v)),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (prev, curr) =>
          prev.canSubmit != curr.canSubmit || prev.isLoading != curr.isLoading,
      builder: (_, state) {
        return FilledButton(
          onPressed: state.canSubmit
              ? () => context.read<LoginBloc>().add(LoginSubmitted())
              : null,
          child: state.isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Login'),
        );
      },
    );
  }
}

class _LoginStatus extends StatelessWidget {
  const _LoginStatus();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (prev, curr) =>
          prev.isLoading != curr.isLoading || prev.isSuccess != curr.isSuccess,
      builder: (_, state) {
        if (state.isLoading) return const Text('Status: loading...');
        if (state.isSuccess) return const Text('Status: success ✅');
        return const Text('Status: idle');
      },
    );
  }
}


enum LoadStatus { loading, success, error }

class LoadCubit extends Cubit<LoadStatus> {
  LoadCubit() : super(LoadStatus.loading);

  Future<void> load() async {
    emit(LoadStatus.loading);
    await Future.delayed(const Duration(seconds: 2));
    final ok = Random().nextBool();
    emit(ok ? LoadStatus.success : LoadStatus.error);
  }
}

class LoadScreen extends StatelessWidget {
  const LoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoadCubit()..load(),
      child: const _LoadView(),
    );
  }
}

class _LoadView extends StatelessWidget {
  const _LoadView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LoadCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Loading Screen')),
      body: Center(
        child: BlocBuilder<LoadCubit, LoadStatus>(
          builder: (_, status) {
            switch (status) {
              case LoadStatus.loading:
                return const _LoadingState();
              case LoadStatus.success:
                return const _SuccessState();
              case LoadStatus.error:
                return _ErrorState(onRetry: cubit.load);
            }
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Loading data...'),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 48),
        SizedBox(height: 12),
        Text('Loaded successfully!'),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        const Text('Something went wrong.'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => onRetry(),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
