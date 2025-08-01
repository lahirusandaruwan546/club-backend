import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';

import '../lib/db.dart';
import '../lib/club_handler.dart';

Future<void> main() async {
  // Load environment variables
  DotEnv().load();

  // Initialize DB connection
  await DB.init();

  // Setup routes
  final router = Router()..mount('/clubs', clubRoutes);

  // Add middleware if needed (like logging, CORS etc.)

  // Start server
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('✅ Server running on http://localhost:${server.port}');
}
