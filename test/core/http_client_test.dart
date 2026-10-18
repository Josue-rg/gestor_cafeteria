import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ignore_for_file: prefer_const_constructors

void main() {
  const baseUrl = 'http://prueba.local';

  test('1. Éxito: responde 200 y devuelve JSON decodificado', () async {
    final mock = MockClient((_) async => http.Response('[{"id": 1}]', 200));
    final api = ApiClient(client: mock, baseUrl: baseUrl);

    final resultado = await api.get('/orders');

    expect(resultado, isA<List>());
    expect(resultado.first['id'], equals(1));
  });

  test('2. No encontrado: responde 404 y lanza NotFoundFailure', () async {
    final mock = MockClient((_) async =>
        http.Response('{"detail": "Order 9 not found"}', 404));
    final api = ApiClient(client: mock, baseUrl: baseUrl);

    expect(
      api.get('/orders/9'),
      throwsA(isA<NotFoundFailure>().having(
        (f) => f.message,
        'message',
        'Order 9 not found',
      )),
    );
  });

  test('3. Conflicto: responde 409 y lanza ConflictFailure', () async {
    final mock = MockClient((_) async =>
        http.Response('{"detail": "Estado no permitido"}', 409));
    final api = ApiClient(client: mock, baseUrl: baseUrl);

    expect(
      api.patch('/orders/1', {'status': 'delivered'}),
      throwsA(isA<ConflictFailure>().having(
        (f) => f.message,
        'message',
        'Estado no permitido',
      )),
    );
  });

  test('4. Validación: responde 422 y lanza ValidationFailure con mapa de campos', () async {
    final body = '{"detail": [{"loc": ["body", "customer"], "msg": "Must be 1-50 characters"}]}';
    final mock = MockClient((_) async => http.Response(body, 422));
    final api = ApiClient(client: mock, baseUrl: baseUrl);

    expect(
      api.post('/orders', {}),
      throwsA(isA<ValidationFailure>().having(
        (f) => f.fields['customer'],
        'fields[customer]',
        'Must be 1-50 characters',
      )),
    );
  });

  test('5. Servidor: responde 503 y lanza ServerFailure', () async {
    final mock = MockClient((_) async => http.Response('Error', 503));
    final api = ApiClient(client: mock, baseUrl: baseUrl);

    expect(
      api.get('/orders'),
      throwsA(isA<ServerFailure>().having(
        (f) => f.statusCode,
        'statusCode',
        503,
      )),
    );
  });

  test('6. Sin conexión: falla de red lanza NetworkFailure', () async {
    final mock = MockClient((_) async => throw http.ClientException('sin red'));
    final api = ApiClient(client: mock, baseUrl: baseUrl);

    expect(
      api.get('/orders'),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('7. Redirección (300): no es éxito y lanza UnexpectedFailure', () async {
    final mock = MockClient((_) async => http.Response('{"detail": "Multiple Choices"}', 300));
    final api = ApiClient(client: mock, baseUrl: baseUrl);

    expect(
      api.get('/orders'),
      throwsA(isA<UnexpectedFailure>().having(
        (f) => f.statusCode,
        'statusCode',
        300,
      )),
    );
  });
}
