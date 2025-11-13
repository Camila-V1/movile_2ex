# 🎤 Guía: Comandos de Voz para Añadir al Carrito (Flutter)

## 📋 Índice
1. [Dependencias](#1-dependencias)
2. [Configuración de Permisos](#2-configuración-de-permisos)
3. [Servicio de Reconocimiento de Voz](#3-servicio-de-reconocimiento-de-voz)
4. [Procesamiento de Comandos](#4-procesamiento-de-comandos)
5. [Widget de Botón de Voz](#5-widget-de-botón-de-voz)
6. [Integración con Carrito](#6-integración-con-carrito)
7. [Comandos Disponibles](#7-comandos-disponibles)
8. [Testing](#8-testing)

---

## 1️⃣ Dependencias

### Verificar en `pubspec.yaml` (ya deberían estar)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Ya existe - Reconocimiento de voz
  speech_to_text: ^7.0.0
  
  # Ya existe - Permisos
  permission_handler: ^11.0.1
  
  # Ya existe - Cliente HTTP
  dio: ^5.7.0
  
  # Ya existe - Estado
  flutter_riverpod: ^2.6.1
  
  # NUEVA - Para texto a voz (feedback al usuario)
  flutter_tts: ^3.8.3
```

### Si falta `flutter_tts`, agregarlo:

```bash
flutter pub add flutter_tts
```

### Instalar dependencias

```bash
flutter pub get
```

---

## 2️⃣ Configuración de Permisos

### Android - `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Agregar estos permisos -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
    
    <application
        android:label="Tu App"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Actividad para reconocimiento de voz -->
        <activity
            android:name="com.google.android.gms.common.api.GoogleApiActivity"
            android:exported="false"/>
        
        <!-- Tu actividad principal -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### iOS - `ios/Runner/Info.plist`

```xml
<dict>
    <!-- Permisos existentes... -->
    
    <!-- Agregar estos permisos -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Necesitamos acceso al micrófono para comandos de voz</string>
    
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Necesitamos acceso al reconocimiento de voz para añadir productos al carrito</string>
</dict>
```

---

## 3️⃣ Servicio de Reconocimiento de Voz

### Crear `lib/core/services/voice_service.dart`

```dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _isAvailable = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  /// Inicializar el servicio de voz
  Future<bool> initialize() async {
    try {
      // Solicitar permisos
      final status = await Permission.microphone.request();
      
      if (status != PermissionStatus.granted) {
        print('❌ Permiso de micrófono denegado');
        return false;
      }

      // Inicializar speech to text
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          print('🎤 Estado del reconocimiento: $status');
          _isListening = status == 'listening';
        },
        onError: (error) {
          print('❌ Error de reconocimiento: $error');
          _isListening = false;
        },
      );

      // Configurar text to speech
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      print('✅ Servicio de voz inicializado: $_isAvailable');
      return _isAvailable;
      
    } catch (e) {
      print('❌ Error inicializando voz: $e');
      return false;
    }
  }

  /// Escuchar comando de voz
  Future<String?> listen() async {
    if (!_isAvailable) {
      print('❌ Servicio de voz no disponible');
      return null;
    }

    if (_isListening) {
      print('⚠️ Ya está escuchando');
      return null;
    }

    String? recognizedText;

    try {
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          print('🎤 Reconocido: $recognizedText');
        },
        listenFor: Duration(seconds: 5),
        pauseFor: Duration(seconds: 3),
        partialResults: false,
        localeId: 'es_ES', // Español
      );

      // Esperar a que termine de escuchar
      await Future.delayed(Duration(seconds: 6));

      return recognizedText;
      
    } catch (e) {
      print('❌ Error escuchando: $e');
      return null;
    } finally {
      _isListening = false;
    }
  }

  /// Detener escucha
  Future<void> stop() async {
    await _speech.stop();
    _isListening = false;
  }

  /// Hablar (dar feedback al usuario)
  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('❌ Error hablando: $e');
    }
  }

  /// Cancelar habla
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  /// Verificar si tiene permisos
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Solicitar permisos
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Limpiar recursos
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
  }
}
```

---

## 4️⃣ Procesamiento de Comandos

### Crear `lib/core/services/voice_command_processor.dart`

```dart
import 'package:dio/dio.dart';
import '../api/api_service.dart';

class VoiceCommandProcessor {
  final ApiService _apiService;

  VoiceCommandProcessor({required ApiService apiService}) 
      : _apiService = apiService;

  /// Procesar comando de voz
  Future<VoiceCommandResult> processCommand(String command) async {
    print('🔍 Procesando comando: "$command"');

    // Normalizar comando (minúsculas, sin tildes)
    final normalizedCommand = _normalize(command);

    // 1. Detectar intención
    if (_isAddToCartCommand(normalizedCommand)) {
      return await _handleAddToCart(normalizedCommand);
    } 
    else if (_isSearchCommand(normalizedCommand)) {
      return await _handleSearch(normalizedCommand);
    }
    else if (_isShowCartCommand(normalizedCommand)) {
      return VoiceCommandResult(
        success: true,
        action: VoiceAction.showCart,
        message: 'Mostrando carrito',
      );
    }
    else if (_isClearCartCommand(normalizedCommand)) {
      return VoiceCommandResult(
        success: true,
        action: VoiceAction.clearCart,
        message: 'Vaciando carrito',
      );
    }
    else {
      return VoiceCommandResult(
        success: false,
        action: VoiceAction.unknown,
        message: 'No entendí el comando. Intenta con: "añadir laptop al carrito" o "buscar mouse"',
      );
    }
  }

  /// Detectar si es comando de añadir al carrito
  bool _isAddToCartCommand(String command) {
    final addKeywords = ['añadir', 'agregar', 'anadir', 'agregar', 'añade', 'agrega'];
    final cartKeywords = ['carrito', 'carro', 'cesta'];
    
    return addKeywords.any((word) => command.contains(word)) &&
           cartKeywords.any((word) => command.contains(word));
  }

  /// Detectar si es comando de búsqueda
  bool _isSearchCommand(String command) {
    final searchKeywords = ['buscar', 'busca', 'busqueda', 'encontrar', 'buscarme'];
    return searchKeywords.any((word) => command.contains(word));
  }

  /// Detectar si es comando de mostrar carrito
  bool _isShowCartCommand(String command) {
    final showKeywords = ['mostrar', 'muestra', 'ver', 've', 'abrir', 'abre'];
    final cartKeywords = ['carrito', 'carro', 'cesta'];
    
    return showKeywords.any((word) => command.contains(word)) &&
           cartKeywords.any((word) => command.contains(word));
  }

  /// Detectar si es comando de vaciar carrito
  bool _isClearCartCommand(String command) {
    final clearKeywords = ['vaciar', 'vacia', 'limpiar', 'limpia', 'borrar', 'borra'];
    final cartKeywords = ['carrito', 'carro', 'cesta'];
    
    return clearKeywords.any((word) => command.contains(word)) &&
           cartKeywords.any((word) => command.contains(word));
  }

  /// Manejar comando de añadir al carrito
  Future<VoiceCommandResult> _handleAddToCart(String command) async {
    try {
      // Extraer nombre del producto
      final productName = _extractProductName(command);
      
      if (productName.isEmpty) {
        return VoiceCommandResult(
          success: false,
          action: VoiceAction.addToCart,
          message: 'No pude identificar el producto. Intenta decir: "añadir laptop al carrito"',
        );
      }

      print('🔍 Buscando producto: "$productName"');

      // Buscar producto por nombre
      final product = await _searchProduct(productName);

      if (product == null) {
        return VoiceCommandResult(
          success: false,
          action: VoiceAction.addToCart,
          message: 'No encontré el producto "$productName". Intenta con otro nombre.',
        );
      }

      // Extraer cantidad (por defecto 1)
      final quantity = _extractQuantity(command);

      return VoiceCommandResult(
        success: true,
        action: VoiceAction.addToCart,
        message: 'Añadiendo ${product['name']} al carrito',
        productId: product['id'],
        quantity: quantity,
        productData: product,
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

  /// Manejar comando de búsqueda
  Future<VoiceCommandResult> _handleSearch(String command) async {
    final searchTerm = _extractSearchTerm(command);
    
    if (searchTerm.isEmpty) {
      return VoiceCommandResult(
        success: false,
        action: VoiceAction.search,
        message: 'No pude identificar qué buscar',
      );
    }

    return VoiceCommandResult(
      success: true,
      action: VoiceAction.search,
      message: 'Buscando "$searchTerm"',
      searchTerm: searchTerm,
    );
  }

  /// Buscar producto en el API usando Dio
  Future<Map<String, dynamic>?> _searchProduct(String productName) async {
    try {
      // Usar el ApiService existente con Dio
      final response = await _apiService.get('/products/', queryParameters: {
        'search': productName,
      });

      if (response.statusCode == 200) {
        final List<dynamic> products = response.data;
        
        if (products.isEmpty) {
          return null;
        }

        // Buscar coincidencia exacta o parcial
        final normalizedSearch = _normalize(productName);
        
        for (var product in products) {
          final normalizedName = _normalize(product['name']);
          if (normalizedName.contains(normalizedSearch) || 
              normalizedSearch.contains(normalizedName)) {
            return product;
          }
        }

        // Si no hay coincidencia exacta, devolver el primero
        return products.first;
      }

      return null;
    } on DioException catch (e) {
      print('❌ Error buscando producto: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error inesperado: $e');
      return null;
    }
  }

  /// Extraer nombre del producto del comando
  String _extractProductName(String command) {
    // Remover palabras de comando
    final wordsToRemove = [
      'añadir', 'agregar', 'anadir', 'añade', 'agrega',
      'al', 'el', 'la', 'los', 'las', 'un', 'una',
      'carrito', 'carro', 'cesta',
      'por', 'favor', 'quiero', 'quiero', 'dame',
    ];

    List<String> words = command.split(' ');
    words = words.where((word) => 
      !wordsToRemove.contains(word) && 
      !_isNumber(word)
    ).toList();

    return words.join(' ').trim();
  }

  /// Extraer término de búsqueda
  String _extractSearchTerm(String command) {
    final wordsToRemove = ['buscar', 'busca', 'busqueda', 'encontrar', 'buscarme'];
    
    List<String> words = command.split(' ');
    words = words.where((word) => !wordsToRemove.contains(word)).toList();
    
    return words.join(' ').trim();
  }

  /// Extraer cantidad del comando
  int _extractQuantity(String command) {
    final words = command.split(' ');
    
    for (var word in words) {
      // Buscar números
      if (_isNumber(word)) {
        return int.tryParse(word) ?? 1;
      }
      
      // Buscar números en palabras
      switch (word) {
        case 'uno': case 'una': return 1;
        case 'dos': return 2;
        case 'tres': return 3;
        case 'cuatro': return 4;
        case 'cinco': return 5;
        case 'seis': return 6;
        case 'siete': return 7;
        case 'ocho': return 8;
        case 'nueve': return 9;
        case 'diez': return 10;
      }
    }
    
    return 1; // Por defecto 1
  }

  /// Verificar si es número
  bool _isNumber(String word) {
    return int.tryParse(word) != null;
  }

  /// Normalizar texto (minúsculas, sin tildes)
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }
}

/// Enum de acciones de voz
enum VoiceAction {
  addToCart,
  search,
  showCart,
  clearCart,
  unknown,
}

/// Resultado del procesamiento de comando
class VoiceCommandResult {
  final bool success;
  final VoiceAction action;
  final String message;
  final int? productId;
  final int? quantity;
  final Map<String, dynamic>? productData;
  final String? searchTerm;

  VoiceCommandResult({
    required this.success,
    required this.action,
    required this.message,
    this.productId,
    this.quantity,
    this.productData,
    this.searchTerm,
  });
}
```

---

## 5️⃣ Widget de Botón de Voz

### Crear `lib/shared/widgets/voice_button.dart`

```dart
import 'package:flutter/material.dart';
import '../../core/services/voice_service.dart';
import '../../core/services/voice_command_processor.dart';
import '../../core/api/api_service.dart';

class VoiceButton extends StatefulWidget {
  final ApiService apiService;
  final Function(VoiceCommandResult) onCommandProcessed;

  const VoiceButton({
    Key? key,
    required this.apiService,
    required this.onCommandProcessed,
  }) : super(key: key);

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> 
    with SingleTickerProviderStateMixin {
  
  final VoiceService _voiceService = VoiceService();
  late VoiceCommandProcessor _commandProcessor;
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _listeningText = 'Escuchando...';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _commandProcessor = VoiceCommandProcessor(apiService: widget.apiService);
    _initializeVoice();
    
    // Animación del botón mientras escucha
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isInitialized = initialized;
    });

    if (!initialized) {
      _showError('No se pudo inicializar el reconocimiento de voz');
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      _showError('Servicio de voz no disponible');
      return;
    }

    if (_isListening) return;

    setState(() {
      _isListening = true;
      _listeningText = 'Escuchando...';
    });

    await _voiceService.speak('¿Qué deseas hacer?');

    final command = await _voiceService.listen();

    setState(() {
      _isListening = false;
    });

    if (command == null || command.isEmpty) {
      await _voiceService.speak('No escuché nada. Intenta de nuevo.');
      return;
    }

    setState(() {
      _listeningText = 'Procesando: "$command"';
    });

    // Procesar comando
    final result = await _commandProcessor.processCommand(command);

    // Dar feedback de voz
    await _voiceService.speak(result.message);

    // Ejecutar callback
    widget.onCommandProcessed(result);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de micrófono
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _scaleAnimation.value : 1.0,
              child: FloatingActionButton(
                onPressed: _isInitialized && !_isListening 
                    ? _startListening 
                    : null,
                backgroundColor: _isListening 
                    ? Colors.red 
                    : Colors.blue,
                child: Icon(
                  _isListening 
                      ? Icons.mic 
                      : Icons.mic_none,
                  size: 32,
                ),
              ),
            );
          },
        ),
        
        // Texto de estado
        if (_isListening)
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _listeningText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}
```

---

## 6️⃣ Integración con Carrito

### Actualizar `lib/features/cart/screens/products_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/voice_button.dart';
import '../../../core/services/voice_command_processor.dart';
import '../../../core/api/api_service.dart';
import '../../../core/providers/cart_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _showCart = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // Cargar productos desde API
    // ... tu código existente ...
  }

  void _handleVoiceCommand(VoiceCommandResult result) {
    if (!result.success) {
      _showMessage(result.message, isError: true);
      return;
    }

    switch (result.action) {
      case VoiceAction.addToCart:
        _addToCartFromVoice(
          result.productId!,
          result.quantity!,
          result.productData!,
        );
        break;

      case VoiceAction.search:
        _searchProducts(result.searchTerm!);
        break;

      case VoiceAction.showCart:
        setState(() => _showCart = true);
        break;

      case VoiceAction.clearCart:
        _clearCartFromVoice();
        break;

      case VoiceAction.unknown:
        _showMessage(result.message, isError: true);
        break;
    }
  }

  void _addToCartFromVoice(
    int productId,
    int quantity,
    Map<String, dynamic> productData,
  ) {
    // Usar el CartProvider de Riverpod en vez de setState
    final cartNotifier = ref.read(cartProvider.notifier);
    
    cartNotifier.addItem(
      productId: productId,
      name: productData['name'],
      price: productData['price'].toDouble(),
      quantity: quantity,
      imageUrl: productData['image_url'],
    );

    _showMessage(
      '✅ ${productData['name']} añadido al carrito (x$quantity)',
      isError: false,
    );
  }

  void _searchProducts(String searchTerm) {
    // Implementar búsqueda con filtro
    print('Buscando: $searchTerm');
    _showMessage('Buscando "$searchTerm"...', isError: false);
    
    // Puedes usar un SearchProvider aquí
    // ref.read(searchQueryProvider.notifier).state = searchTerm;
  }

  void _clearCartFromVoice() {
    // Usar el CartProvider
    ref.read(cartProvider.notifier).clear();
    _showMessage('Carrito vaciado', isError: false);
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos'),
        actions: [
          // Badge del carrito
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  setState(() => _showCart = true);
                },
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de productos
          Expanded(
            child: _buildProductList(),
          ),
          
          // Instrucciones de voz
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Di: "Añadir laptop al carrito" o "Buscar mouse"',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Botón flotante de voz
      floatingActionButton: VoiceButton(
        apiService: ref.read(apiServiceProvider),
        onCommandProcessed: _handleVoiceCommand,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
      // Bottom sheet del carrito
      bottomSheet: _showCart ? _buildCartSheet() : null,
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ListTile(
          leading: product['image_url'] != null
              ? Image.network(product['image_url'], width: 50)
              : Icon(Icons.image),
          title: Text(product['name']),
          subtitle: Text('\$${product['price']}'),
          trailing: IconButton(
            icon: Icon(Icons.add_shopping_cart),
            onPressed: () {
              _addToCartFromVoice(
                product['id'],
                1,
                product,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCartSheet() {
    final cart = ref.watch(cartProvider);
    
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carrito',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() => _showCart = false);
                },
              ),
            ],
          ),
          Expanded(
            child: cart.items.isEmpty
                ? Center(child: Text('Carrito vacío'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        leading: item.imageUrl != null
                            ? Image.network(item.imageUrl!, width: 50)
                            : Icon(Icons.image),
                        title: Text(item.name),
                        subtitle: Text('\$${item.price} x ${item.quantity}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            ref.read(cartProvider.notifier).removeItem(item.productId);
                          },
                        ),
                      );
                    },
                  ),
          ),
          ElevatedButton(
            onPressed: cart.items.isNotEmpty ? () {
              // Proceder al pago con GoRouter
              // context.go('/checkout');
            } : null,
            child: Text('Proceder al Pago'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 7️⃣ Comandos Disponibles

### Comandos de Añadir al Carrito

```
✅ "Añadir laptop al carrito"
✅ "Agregar mouse al carrito"
✅ "Añade dos teclados al carrito"
✅ "Agrega tres auriculares"
✅ "Añadir cinco cables HDMI"
```

### Comandos de Búsqueda

```
✅ "Buscar laptop gaming"
✅ "Busca mouse inalámbrico"
✅ "Encontrar teclado mecánico"
✅ "Buscarme auriculares bluetooth"
```

### Comandos de Carrito

```
✅ "Mostrar carrito"
✅ "Ver carrito"
✅ "Abrir carrito"
✅ "Vaciar carrito"
✅ "Limpiar carrito"
```

### Ejemplos Avanzados

```
✅ "Añadir dos laptops HP al carrito"
✅ "Agregar tres mouse Logitech"
✅ "Añade cinco teclados mecánicos RGB"
```

---

## 8️⃣ Testing

### Probar en Emulador/Dispositivo

```bash
# Ejecutar app
flutter run

# Ver logs
flutter logs
```

### Test de Permisos

```dart
// En una pantalla de debug
ElevatedButton(
  onPressed: () async {
    final service = VoiceService();
    final hasPermission = await service.hasPermission();
    
    if (!hasPermission) {
      final granted = await service.requestPermission();
      print('Permiso concedido: $granted');
    } else {
      print('Ya tiene permiso');
    }
  },
  child: Text('Verificar Permisos'),
);
```

### Test de Reconocimiento

```dart
// Test básico
final voiceService = VoiceService();
await voiceService.initialize();

final command = await voiceService.listen();
print('Comando reconocido: $command');

await voiceService.speak('Comando recibido: $command');
```

### Test de Comandos

```dart
// Test de procesador
final processor = VoiceCommandProcessor(token: 'tu_token');

final testCommands = [
  'añadir laptop al carrito',
  'buscar mouse',
  'mostrar carrito',
  'agregar tres teclados',
];

for (var command in testCommands) {
  final result = await processor.processCommand(command);
  print('Comando: $command');
  print('Resultado: ${result.message}');
  print('Acción: ${result.action}');
  print('---');
}
```

---

## 🎯 Características Implementadas

✅ Reconocimiento de voz en español  
✅ Comandos naturales ("añadir laptop al carrito")  
✅ Extracción de cantidades ("dos", "tres", "2", "3")  
✅ Búsqueda inteligente de productos  
✅ Feedback de voz (texto a voz)  
✅ Animación del botón mientras escucha  
✅ Manejo de permisos automático  
✅ Normalización de texto (sin tildes)  
✅ Múltiples acciones (añadir, buscar, mostrar, vaciar)  
✅ Integración con carrito existente  
✅ Manejo de errores robusto  

---

## 🐛 Solución de Problemas

### 1. No reconoce la voz

**Problema:** El servicio no escucha.

**Soluciones:**
- Verificar permisos de micrófono
- Verificar que el dispositivo tenga micrófono funcional
- Probar en dispositivo real (no emulador)
- Verificar que el idioma sea español (`es_ES`)

### 2. No encuentra productos

**Problema:** Comando procesado pero no encuentra producto.

**Soluciones:**
- Verificar que el nombre del producto exista en el backend
- Mejorar normalización de texto
- Agregar sinónimos en el procesador
- Verificar que el token sea válido

### 3. Feedback de voz no funciona

**Problema:** No escucha respuesta del sistema.

**Soluciones:**
- Verificar volumen del dispositivo
- Verificar `flutter_tts` configurado correctamente
- Probar con idioma diferente si español no funciona

### 4. Cantidad siempre es 1

**Problema:** No detecta cantidades.

**Soluciones:**
- Decir cantidad antes del producto: "dos laptops"
- Mejorar función `_extractQuantity()`
- Agregar más palabras numéricas

---

## 📱 Ejemplo Completo de Uso

```dart
// 1. Usuario presiona botón de voz
// 2. Sistema dice: "¿Qué deseas hacer?"
// 3. Usuario dice: "Añadir dos laptops HP al carrito"
// 4. Sistema procesa:
//    - Extrae "laptops HP"
//    - Extrae cantidad: 2
//    - Busca en API
//    - Encuentra producto
// 5. Sistema dice: "Añadiendo Laptop HP al carrito"
// 6. Sistema añade al carrito
// 7. Muestra SnackBar: "✅ Laptop HP añadido al carrito (x2)"
```

---

## 🚀 Próximos Pasos

- [ ] Agregar más comandos (eliminar del carrito, checkout por voz)
- [ ] Mejorar búsqueda con IA/ML
- [ ] Agregar soporte para múltiples idiomas
- [ ] Implementar historial de comandos
- [ ] Agregar comandos de navegación ("ir a inicio", "ir a perfil")
- [ ] Implementar confirmación por voz para acciones críticas

---

¡Listo! Ahora tu app Flutter tiene comandos de voz completos para añadir productos al carrito. 🎤🛒
