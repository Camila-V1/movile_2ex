import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/api/api_service.dart';
import 'core/providers/auth_provider.dart';
import 'shared/constants/app_theme.dart';

/// Widget raíz de la aplicación Smart Sales
class SmartSalesApp extends ConsumerStatefulWidget {
  const SmartSalesApp({super.key});

  @override
  ConsumerState<SmartSalesApp> createState() => _SmartSalesAppState();
}

class _SmartSalesAppState extends ConsumerState<SmartSalesApp> {
  @override
  void initState() {
    super.initState();
    // Inicializar push notifications cuando la app arranca
    _initializePushNotifications();
  }

  Future<void> _initializePushNotifications() async {
    // Esperar un poco para que el auth provider se inicialice
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Solo inicializar si el usuario está autenticado
    if (!mounted) return;
    
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    if (isAuthenticated) {
      print('📱 [APP] Usuario autenticado, inicializando push notifications...');
      try {
        final apiService = ApiService();
        await PushNotificationService.initialize(apiService);
        print('✅ [APP] Push notifications inicializadas desde app.dart');
      } catch (e) {
        print('⚠️ [APP] Error inicializando push notifications: $e');
      }
    } else {
      print('⏭️ [APP] Usuario no autenticado, esperando login para push notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Smart Sales',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
