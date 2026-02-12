import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://httpstat.us', // удобно для теста 400/401/500
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(_LogInterceptor());
}

/// Логирование запросов/ответов/ошибок через Interceptor
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('➡️ [DIO][REQ] ${options.method} ${options.baseUrl}${options.path}');
    debugPrint('   headers: ${options.headers}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('   query: ${options.queryParameters}');
    }
    if (options.data != null) {
      debugPrint('   body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ [DIO][RES] ${response.statusCode} ${response.requestOptions.path}');
    debugPrint('   data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode;
    debugPrint('❌ [DIO][ERR] type=${err.type} status=$code path=${err.requestOptions.path}');
    debugPrint('   message: ${err.message}');
    handler.next(err);
  }
}

/// -------------------------
/// 2) Error mapping: 400/401/500 + no network
/// -------------------------
String userMessageFromDio(DioException e) {
  // Отмена запроса
  if (e.type == DioExceptionType.cancel) {
    return 'Запрос отменён.';
  }

  // Таймауты
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'Слишком долго нет ответа. Проверьте интернет и попробуйте снова.';
  }

  // Нет сети / проблемы соединения (часто сюда попадает airplane mode, Wi-Fi off и т.п.)
  if (e.type == DioExceptionType.connectionError) {
    return 'Нет соединения с интернетом. Проверьте сеть.';
  }

  // Сервер вернул ответ с кодом
  if (e.type == DioExceptionType.badResponse) {
    final status = e.response?.statusCode;

    if (status == 400) return 'Ошибка 400: Некорректный запрос.';
    if (status == 401) return 'Ошибка 401: Необходима авторизация.';
    if (status != null && status >= 500) return 'Ошибка сервера ($status). Попробуйте позже.';

    return 'Ошибка запроса (код: $status).';
  }

  return 'Неизвестная ошибка. Попробуйте ещё раз.';
}

/// -------------------------
/// 3) UI screen with CancelToken + dispose cancel
/// -------------------------
enum DemoCase { ok200, bad400, unauth401, server500, longDelay }

class DioDemoPage extends StatefulWidget {
  const DioDemoPage({super.key});

  @override
  State<DioDemoPage> createState() => _DioDemoPageState();
}

class _DioDemoPageState extends State<DioDemoPage> {
  final Dio _dio = ApiClient.dio;
  CancelToken? _cancelToken;

  DemoCase _case = DemoCase.ok200;

  bool _loading = false;
  String? _resultText; // success or error text

  @override
  void dispose() {
    // ✅ отменяем запрос при уходе со страницы
    _cancelToken?.cancel('Page disposed');
    super.dispose();
  }

  String _pathForCase(DemoCase c) {
    // httpstat.us возвращает нужные коды
    switch (c) {
      case DemoCase.ok200:
        return '/200';
      case DemoCase.bad400:
        return '/400';
      case DemoCase.unauth401:
        return '/401';
      case DemoCase.server500:
        return '/500';
      case DemoCase.longDelay:
        // задержка ответа (можно поймать таймаут, если timeout меньше delay)
        return '/200?sleep=12000'; // 12 секунд
    }
  }

  Future<void> _load() async {
    // если уже есть запрос — отменим и создадим новый
    _cancelToken?.cancel('New request started');
    _cancelToken = CancelToken();

    setState(() {
      _loading = true;
      _resultText = null;
    });

    try {
      final path = _pathForCase(_case);

      final res = await _dio.get(
        path,
        cancelToken: _cancelToken,
      );

      setState(() {
        _resultText = 'Успех ✅\nstatus: ${res.statusCode}\nbody: ${res.data}';
      });
    } on DioException catch (e) {
      setState(() {
        _resultText = 'Ошибка ❌\n${userMessageFromDio(e)}';
      });
    } catch (e) {
      setState(() {
        _resultText = 'Ошибка ❌\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _cancel() {
    _cancelToken?.cancel('User canceled');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dio: baseUrl + interceptors + cancel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Выбери сценарий:', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<DemoCase>(
                      value: _case,
                      items: const [
                        DropdownMenuItem(value: DemoCase.ok200, child: Text('200 OK')),
                        DropdownMenuItem(value: DemoCase.bad400, child: Text('400 Bad Request')),
                        DropdownMenuItem(value: DemoCase.unauth401, child: Text('401 Unauthorized')),
                        DropdownMenuItem(value: DemoCase.server500, child: Text('500 Server Error')),
                        DropdownMenuItem(value: DemoCase.longDelay, child: Text('Delay (try timeout)')),
                      ],
                      onChanged: _loading ? null : (v) => setState(() => _case = v!),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _loading ? null : _load,
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Send request'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _loading ? _cancel : null,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _resultText == null
                      ? const Center(child: Text('Нажми "Send request"'))
                      : SingleChildScrollView(child: Text(_resultText!)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Логи смотри в Debug Console (VS Code/Android Studio).',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
