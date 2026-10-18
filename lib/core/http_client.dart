import 'dart:convert';
import 'package:http/http.dart' as http;
import 'failure.dart';

//clase client
class ApiClient {
  //D2: propiedades NO nulables (se elimino el operador "!")
  final http.Client _client;
  final String baseUrl;

  ApiClient({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? 'http://localhost:8000';

  //post, get, patch, delete
  //D1: se elimino el metodo update()
  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Object body) => _send('POST', path, body);
  Future<dynamic> patch(String path, Object body) =>
      _send('PATCH', path, body);
  Future<void> delete(String path) => _send('DELETE', path);

//Funcion SEND -> Mandar la peticion al Servicio, esperar una respuesta y
//adecuarlo para flutter
  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse(baseUrl).resolve(path))
      ..headers['Content-Type'] = 'application/json';

    if (body != null) {
      request.body = jsonEncode(body);
    }

    //guargar respuesta de servicio
    final http.Response response;
    //el response se va a tratar segun el caso con el que respondio
    try {
      final streamed = await _client.send(request);
      response = await http.Response.fromStream(streamed);
    } on http.ClientException {
      throw const NetworkFailure();
    }

    final json = _tryDecode(response);
    final code = response.statusCode;

    //D3: exito SOLO en 2xx (200 inclusive, 300 exclusivo)
    if (code >= 200 && code < 300) return json;
    throw mapHttpError(code, json);
  }

  dynamic _tryDecode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

//Direccionamiento de los errores fuera de los 2xx
  Failure mapHttpError(int code, Object? json) {
    return switch (code) {
      404 => NotFoundFailure(_detailFrom(json) ?? 'Recurso no encontrado'),
      409 => ConflictFailure(_detailFrom(json) ?? 'Conflicto en la solicitud'),
      422 => ValidationFailure(_fieldsFrom(json)),
      >= 500 && < 600 => ServerFailure(code),
      _ => UnexpectedFailure(code, 'Error desconocido ($code)'),
    };
  }

  //Extrae el "detail" cuando el body viene como objeto JSON
  //ej: {"detail": "Order 9 not found"} -> "Order 9 not found"
  String? _detailFrom(Object? json) {
    if (json is Map && json['detail'] is String) {
      return json['detail'] as String;
    }
    return null;
  }

  Map<String, String> _fieldsFrom(Object? json) {
    final fields = <String, String>{};
    if (json is Map && json['detail'] is List) {
      for (final error in json['detail'] as List) {
        if (error is Map && error['loc'] is List && error['msg'] is String) {
          final loc = error['loc'] as List;
          if (loc.isNotEmpty) {
            //la ultima parte del "loc" es el nombre del campo
            //["body", "customer"] -> "customer"
            fields[loc.last.toString()] = error['msg'] as String;
          }
        }
      }
    }
    return fields;
  }
}
