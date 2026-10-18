import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';

void main() {
  group('Failure (clase sellada)', () {
    test('NetworkFailure implementa Exception con mensaje por defecto', () {
      const failure = NetworkFailure();

      expect(failure, isA<Exception>());
      expect(failure.message, isNotEmpty);
    });

    test('ServerFailure conserva el statusCode', () {
      const failure = ServerFailure(503);

      expect(failure.statusCode, 503);
      expect(failure.message, isNotEmpty);
    });

    test('NotFoundFailure conserva el mensaje recibido', () {
      const failure = NotFoundFailure('Order 9 not found');

      expect(failure.message, 'Order 9 not found');
    });

    test('ConflictFailure conserva el mensaje recibido', () {
      const failure = ConflictFailure('Estado no permitido');

      expect(failure.message, 'Estado no permitido');
    });

    test('ValidationFailure conserva el mapa de campos', () {
      const failure = ValidationFailure({'customer': 'Must be 1-50 characters'});

      expect(failure.fields['customer'], 'Must be 1-50 characters');
    });

    test('UnexpectedFailure conserva statusCode y mensaje', () {
      const failure = UnexpectedFailure(300, 'Error desconocido (300)');

      expect(failure.statusCode, 300);
      expect(failure.message, contains('300'));
    });
  });
}
