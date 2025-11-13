import '../api/api_service.dart';
import '../models/product.dart';

class VoiceCommandProcessor {
  final ApiService _apiService;

  VoiceCommandProcessor(this._apiService);

  /// Procesar comando de voz
  Future<VoiceCommandResult> processCommand(String command) async {
    print(' Procesando comando: "$command"');

    // Normalizar comando (minúsculas, sin tildes)
    final normalizedCommand = _normalize(command);

    // ✅ Expandir comandos cortos comunes
    final expandedCommand = _expandShortCommands(normalizedCommand);
    print('💡 Comando expandido: "$expandedCommand"');

    // 1. Detectar intención
    if (_isAddToCartCommand(expandedCommand)) {
      return await _handleAddToCart(command); // Enviar comando original
    } else if (_isSearchCommand(expandedCommand)) {
      return await _handleSearch(expandedCommand);
    } else if (_isShowCartCommand(expandedCommand)) {
      return VoiceCommandResult(
        success: true,
        action: VoiceAction.showCart,
        message: 'Mostrando carrito',
      );
    } else if (_isClearCartCommand(expandedCommand)) {
      return VoiceCommandResult(
        success: true,
        action: VoiceAction.clearCart,
        message: 'Vaciando carrito',
      );
    } else {
      return VoiceCommandResult(
        success: false,
        action: VoiceAction.unknown,
        message:
            'No entendí el comando. Intenta con: "añadir laptop al carrito" o "buscar mouse"',
      );
    }
  }

  /// Expandir comandos cortos comunes
  String _expandShortCommands(String command) {
    // ✅ "añade una lap" → "anadir una laptop al carrito"
    if (command.contains('anadi') || command.contains('anadi')) {
      if (!command.contains('carrito')) {
        command = '$command al carrito';
      }
    }

    // ✅ Expandir abreviaciones comunes
    final expansions = {
      'lap': 'laptop',
      'note': 'notebook',
      'compu': 'computadora',
      'celu': 'celular',
      'auri': 'auriculares',
      'tele': 'television',
      'cama': 'camara',
    };

    expansions.forEach((short, full) {
      if (command.contains(short) && !command.contains(full)) {
        command = command.replaceAll(short, full);
      }
    });

    return command;
  }

  /// Detectar si es comando de añadir al carrito
  bool _isAddToCartCommand(String command) {
    final addKeywords = [
      'añadir',
      'agregar',
      'anadir',
      'añade',
      'agrega',
      'pon',
      'dame',
      'quiero', // ✅ Nuevo
      'comprar', // ✅ Nuevo
    ];
    final cartKeywords = ['carrito', 'carro', 'cesta'];

    // ✅ Si contiene palabra de añadir, asumir que es para el carrito
    // (aunque no diga "carrito" explícitamente)
    final hasAddKeyword = addKeywords.any((word) => command.contains(word));
    final hasCartKeyword = cartKeywords.any((word) => command.contains(word));

    // ✅ Si dice "añadir/quiero/dame" + producto, asumir carrito
    return hasAddKeyword || (hasAddKeyword && hasCartKeyword);
  }

  /// Detectar si es comando de búsqueda
  bool _isSearchCommand(String command) {
    final searchKeywords = [
      'buscar',
      'busca',
      'busqueda',
      'encontrar',
      'buscarme',
    ];
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
    final clearKeywords = [
      'vaciar',
      'vacia',
      'limpiar',
      'limpia',
      'borrar',
      'borra',
    ];
    final cartKeywords = ['carrito', 'carro', 'cesta'];

    return clearKeywords.any((word) => command.contains(word)) &&
        cartKeywords.any((word) => command.contains(word));
  }

