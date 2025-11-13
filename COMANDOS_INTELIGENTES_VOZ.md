# 🎯 Sistema Inteligente de Comandos de Voz

## ✅ Nueva Funcionalidad: Detección de Comandos Incompletos

El sistema ahora detecta cuando dices un comando incompleto y te pide que especifiques el producto.

---

## 🎤 Cómo Funciona

### **Escenario 1: Comando Completo** ✅
```
Usuario: "añadir laptop al carrito"
Sistema: ✅ "Laptop agregada al carrito"
```

### **Escenario 2: Comando Incompleto** 🔄
```
Usuario: "añadir al carrito"
Sistema: 🤔 "¿Qué producto quieres agregar? Por ejemplo: Hub USB-C 7 en 1"
Usuario: "laptop"
Sistema: ✅ "Laptop agregada al carrito"
```

### **Escenario 3: Solo Verbo** 🔄
```
Usuario: "quiero"
Sistema: 🤔 "¿Qué producto quieres agregar? Por ejemplo: Mouse Gaming RGB"
Usuario: "mouse"
Sistema: ✅ "Mouse agregado al carrito"
```

---

## 🧠 Detección Inteligente

El sistema detecta automáticamente estos comandos incompletos:

### Comandos que disparan el modo "necesita producto":
```
❌ "añadir al carrito"
❌ "agregar al carrito"
❌ "pon al carrito"
❌ "al carrito"
❌ "añadir"
❌ "agregar"
❌ "quiero"
❌ "dame"
❌ "comprar"
```

### Comandos completos que funcionan directo:
```
✅ "añadir laptop al carrito"
✅ "quiero un mouse"
✅ "dame auriculares"
✅ "comprar teclado"
✅ "agregar celular al carrito"
```

---

## 🔄 Flujo de Conversación

### Ejemplo Completo:

**Usuario:** *Presiona micrófono 🎤*

**Sistema:** 🔊 "¿Qué deseas hacer?"

**Usuario:** "Añadir al carrito"

**Sistema:** 🔊 "¿Qué producto quieres agregar? Por ejemplo: Pelota de Yoga"

**Usuario:** "Pelota de Yoga"

**Sistema:** 🔊 "Pelota de Yoga agregada al carrito"

---

## 📋 Implementación Técnica

### 1. **Detección de Comando Incompleto** (`voice_command_processor.dart`)

```dart
bool _isIncompleteAddCommand(String command) {
  final normalized = _normalize(command);
  
  final incompletePatterns = [
    'anadir al carrito',
    'agregar al carrito',
    'al carrito',
    'anadir',
    'agregar',
    'quiero',
    'dame',
    'comprar',
  ];

  // Si el comando es exactamente uno de estos (sin producto)
  for (final pattern in incompletePatterns) {
    if (normalized.trim() == pattern) {
      return true;
    }
  }

  // Si tiene menos de 3 palabras y contiene "añadir/agregar"
  final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
  if (words.length <= 3) {
    final hasAddKeyword = ['anadir', 'agregar', 'pon'].any((k) => normalized.contains(k));
    final hasCartKeyword = ['carrito', 'carro', 'cesta'].any((k) => normalized.contains(k));
    
    if (hasAddKeyword && hasCartKeyword && words.length <= 3) {
      return true;
    }
  }

  return false;
}
```

### 2. **Sugerencia Inteligente de Productos**

Cuando detecta comando incompleto:
1. Obtiene productos populares del backend
2. Sugiere el primer producto como ejemplo
3. Espera a que el usuario diga el nombre del producto

```dart
Future<VoiceCommandResult> _handleIncompleteCommand(String command) async {
  // Obtener productos populares
  final response = await _apiService.get(
    '/api/products/',
    queryParameters: {
      'ordering': '-average_rating',
      'page_size': '5',
    },
  );

  // Sugerir el producto más popular
  return VoiceCommandResult(
    success: false,
    action: VoiceAction.needsProduct,
    message: '¿Qué producto quieres agregar? Por ejemplo: ${products.first.name}',
    suggestedProducts: products,
  );
}
```

