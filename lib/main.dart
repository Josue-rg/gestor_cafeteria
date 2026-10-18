import 'package:flutter/material.dart';
import 'core/http_client.dart';

void main() {
  // Monta la interfaz (sin esto no se ve ninguna ventana)
  runApp(const MainApp());

  // Prueba de la API en segundo plano (no bloquea la interfaz)
  // Nota: 10.0.2.2 solo sirve en el emulador de Android;
  // en Windows/web usa localhost.
  final clientePrueba = ApiClient(baseUrl: 'http://localhost:8000');
  clientePrueba.get('/orders').then(
        (respuesta) => debugPrint('Respuesta API: $respuesta'),
        onError: (Object e) => debugPrint('Error API: $e'),
      );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
