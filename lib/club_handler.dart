import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'db.dart';

final Router clubRoutes = Router()
  ..get('/', _getAllClubs)
  ..post('/', _createClub)
  ..put('/<id|[0-9]+>', _updateClub)
  ..delete('/<id|[0-9]+>', _deleteClub);

Future<Response> _getAllClubs(Request request) async {
  final conn = DB.connection;
  final results =
      await conn.query('SELECT * FROM clubs ORDER BY created_at DESC');

  final clubs = results
      .map((row) => {
            'id': row['id'],
            'title': row['title'],
            'image_url': utf8.decode(row['image_url'].toBytes()),
            'created_at': row['created_at'].toString(),
          })
      .toList();

  return Response.ok(jsonEncode(clubs),
      headers: {'Content-Type': 'application/json'});
}

Future<Response> _createClub(Request request) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final title = data['title'];
  final imageUrl = data['image_url'];

  if (title == null || imageUrl == null) {
    return Response(400, body: 'Missing title or image_url');
  }

  final conn = DB.connection;
  await conn.query(
      'INSERT INTO clubs (title, image_url) VALUES (?, ?)', [title, imageUrl]);

  return Response.ok('Club created');
}

Future<Response> _updateClub(Request request, String id) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final title = data['title'];
  final imageUrl = data['image_url'];

  if (title == null || imageUrl == null) {
    return Response(400, body: 'Missing title or image_url');
  }

  final conn = DB.connection;
  final result = await conn.query(
    'UPDATE clubs SET title = ?, image_url = ? WHERE id = ?',
    [title, imageUrl, int.parse(id)],
  );

  if (result.affectedRows == 0) {
    return Response(404, body: 'Club not found');
  }

  return Response.ok('Club updated');
}

Future<Response> _deleteClub(Request request, String id) async {
  final conn = DB.connection;
  final result =
      await conn.query('DELETE FROM clubs WHERE id = ?', [int.parse(id)]);

  if (result.affectedRows == 0) {
    return Response(404, body: 'Club not found');
  }

  return Response.ok('Club deleted');
}
