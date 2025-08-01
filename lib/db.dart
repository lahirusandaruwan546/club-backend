import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';
import 'package:pool/pool.dart';

class DB {
  static late ConnectionSettings _settings;
  static final Pool _pool = Pool(5); // max 5 parallel DB connections

  static void init() {
    final env = DotEnv()..load();

    final host = env['DB_HOST'];
    final port = env['DB_PORT'];
    final user = env['DB_USER'];
    final password = env['DB_PASSWORD'];
    final dbName = env['DB_NAME'];

    if ([host, port, user, password, dbName].any((e) => e == null)) {
      throw Exception("❌ Missing environment variables in .env");
    }

    _settings = ConnectionSettings(
      host: host!,
      port: int.parse(port!),
      user: user!,
      password: password!,
      db: dbName!,
    );

    print('✅ DB settings loaded');
  }

  static Future<T> run<T>(
      Future<T> Function(MySqlConnection conn) operation) async {
    return await _pool.withResource(() async {
      final conn = await MySqlConnection.connect(_settings);
      try {
        return await operation(conn);
      } finally {
        await conn.close();
      }
    });
  }
}
