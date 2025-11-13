# 🔌 Guía de API - Sistema de Devoluciones (Flutter)

## 📋 Índice
1. [Configuración Inicial](#configuración-inicial)
2. [Ver Mis Devoluciones](#1-ver-mis-devoluciones)
3. [Crear Devolución](#2-crear-devolución)
4. [Ver Detalle de Devolución](#3-ver-detalle-de-devolución)
5. [Cancelar Devolución](#4-cancelar-devolución)
6. [Ver Mis Órdenes (con info de devolución)](#5-ver-mis-órdenes)
7. [Errores Comunes](#errores-comunes)

---

## ⚙️ Configuración Inicial

### URL Base
```dart
final String baseUrl = 'https://backend-2ex-ecommerce.onrender.com/api';
```

### Headers Requeridos
```dart
Map<String, String> getHeaders(String token) {
  return {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };
}
```

### Obtener Token (Login)
```dart
// POST /api/token/
Future<String> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/token/'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['access']; // Guardar este token
  } else {
    throw Exception('Credenciales inválidas');
  }
}
```

---

## 1️⃣ Ver Mis Devoluciones

### Endpoint
```
GET /api/deliveries/returns/my-returns/
```

### Función en Flutter
```dart
Future<List<Map<String, dynamic>>> getMisReturns(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/deliveries/returns/my-returns/'),
    headers: getHeaders(token),
  );

  if (response.statusCode == 200) {
    // Decodificar con UTF-8 para caracteres especiales
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return List<Map<String, dynamic>>.from(data);
  } else if (response.statusCode == 401) {
    throw Exception('Token expirado o inválido');
  } else {
    throw Exception('Error al cargar devoluciones: ${response.statusCode}');
  }
}
```

### Respuesta Exitosa (200)
```json
[
  {
    "id": 1,
    "order": 123,
    "order_details": {
      "id": 123,
      "status": "delivered",
      "total_price": "150.00"
    },
    "status": "pending",
    "reason": "defective",
    "description": "El producto llegó dañado",
    "total_refund_amount": "50.00",
    "created_at": "2025-11-13T10:30:00Z",
    "processed_at": null,
    "admin_notes": null,
    "items": [
      {
        "id": 1,
        "order_item": 456,
        "product_name": "Laptop Gaming",
        "quantity": 1,
        "refund_amount": "50.00",
        "product_image": "https://example.com/image.jpg"
      }
    ]
  }
]
```

### Uso en Widget
```dart
class MyReturnsScreen extends StatefulWidget {
  final String token;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getMisReturns(token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No tienes devoluciones'));
        }
        
        final returns = snapshot.data!;
        
        return ListView.builder(
          itemCount: returns.length,
          itemBuilder: (context, index) {
            final returnData = returns[index];
            
            return ListTile(
              title: Text('Devolución #${returnData['id']}'),
              subtitle: Text('Estado: ${returnData['status']}'),
              trailing: Text('\$${returnData['total_refund_amount']}'),
              onTap: () {
                // Navegar a detalle
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReturnDetailScreen(
                      returnId: returnData['id'],
                      token: token,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
```

---

## 2️⃣ Crear Devolución

### Endpoint
```
POST /api/deliveries/returns/
```

### Función en Flutter
```dart
Future<Map<String, dynamic>> crearDevolucion({
  required String token,
  required int orderId,
  required String reason,
  String? description,
  required List<Map<String, dynamic>> items,
}) async {
  final body = json.encode({
    'order_id': orderId,
    'reason': reason,
    'description': description,
    'items': items,
  });

  final response = await http.post(
    Uri.parse('$baseUrl/deliveries/returns/'),
    headers: getHeaders(token),
    body: body,
  );

  if (response.statusCode == 201) {
    return json.decode(utf8.decode(response.bodyBytes));
  } else if (response.statusCode == 400) {
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'Datos inválidos');
  } else if (response.statusCode == 404) {
    throw Exception('Orden no encontrada');
  } else {
    throw Exception('Error al crear devolución: ${response.statusCode}');
  }
}
```

### Ejemplo de Llamada
```dart
// Desde un botón "Solicitar Devolución"
onPressed: () async {
  try {
    final resultado = await crearDevolucion(
      token: miToken,
      orderId: 123,
      reason: 'defective',
      description: 'El producto llegó roto',
      items: [
        {
          'order_item_id': 456, // ID del OrderItem (no del Product)
          'quantity': 1,
        },
        {
          'order_item_id': 457,
          'quantity': 2,
        },
      ],
    );
    
    // Mostrar éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Devolución creada: #${resultado['id']}'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navegar a detalle o volver
    Navigator.pop(context);
    
  } catch (e) {
    // Mostrar error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Request Body Ejemplo
```json
{
  "order_id": 123,
  "reason": "defective",
  "description": "El producto llegó dañado en el empaque",
  "items": [
    {
      "order_item_id": 456,
      "quantity": 1
    }
  ]
}
```

### Respuesta Exitosa (201)
```json
{
  "id": 5,
  "order": 123,
  "order_details": {
    "id": 123,
    "status": "delivered",
    "total_price": "150.00"
  },
  "status": "pending",
  "reason": "defective",
  "description": "El producto llegó dañado en el empaque",
  "total_refund_amount": "50.00",
  "created_at": "2025-11-13T15:45:30Z",
  "processed_at": null,
  "admin_notes": null,
  "items": [
    {
      "id": 10,
      "order_item": 456,
      "product_name": "Laptop Gaming",
      "quantity": 1,
      "refund_amount": "50.00",
      "product_image": "https://example.com/laptop.jpg"
    }
  ]
}
```

### Valores Válidos para `reason`
```dart
enum ReturnReason {
  defective,        // "defective" - Producto defectuoso
  wrongItem,        // "wrong_item" - Artículo incorrecto
  notAsDescribed,   // "not_as_described" - No es como se describe
  changedMind,      // "changed_mind" - Cambié de opinión
  other,            // "other" - Otro (requiere description)
}

// Uso:
final reason = 'defective'; // Enviar el string directamente
```

---

## 3️⃣ Ver Detalle de Devolución

### Endpoint
```
GET /api/deliveries/returns/{id}/
```

### Función en Flutter
```dart
Future<Map<String, dynamic>> getDetalleDevolucion(
  String token,
  int returnId,
) async {
  final response = await http.get(
    Uri.parse('$baseUrl/deliveries/returns/$returnId/'),
    headers: getHeaders(token),
  );

  if (response.statusCode == 200) {
    return json.decode(utf8.decode(response.bodyBytes));
  } else if (response.statusCode == 404) {
    throw Exception('Devolución no encontrada');
  } else if (response.statusCode == 403) {
    throw Exception('No tienes permiso para ver esta devolución');
  } else {
    throw Exception('Error al cargar detalle: ${response.statusCode}');
  }
}
```

### Ejemplo de Uso
```dart
class ReturnDetailScreen extends StatelessWidget {
  final int returnId;
  final String token;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getDetalleDevolucion(token, returnId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        
        return Scaffold(
          appBar: AppBar(title: Text('Devolución #${data['id']}')),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado
                Text(
                  'Estado: ${data['status']}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                
                // Monto
                Text('Reembolso: \$${data['total_refund_amount']}'),
                
                // Motivo
                Text('Motivo: ${data['reason']}'),
                
                // Descripción
                if (data['description'] != null)
                  Text('Descripción: ${data['description']}'),
                
                // Fecha
                Text('Creado: ${data['created_at']}'),
                
                // Notas del admin (si fue rechazada)
                if (data['admin_notes'] != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    color: Colors.red[50],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notas del Administrador:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(data['admin_notes']),
                      ],
                    ),
                  ),
                
                // Items
                SizedBox(height: 16),
                Text(
                  'Productos:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ...((data['items'] as List).map((item) {
                  return ListTile(
                    leading: item['product_image'] != null
                        ? Image.network(item['product_image'], width: 50)
                        : Icon(Icons.image),
                    title: Text(item['product_name']),
                    subtitle: Text('Cantidad: ${item['quantity']}'),
                    trailing: Text('\$${item['refund_amount']}'),
                  );
                })),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### Respuesta Exitosa (200)
```json
{
  "id": 5,
  "order": 123,
  "order_details": {
    "id": 123,
    "status": "delivered",
    "total_price": "150.00",
    "created_at": "2025-11-01T10:00:00Z"
  },
  "status": "approved",
  "reason": "defective",
  "description": "El producto llegó dañado",
  "total_refund_amount": "50.00",
  "created_at": "2025-11-13T10:30:00Z",
  "processed_at": "2025-11-13T14:20:00Z",
  "admin_notes": "Devolución aprobada. Se procesará el reembolso en 24 horas.",
  "items": [
    {
      "id": 10,
      "order_item": 456,
      "product_name": "Laptop Gaming",
      "quantity": 1,
      "refund_amount": "50.00",
      "product_image": "https://example.com/laptop.jpg"
    }
  ]
}
```

---

## 4️⃣ Cancelar Devolución

### Endpoint
```
POST /api/deliveries/returns/{id}/cancel/
```

### Función en Flutter
```dart
Future<void> cancelarDevolucion(String token, int returnId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/deliveries/returns/$returnId/cancel/'),
    headers: getHeaders(token),
  );

  if (response.statusCode == 200) {
    // Cancelado exitosamente
    return;
  } else if (response.statusCode == 400) {
    final error = json.decode(response.body);
    throw Exception(error['error'] ?? 'No se puede cancelar');
  } else if (response.statusCode == 404) {
    throw Exception('Devolución no encontrada');
  } else {
    throw Exception('Error al cancelar: ${response.statusCode}');
  }
}
```

### Ejemplo de Uso
```dart
// Desde un botón "Cancelar Devolución"
onPressed: () async {
  // Confirmar con diálogo
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cancelar Devolución'),
      content: Text('¿Estás seguro de cancelar esta devolución?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Sí, Cancelar'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    await cancelarDevolucion(token, returnId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Devolución cancelada'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context); // Volver a lista
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Respuesta Exitosa (200)
```json
{
  "message": "Devolución cancelada exitosamente"
}
```

### Errores Comunes (400)
```json
{
  "error": "Solo puedes cancelar devoluciones en estado pending"
}
```

---

## 5️⃣ Ver Mis Órdenes

### Endpoint
```
GET /api/orders/
```

### Función en Flutter
```dart
Future<List<Map<String, dynamic>>> getMisOrdenes(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/orders/'),
    headers: getHeaders(token),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return List<Map<String, dynamic>>.from(data);
  } else {
    throw Exception('Error al cargar órdenes: ${response.statusCode}');
  }
}
```

### Respuesta (incluye info de devolución)
```json
[
  {
    "id": 123,
    "status": "delivered",
    "total_price": "150.00",
    "created_at": "2025-11-01T10:00:00Z",
    "can_return": true,
    "return_request_id": 5,
    "items": [
      {
        "id": 456,
        "product": 10,
        "product_name": "Laptop Gaming",
        "quantity": 2,
        "price": "50.00",
        "product_image": "https://example.com/laptop.jpg"
      }
    ]
  }
]
```

### Uso en Widget
```dart
class MyOrdersScreen extends StatelessWidget {
  final String token;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getMisOrdenes(token),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final orders = snapshot.data!;
        
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final isDelivered = order['status'] == 'delivered';
            final canReturn = order['can_return'] == true;
            final hasReturn = order['return_request_id'] != null;
            
            return Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Orden #${order['id']}'),
                    subtitle: Text('Estado: ${order['status']}'),
                    trailing: Text('\$${order['total_price']}'),
                  ),
                  
                  // Botones de acción
                  if (isDelivered && !hasReturn && canReturn)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navegar a crear devolución
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateReturnScreen(
                              order: order,
                              token: token,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.assignment_return),
                      label: Text('Solicitar Devolución'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  
                  if (hasReturn)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navegar a ver devolución
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReturnDetailScreen(
                              returnId: order['return_request_id'],
                              token: token,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.visibility),
                      label: Text('Ver Devolución'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  
                  if (isDelivered && !canReturn && !hasReturn)
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Plazo de devolución expirado (30 días)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
```

---

## ⚠️ Errores Comunes

### 1. Token Expirado (401)
```json
{
  "detail": "Token is invalid or expired",
  "code": "token_not_valid"
}
```

**Solución:** Hacer login de nuevo y obtener nuevo token.

```dart
try {
  await getMisReturns(token);
} catch (e) {
  if (e.toString().contains('401') || e.toString().contains('token')) {
    // Redirigir a login
    Navigator.pushReplacementNamed(context, '/login');
  }
}
```

### 2. Orden No Puede Devolverse (400)
```json
{
  "error": "Solo puedes devolver órdenes entregadas (delivered)"
}
```

**Validar antes:**
```dart
if (order['status'] != 'delivered') {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Solo puedes devolver órdenes entregadas')),
  );
  return;
}

if (order['can_return'] != true) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Plazo de devolución expirado (30 días)')),
  );
  return;
}
```

### 3. Orden Ya Tiene Devolución (400)
```json
{
  "error": "Esta orden ya tiene una devolución activa"
}
```

**Validar antes:**
```dart
if (order['return_request_id'] != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Esta orden ya tiene una devolución')),
  );
  return;
}
```

### 4. Cantidad Inválida (400)
```json
{
  "error": "Cantidad solicitada (3) excede la cantidad disponible (2)"
}
```

**Validar cantidades:**
```dart
for (var item in selectedItems) {
  final orderItem = order['items'].firstWhere((i) => i['id'] == item['order_item_id']);
  
  if (item['quantity'] > orderItem['quantity']) {
    throw Exception(
      'Cantidad solicitada (${item['quantity']}) excede disponible (${orderItem['quantity']})'
    );
  }
}
```

### 5. Items Vacíos (400)
```json
{
  "items": ["Debes incluir al menos un producto para devolver"]
}
```

**Validar antes:**
```dart
if (selectedItems.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Selecciona al menos un producto')),
  );
  return;
}
```

---

## 📊 Resumen de Estados

### Estados de Devolución
```dart
// status field
'pending'    → Pendiente de revisión (amarillo/naranja)
'approved'   → Aprobada por admin (azul)
'rejected'   → Rechazada (rojo)
'completed'  → Reembolso procesado (verde)
```

### Estados de Orden
```dart
// Para que pueda devolverse:
order['status'] == 'delivered'  // Debe estar entregada
order['can_return'] == true      // Dentro de 30 días
order['return_request_id'] == null // Sin devolución activa
```

---

## 🧪 Ejemplo Completo de Flujo

```dart
class ReturnFlowExample extends StatefulWidget {
  final String token;

  @override
  _ReturnFlowExampleState createState() => _ReturnFlowExampleState();
}

class _ReturnFlowExampleState extends State<ReturnFlowExample> {
  Future<void> flujoCompleto() async {
    try {
      // 1. Obtener órdenes
      final orders = await getMisOrdenes(widget.token);
      print('✅ Órdenes cargadas: ${orders.length}');
      
      // 2. Filtrar orden delivered sin devolución
      final orderToReturn = orders.firstWhere(
        (o) => o['status'] == 'delivered' && 
               o['return_request_id'] == null &&
               o['can_return'] == true,
      );
      print('✅ Orden para devolver: #${orderToReturn['id']}');
      
      // 3. Crear devolución
      final newReturn = await crearDevolucion(
        token: widget.token,
        orderId: orderToReturn['id'],
        reason: 'defective',
        description: 'Producto llegó dañado',
        items: [
          {
            'order_item_id': orderToReturn['items'][0]['id'],
            'quantity': 1,
          }
        ],
      );
      print('✅ Devolución creada: #${newReturn['id']}');
      
      // 4. Ver detalle
      final detail = await getDetalleDevolucion(widget.token, newReturn['id']);
      print('✅ Detalle cargado: Estado=${detail['status']}');
      
      // 5. Ver lista de devoluciones
      final myReturns = await getMisReturns(widget.token);
      print('✅ Total devoluciones: ${myReturns.length}');
      
      // 6. (Opcional) Cancelar si está pending
      if (detail['status'] == 'pending') {
        await cancelarDevolucion(widget.token, newReturn['id']);
        print('✅ Devolución cancelada');
      }
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: flujoCompleto,
      child: Text('Probar Flujo Completo'),
    );
  }
}
```

---

## 🎯 Checklist de Implementación

- [ ] Implementar función `login()` para obtener token
- [ ] Implementar función `getMisReturns()` para listar
- [ ] Implementar función `crearDevolucion()` con validaciones
- [ ] Implementar función `getDetalleDevolucion()` para ver detalle
- [ ] Implementar función `cancelarDevolucion()` para pending
- [ ] Implementar función `getMisOrdenes()` para ver órdenes
- [ ] Agregar manejo de errores (try-catch)
- [ ] Agregar decodificación UTF-8 (`utf8.decode()`)
- [ ] Validar `can_return` antes de crear devolución
- [ ] Validar cantidades no excedan disponibles
- [ ] Mostrar mensajes de éxito/error con SnackBar
- [ ] Guardar token en storage local (SharedPreferences)
- [ ] Manejar expiración de token (logout automático)

---

¡Listo! Ahora sabes exactamente **cómo llamar cada función** y **qué respuestas esperar**. 🚀
