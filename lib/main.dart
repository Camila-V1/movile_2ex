import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

/// Punto de entrada de la aplicación Smart Sales
///
/// Configuración inicial:
/// - Riverpod como gestor de estado global
/// - Stripe para pagos
/// - Firebase (Push Notifications)
/// - Material Design 3
/// - Backend: https://backend-2ex-ecommerce.onrender.com
void main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (requiere google-services.json en android/app/)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado en main.dart');
  } catch (e) {
    print('⚠️ Error inicializando Firebase: $e');
    print('   Nota: Necesitas agregar google-services.json para usar push notifications');
  }

  // Configurar Stripe con la clave publicable
  Stripe.publishableKey =
      'pk_test_51SExMoHicqevsHU17bgk9ul6DyKqMv75LDtRHgFOtIT70LF1ZQPGp9pXpMMJsoxerR90YtdDJqLrM3Po9idv7yrb0071UU6csG';

  // Aplicar configuración de Stripe
  await Stripe.instance.applySettings();

  // Ejecutar la app envuelta en ProviderScope para Riverpod
  runApp(const ProviderScope(child: SmartSalesApp()));
}