### 3. **Manejo en Voice Button** (`voice_button.dart`)

```dart
final result = await widget.commandProcessor.processCommand(command);

// ✅ Si necesita especificar producto, escuchar de nuevo
if (result.action == VoiceAction.needsProduct) {
  await _voiceService.speak(result.message);
  await Future.delayed(const Duration(milliseconds: 1500));
  await _voiceService.stopSpeaking();
  
  // Escuchar el nombre del producto
  final productCommand = await _voiceService.listen();
  
  if (productCommand != null && productCommand.isNotEmpty) {
    // Construir comando completo
    final fullCommand = 'añadir $productCommand al carrito';
    
    // Procesar comando completo
    final newResult = await widget.commandProcessor.processCommand(fullCommand);
    await _voiceService.speak(newResult.message);
    widget.onCommandProcessed(newResult);
  }
}
```

---

## 🧪 Pruebas

### Test 1: Comando Incompleto
```bash
# 1. Presiona micrófono
# 2. Di: "añadir al carrito"
# 3. Espera sugerencia
# 4. Di: "laptop"
# 5. Verifica que se agregue
```

### Test 2: Comando Completo
```bash
# 1. Presiona micrófono
# 2. Di: "añadir laptop al carrito"
# 3. Verifica que se agregue directo (sin preguntar)
```

### Test 3: Solo Verbo
```bash
# 1. Presiona micrófono
# 2. Di: "quiero"
# 3. Espera sugerencia
# 4. Di: "mouse"
# 5. Verifica que se agregue
```

---

## 📊 Logs Esperados

### Comando Incompleto:
```
I/flutter: 🎤 Reconocido FINAL: Añadir al carrito
I/flutter:  Procesando comando: "Añadir al carrito"
I/flutter: ⚠️ Comando incompleto detectado: "Añadir al carrito"
I/flutter: 🔍 Obteniendo productos populares para sugerencia...
I/flutter: ✅ Encontrados 5 productos populares
I/flutter: 🎤 Reconocido FINAL: laptop
I/flutter: 🔄 Reintentando con comando completo: "añadir laptop al carrito"
I/flutter: 🤖 Enviando comando al backend NLP: "añadir laptop al carrito"
I/flutter: ✅ Backend validó 1 items para agregar
```

### Comando Completo:
```
I/flutter: 🎤 Reconocido FINAL: Añadir laptop al carrito
I/flutter:  Procesando comando: "Añadir laptop al carrito"
I/flutter: 🤖 Enviando comando al backend NLP: "Añadir laptop al carrito"
I/flutter: ✅ Backend validó 1 items para agregar
```

---

## 🎯 Ventajas del Sistema

### Antes:
- ❌ Usuario dice "añadir al carrito" → Error
- ❌ Backend busca producto llamado "al carrito"
- ❌ Usuario confundido

### Ahora:
- ✅ Usuario dice "añadir al carrito" → Sistema pregunta
- ✅ Usuario especifica producto → Sistema agrega
- ✅ Conversación natural y fluida

---

## 🚀 Cómo Usar

1. **Presiona micrófono** 🎤
2. **Espera** "¿Qué deseas hacer?"
3. **Di tu comando**:
   - Completo: "añadir laptop al carrito"
   - Incompleto: "añadir al carrito" (sistema te preguntará)
4. **Si pregunta**, di el nombre del producto
5. **Confirma** cuando diga "agregado al carrito"

---

## 🔧 Archivos Modificados

- ✅ `lib/core/services/voice_command_processor.dart`
  - Añadido `_isIncompleteAddCommand()`
  - Añadido `_handleIncompleteCommand()`
  - Nuevo enum `VoiceAction.needsProduct`

- ✅ `lib/core/widgets/voice_button.dart`
  - Manejo de `VoiceAction.needsProduct`
  - Segunda escucha automática
  - Construcción de comando completo

---

**¡Ahora puedes usar comandos naturales y el sistema te guiará si falta información!** 🎉
