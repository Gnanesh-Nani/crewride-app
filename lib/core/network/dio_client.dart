import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DioClient {
  static Dio? _dio;
  static CookieJar? _cookieJar;

  static Dio get instance {
    if (_dio != null) return _dio!;

    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL']!,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => true, // Accept all status codes
      ),
    );

    // Cookie handling (for refresh token) - will be initialized async
    _initializeCookieJar(dio);

    _dio = dio;
    return dio;
  }

  /// Initialize the Dio client and cookie jar. Call this once at app startup
  /// (before `runApp`) to ensure cookie handling is ready synchronously.
  static Future<void> init() async {
    if (_dio != null && _cookieJar != null) return;

    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL']!,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => true, // Accept all status codes
      ),
    );

    await _initializeCookieJar(dio);

    _dio = dio;
  }

  static Future<void> _initializeCookieJar(Dio dio) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage('${appDocDir.path}/.cookies/'),
    );
    dio.interceptors.add(CookieManager(_cookieJar!));
  }

  static Future<void> clearCookies() async {
    await _cookieJar?.deleteAll();
  }
}
