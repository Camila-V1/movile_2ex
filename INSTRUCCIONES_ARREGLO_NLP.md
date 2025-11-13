# 🔧 Instrucciones: Arreglar Sistema NLP para Agregar al Carrito

## 🐛 Problema Identificado

El backend y los frontends (Web React + Flutter) **no están sincronizados**:

### Backend espera:
```json
POST /api/orders/cart/add-natural-language/
{
  "prompt": "Agrega 2 laptops al carrito"
}
```

### Backend devuelve:
```json
{
  "success": true,
  "message": "Se encontraron 2 producto(s) para agregar al carrito",
  "prompt": "Agrega 2 laptops al carrito",
  "interpreted_action": "add",
  "items": [
    {
      "product_id": 12,
      "name": "Laptop HP Pavilion",
      "price": "1299.99",
      "quantity": 2,
      "subtotal": "2599.98",
      "stock_available": 15,
      "image_url": "https://..."
    }
  ],
  "total": "2599.98",
  "cart_action": "add_to_cart"
}
```

### ⚠️ Problemas encontrados:
1. **Frontend Web envía** `text` en vez de `prompt` ❌
2. **Frontend Flutter envía** `text` en vez de `prompt` ❌
3. **Backend NO añade al carrito** - solo devuelve productos validados
4. **Frontends NO leen** el array `items` correctamente
5. **Frontends NO llaman** `addToCart`/`addItem` por cada producto

---

## 📋 INSTRUCCIONES PARA FRONTEND WEB (React)

### Archivo a modificar: `src/pages/Cart.jsx` (o similar)

**Busca la función que llama al endpoint NLP** (probablemente cerca de la línea donde dice `cart/add-natural-language`).

### CAMBIO 1: Enviar `prompt` en vez de `text`

**❌ ANTES (INCORRECTO):**
```javascript
const res = await api.post('orders/cart/add-natural-language/', { 
  text: command  // ❌ INCORRECTO
});
```

**✅ DESPUÉS (CORRECTO):**
```javascript
const res = await api.post('orders/cart/add-natural-language/', { 
  prompt: command  // ✅ CORRECTO
});
```

### CAMBIO 2: Leer `items` y agregar cada producto al carrito

**❌ ANTES (INCORRECTO):**
```javascript
const res = await api.post('orders/cart/add-natural-language/', { prompt: command });
console.log('✅ Respuesta del servidor:', res.data);
console.log('📦 Agregando productos al carrito:', res.data.added_items); // ❌ NO EXISTE

// ❌ NO HACE NADA - el carrito queda vacío
```

**✅ DESPUÉS (CORRECTO):**
```javascript
const res = await api.post('orders/cart/add-natural-language/', { prompt: command });

if (res.data.success && res.data.items && res.data.items.length > 0) {
  // ✅ Iterar items y agregar cada uno al carrito
  res.data.items.forEach(item => {
    // Asumiendo que tienes una función addToCart o dispatch
    addToCart({
      productId: item.product_id,
      name: item.name,
      price: parseFloat(item.price),
      quantity: item.quantity,
      imageUrl: item.image_url
    });
    
    // O si usas Redux/Context:
    // dispatch(addItemToCart({ ...item }));
  });

  // Mostrar mensaje de éxito
  showNotification(`✅ ${res.data.items.length} producto(s) añadido(s) al carrito`, 'success');
  
  // Actualizar total del carrito
  updateCartTotal();
} else {
  showNotification(`❌ ${res.data.message || 'No se encontraron productos'}`, 'error');
}
```

### CAMBIO 3: Implementación completa recomendada

```javascript
const handleNLPCommand = async (command) => {
  try {
    setLoading(true);
    
    const response = await api.post('orders/cart/add-natural-language/', { 
      prompt: command 
    });

    if (response.data.success && response.data.cart_action === 'add_to_cart') {
      const items = response.data.items || [];
      
      if (items.length === 0) {
        toast.warning('No se encontraron productos con ese nombre');
        return;
      }

      // Agregar cada item al carrito (LOCAL)
      items.forEach(item => {
        dispatch(addToCart({
          id: item.product_id,
          name: item.name,
          price: parseFloat(item.price),
          quantity: item.quantity,
          image: item.image_url,
          stock: item.stock_available
        }));
      });

      // Mensaje de éxito
      const totalQty = items.reduce((sum, item) => sum + item.quantity, 0);
      toast.success(`✅ ${items.length} producto(s) añadido(s) (x${totalQty}) - Total: $${response.data.total}`);
      
      // Opcional: navegar al carrito
      // navigate('/cart');
      
    } else {
      toast.error(response.data.error || 'No se pudo procesar el comando');
    }
    
  } catch (error) {
    console.error('Error NLP:', error);
    toast.error('Error al procesar comando de voz');
  } finally {
    setLoading(false);
  }
};
```

