// Tests básicos para Smart Sales Mobile
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movile_2ex/app.dart';

void main() {
  testWidgets('App smoke test - verifica que se carga correctamente', (
    WidgetTester tester,
  ) async {
    // Construir la app y renderizar un frame
    await tester.pumpWidget(const ProviderScope(child: SmartSalesApp()));

    // Verificar que el título aparece
    expect(find.text('Smart Sales'), findsOneWidget);

    // Verificar que el subtítulo aparece
    expect(find.text('E-commerce Mobile App'), findsOneWidget);

    // Verificar que el icono de shopping bag aparece
    expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
  });
}
