import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';

class DB {
  static MySqlConnection? _connection;

  // Initialize connection
  static Future<void> init() async {
    final env = DotEnv()..load();

    final host = env['DB_HOST'];
    final port = env['DB_PORT'];
    final user = env['DB_USER'];
    final password = env['DB_PASSWORD'];
    final dbName = env['DB_NAME'];

    if ([host, port, user, password, dbName].any((e) => e == null)) {
      throw Exception("❌ Missing required environment variables in .env file");
    }

    final settings = ConnectionSettings(
      host: host!,
      port: int.parse(port!),
      user: user!,
      password: password!,
      db: dbName!,
    );

    _connection = await MySqlConnection.connect(settings);
    print('✅ Connected to MySQL database');
  }

  static MySqlConnection get connection {
    if (_connection == null) {
      throw Exception('Database not initialized. Call DB.init() first.');
    }
    return _connection!;
  }

  static Future<void> close() async {
    await _connection?.close();
  }
}