---

## 📱 INSTRUCCIONES PARA FRONTEND FLUTTER

### Archivo a modificar: `lib/core/services/voice_command_processor.dart`

**YA LO MODIFIQUÉ**, pero aquí está el resumen de lo que cambió:

### CAMBIO 1: Método `_handleAddToCart` ahora usa el endpoint NLP

**✅ YA CORREGIDO EN EL ARCHIVO:**
```dart
Future<VoiceCommandResult> _handleAddToCart(String command) async {
  try {
    print('🤖 Enviando comando al backend NLP: "$command"');

    // ✅ Llamar al endpoint NLP del backend
    final response = await _apiService.post(
      '/api/orders/cart/add-natural-language/',
      data: {'prompt': command}, // ✅ CORRECTO: usa 'prompt'
    );

    if (response.statusCode == 200) {
      final data = response.data;

      // ✅ Leer 'items' del backend (no 'added_items')
      final items = data['items'] as List<dynamic>?;

      if (items != null && items.isNotEmpty) {
        print('✅ Backend validó ${items.length} items para agregar');

        return VoiceCommandResult(
          success: true,
          action: VoiceAction.addToCartNLP,
          message: data['message'] ?? 'Productos listos para agregar',
          addedItems: items.map((item) => CartItemFromNLP.fromJson(item)).toList(),
        );
      } else {
        return VoiceCommandResult(
          success: false,
          action: VoiceAction.addToCart,
          message: data['message'] ?? 'No se encontraron productos',
        );
      }
    }

    return VoiceCommandResult(
      success: false,
      action: VoiceAction.addToCart,
      message: 'Error al procesar el comando',
    );
  } catch (e) {
    print('❌ Error en _handleAddToCart: $e');
    return VoiceCommandResult(
      success: false,
      action: VoiceAction.addToCart,
      message: 'Ocurrió un error al procesar el comando',
    );
  }
}
```

### CAMBIO 2: Archivo `product_catalog_screen.dart` - Método `_handleVoiceCommand`

**⚠️ ESTE ARCHIVO NO SE ACTUALIZÓ CORRECTAMENTE** - Necesitas hacer esto manualmente:

**Ubicación:** `lib/features/products/screens/product_catalog_screen.dart` línea ~71

**REEMPLAZA TODO EL MÉTODO `_handleVoiceCommand`:**

```dart
void _handleVoiceCommand(VoiceCommandResult result) {
  // ✅ Manejar casos donde success=false pero hay acción especial
  if (!result.success && result.action != VoiceAction.confirmProduct) {
    _showMessage(result.message, isError: true);
    return;
  }

  switch (result.action) {
    case VoiceAction.addToCart:
      _addToCartFromVoice(result.product!, result.quantity!);
      break;

    case VoiceAction.addToCartNLP:
      // ✅ NUEVO: El backend validó los items, ahora agregar al carrito
      _handleNLPCartAddition(result);
      break;

    case VoiceAction.confirmProduct:
      // Mostrar diálogo de confirmación (si hay múltiples productos)
      _showProductConfirmation(result.suggestedProducts ?? []);
      break;

    case VoiceAction.search:
      _searchController.text = result.searchTerm!;
      setState(() {});
      break;

    case VoiceAction.showCart:
      context.push('/cart');
      break;

    case VoiceAction.clearCart:
      ref.read(cartProvider.notifier).clearCart();
      _showMessage('Carrito vaciado', isError: false);
      break;

    case VoiceAction.unknown:
      _showMessage(result.message, isError: true);
      break;
  }
}
```

**AGREGA ESTOS DOS MÉTODOS NUEVOS** (después de `_handleVoiceCommand`):