  /// Manejar comando de añadir al carrito usando NLP del backend
  Future<VoiceCommandResult> _handleAddToCart(String command) async {
    try {
      // ✅ Detectar si el comando está incompleto (solo "añadir al carrito")
      if (_isIncompleteAddCommand(command)) {
        print('⚠️ Comando incompleto detectado: "$command"');
        return await _handleIncompleteCommand(command);
      }

      print('🤖 Enviando comando al backend NLP: "$command"');

      // ✅ Llamar al endpoint NLP del backend con 'prompt' (no 'text')
      final response = await _apiService.post(
        '/api/orders/cart/add-natural-language/',
        data: {'prompt': command},
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
            addedItems: items
                .map((item) => CartItemFromNLP.fromJson(item))
                .toList(),
          );
        } else {
          // No se encontraron productos
          print('⚠️ No se encontraron productos');

          return VoiceCommandResult(
            success: false,
            action: VoiceAction.addToCart,
            message:
                data['message'] ??
                'No encontré productos con ese nombre. Intenta con otro',
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

  /// Detectar si el comando de añadir está incompleto
  bool _isIncompleteAddCommand(String command) {
    final normalized = _normalize(command);

    // Lista de comandos incompletos comunes
    final incompletePatterns = [
      'anadir al carrito',
      'agregar al carrito',
      'pon al carrito',
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
      final hasAddKeyword = [
        'anadir',
        'agregar',
        'pon',
      ].any((k) => normalized.contains(k));
      final hasCartKeyword = [
        'carrito',
        'carro',
        'cesta',
      ].any((k) => normalized.contains(k));

      // Si solo dice "añadir al carrito" sin producto
      if (hasAddKeyword && hasCartKeyword && words.length <= 3) {
        return true;
      }
    }

    return false;
  }

  /// Manejar comando incompleto - sugerir productos populares
  Future<VoiceCommandResult> _handleIncompleteCommand(String command) async {
    try {
      print('🔍 Obteniendo productos populares para sugerencia...');

      // Obtener productos populares del backend
      final response = await _apiService.get(
        '/api/products/',
        queryParameters: {'ordering': '-average_rating', 'page_size': '5'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsData = response.data is List
            ? response.data
            : (response.data['results'] ?? []);

        if (productsData.isNotEmpty) {
          final products = productsData
              .map((json) => Product.fromJson(json))
              .toList();

          print('✅ Encontrados ${products.length} productos populares');

          return VoiceCommandResult(
            success: false,
            action: VoiceAction.needsProduct,
            message:
                '¿Qué producto quieres agregar? Por ejemplo: ${products.first.name}',
            suggestedProducts: products,
          );
        }
      }

      // Fallback si no se pueden obtener productos
      return VoiceCommandResult(
        success: false,
        action: VoiceAction.needsProduct,
        message:
            '¿Qué producto quieres agregar? Por ejemplo: laptop, mouse, teclado',
      );
    } catch (e) {
      print('❌ Error obteniendo productos: $e');
      return VoiceCommandResult(
        success: false,
        action: VoiceAction.needsProduct,
        message: '¿Qué producto quieres agregar? Dime el nombre del producto',
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

  /// Extraer término de búsqueda
  String _extractSearchTerm(String command) {
    final wordsToRemove = [
      'buscar',
      'busca',
      'busqueda',
      'encontrar',
      'buscarme',
    ];

    List<String> words = command.split(' ');
    words = words.where((word) => !wordsToRemove.contains(word)).toList();

    return words.join(' ').trim();
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
  addToCartNLP, // Nuevo: cuando el backend ya añadió al carrito
  confirmProduct, // Nuevo: cuando necesita confirmación del usuario
  needsProduct, // ✅ Nuevo: cuando falta especificar el producto
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
  final Product? product;
  final String? searchTerm;
  final List<CartItemFromNLP>? addedItems; // Nuevo
  final List<Product>? suggestedProducts; // Nuevo

  VoiceCommandResult({
    required this.success,
    required this.action,
    required this.message,
    this.productId,
    this.quantity,
    this.product,
    this.searchTerm,
    this.addedItems,
    this.suggestedProducts,
  });
}

/// Item del carrito retornado por NLP
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
