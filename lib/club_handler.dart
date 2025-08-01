import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_multipart/multipart.dart';
import 'db.dart';

final Router clubRoutes = Router()
  ..get('/', _getAllClubs)
  ..post('/', _createClub)
  ..put('/<id|[0-9]+>', _updateClub)
  ..delete('/<id|[0-9]+>', _deleteClub);

final Router uploadRoutes = Router()..post('/', _uploadImage);

Future<Response> _getAllClubs(Request request) async {
  try {
    final clubs = await DB.run((conn) async {
      final results =
          await conn.query('SELECT * FROM clubs ORDER BY created_at DESC');
      return results
          .map((row) => {
                'id': row['id'],
                'title': row['title'],
                'image_url': utf8.decode(row['image_url'].toBytes()),
                'created_at': row['created_at'].toString(),
              })
          .toList();
    });

    return Response.ok(jsonEncode(clubs),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    print('❌ Error: $e');
    return Response.internalServerError(body: 'Failed to fetch clubs');
  }
}

Future<Response> _createClub(Request request) async {
  try {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    final title = data['title'];
    final imageUrl = data['image_url'];

    if (title == null || imageUrl == null) {
      return Response(400, body: 'Missing title or image_url');
    }

    await DB.run((conn) async {
      // Check if club already exists
      final existing = await conn.query(
        'SELECT * FROM clubs WHERE title = ?',
        [title],
      );

      if (existing.isNotEmpty) {
        return Response(409, body: 'Club already exists');
      }

// Proceed to insert
      await conn.query(
        'INSERT INTO clubs (title, image_url) VALUES (?, ?)',
        [title, imageUrl],
      );
    });

    return Response.ok('Club created');
  } catch (e) {
    return Response.internalServerError(body: 'Failed to create club');
  }
}

Future<Response> _updateClub(Request request, String id) async {
  try {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    final title = data['title'];
    final imageUrl = data['image_url'];

    if (title == null || imageUrl == null) {
      return Response(400, body: 'Missing title or image_url');
    }

    final affected = await DB.run((conn) async {
      final result = await conn.query(
        'UPDATE clubs SET title = ?, image_url = ? WHERE id = ?',
        [title, imageUrl, int.parse(id)],
      );
      return result.affectedRows;
    });

    if (affected == 0) return Response(404, body: 'Club not found');

    return Response.ok('Club updated');
  } catch (e) {
    return Response.internalServerError(body: 'Failed to update club');
  }
}

Future<Response> _deleteClub(Request request, String id) async {
  try {
    final affected = await DB.run((conn) async {
      final result =
          await conn.query('DELETE FROM clubs WHERE id = ?', [int.parse(id)]);
      return result.affectedRows;
    });

    if (affected == 0) return Response(404, body: 'Club not found');

    return Response.ok('Club deleted');
  } catch (e) {
    return Response.internalServerError(body: 'Failed to delete club');
  }
}

Future<Response> _uploadImage(Request request) async {
  try {
    final transformer = MimeMultipartTransformer(
        request.headers['content-type']!.split("; ")[1].split("=")[1]);
    final parts = await transformer.bind(request.read()).toList();

    for (var part in parts) {
      final contentDisposition = part.headers['content-disposition']!;
      final nameMatch = RegExp(r'name="(.+?)"').firstMatch(contentDisposition);
      final filenameMatch =
          RegExp(r'filename="(.+?)"').firstMatch(contentDisposition);

      if (nameMatch != null &&
          nameMatch.group(1) == 'image' &&
          filenameMatch != null) {
        final filename = filenameMatch.group(1)!;
        final bytes = await part.fold<List<int>>([], (a, b) => a..addAll(b));

        final uploadDir = Directory('uploads');
        if (!uploadDir.existsSync()) uploadDir.createSync(recursive: true);

        final file = File('uploads/$filename');
        await file.writeAsBytes(bytes);

        final imageUrl = 'http://10.148.5.132:8080/uploads/$filename';
        return Response.ok(jsonEncode({'url': imageUrl}),
            headers: {'Content-Type': 'application/json'});
      }
    }

    return Response(400, body: 'Invalid image upload');
  } catch (e) {
    return Response.internalServerError(body: 'Error uploading image: $e');
  }
}