```dart
// ✅ NUEVO MÉTODO: Manejar adición desde NLP
void _handleNLPCartAddition(VoiceCommandResult result) {
  if (result.addedItems == null || result.addedItems!.isEmpty) {
    _showMessage('No se añadieron productos', isError: true);
    return;
  }

  // Iterar cada item y agregarlo al carrito usando el provider
  for (var item in result.addedItems!) {
    try {
      // Buscar el producto completo para tener toda la info
      final product = Product(
        id: item.productId,
        name: item.name,
        price: item.price,
        // Los demás campos se llenarán cuando se refresque
      );

      ref.read(cartProvider.notifier).addItem(product, quantity: item.quantity);
    } catch (e) {
      print('❌ Error agregando item ${item.name}: $e');
    }
  }

  // Mostrar mensaje de éxito
  final count = result.addedItems!.length;
  final totalQty = result.addedItems!.fold(0, (sum, item) => sum + item.quantity);
  
  _showMessage(
    '✅ $count producto(s) añadido(s) al carrito (x$totalQty)',
    isError: false,
  );
}

// ✅ NUEVO MÉTODO: Mostrar confirmación si hay múltiples productos
void _showProductConfirmation(List<Product> products) {
  if (products.isEmpty) return;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Cuál de estos productos quieres agregar?'),
          const SizedBox(height: 16),
          ...products.take(3).map((product) => ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            onTap: () {
              Navigator.pop(context);
              _addToCartFromVoice(product, 1);
            },
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}
```

### CAMBIO 3: Actualizar CartItemFromNLP

**Ya está en el archivo `voice_command_processor.dart`**, pero verifica que tenga estos campos:

```dart
class CartItemFromNLP {
  final int productId;
  final String name;
  final int quantity;
  final double price;

  CartItemFromNLP({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory CartItemFromNLP.fromJson(Map<String, dynamic> json) {
    return CartItemFromNLP(
      productId: json['product_id'] ?? json['id'],
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}
```

---

## ✅ CHECKLIST DE VERIFICACIÓN

### Para el equipo Web:
- [ ] Cambiar `data: { text: ... }` por `data: { prompt: ... }`
- [ ] Leer `response.data.items` (no `added_items`)
- [ ] Iterar `items` y llamar `addToCart()` por cada uno
- [ ] Mostrar mensaje de éxito con cantidad total
- [ ] Actualizar UI del carrito después de agregar

### Para el equipo Flutter:
- [ ] Verificar que `voice_command_processor.dart` usa `'prompt'` en POST
- [ ] Verificar que lee `data['items']` del response
- [ ] Reemplazar método `_handleVoiceCommand` en `product_catalog_screen.dart`
- [ ] Agregar métodos `_handleNLPCartAddition` y `_showProductConfirmation`
- [ ] Probar comando: "Agrega 2 laptops al carrito"

---

## 🧪 CÓMO PROBAR

### Prueba 1: Comando simple
```
Comando: "Agrega laptop al carrito"
Esperado: Se busca producto con "laptop", se valida stock, se agrega 1 unidad
```

### Prueba 2: Comando con cantidad
```
Comando: "Quiero 3 mouse"
Esperado: Se busca producto con "mouse", se valida stock>=3, se agregan 3 unidades
```

### Prueba 3: Producto no encontrado
```
Comando: "Agrega producto inexistente al carrito"
Esperado: Mensaje "No se encontraron productos con ese nombre"
```

### Prueba 4: Stock insuficiente
```
Comando: "Agrega 100 laptops al carrito"
Esperado: Mensaje "Stock insuficiente para [nombre]. Stock disponible: X"
```

---

## 📞 Si necesitas ayuda adicional

**Verifica los logs del backend en Render:**
```bash
# Deberías ver:
🌐 REQUEST: POST /api/orders/cart/add-natural-language/
🌐 RESPONSE: 200 for /api/orders/cart/add-natural-language/
```

**Verifica los logs del frontend:**
- **Web:** Console del navegador → buscar "🤖 Procesando comando NLP"
- **Flutter:** Logcat/Console → buscar "🤖 Enviando comando al backend NLP"

---

## 🎯 RESUMEN EJECUTIVO

**El problema NO está en el backend** - el backend funciona perfectamente y devuelve los productos correctamente.

**El problema está en los frontends:**
1. ❌ Envían `text` en vez de `prompt`
2. ❌ No leen el array `items` del response
3. ❌ No llaman a `addToCart` por cada item

**Solución:** Los frontends deben:
1. ✅ Enviar `{ prompt: comando }`
2. ✅ Leer `response.data.items`
3. ✅ Iterar items y llamar `addToCart(item)` por cada uno

**Tiempo estimado de corrección:**
- Web: 10-15 minutos
- Flutter: 15-20 minutos (si copias/pegas el código de arriba)
