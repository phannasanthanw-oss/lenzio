// ฟังก์ชันเรียก API: GET และ POST/PUT/DELETE
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

/// GET request — คืน decoded JSON (Map หรือ List)
Future<dynamic> apiGet(String path, [Map<String, String>? query]) async {
  final uri = Uri.parse('$kApiBase$path').replace(queryParameters: query);
  final res = await http.get(uri).timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  return jsonDecode(utf8.decode(res.bodyBytes));
}

/// POST / PUT / DELETE พร้อม JSON body (ไม่บังคับ) — นับ 2xx ว่าสำเร็จ
Future<dynamic> apiSend(String method, String path, [Map<String, dynamic>? body]) async {
  final req = http.Request(method, Uri.parse('$kApiBase$path'));
  req.headers['Content-Type'] = 'application/json';
  if (body != null) req.body = jsonEncode(body);
  final streamed = await req.send().timeout(const Duration(seconds: 20));
  final res = await http.Response.fromStream(streamed);
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode}: ${utf8.decode(res.bodyBytes)}');
  }
  return jsonDecode(utf8.decode(res.bodyBytes));
}

