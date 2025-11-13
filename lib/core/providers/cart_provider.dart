import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movile_2ex/core/models/cart_item.dart';
import 'package:movile_2ex/core/models/product.dart';

/// Estado del carrito
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  CartState({this.items = const [], this.isLoading = false, this.error});

  /// Total de items en el carrito
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total del carrito
  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Impuestos (10% del total)
  double get tax => total * 0.10;

  /// Total con impuestos
  double get totalWithTax => total + tax;

  /// Verifica si el carrito está vacío
  bool get isEmpty => items.isEmpty;

  CartState copyWith({List<CartItem>? items, bool? isLoading, String? error}) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notificador del carrito que maneja la lógica y persistencia
class CartNotifier extends StateNotifier<CartState> {
  static const String _storageKey = 'shopping_cart';

  CartNotifier() : super(CartState()) {
    _loadCart();
  }

  /// Carga el carrito desde SharedPreferences
  Future<void> _loadCart() async {
    try {
      state = state.copyWith(isLoading: true);
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_storageKey);

      if (cartJson != null) {
        final List<dynamic> decoded = json.decode(cartJson);
        final items = decoded.map((item) => CartItem.fromJson(item)).toList();
        state = state.copyWith(items: items, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar el carrito: $e',
      );
    }
  }

  /// Guarda el carrito en SharedPreferences
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(
        state.items.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, cartJson);
    } catch (e) {
      state = state.copyWith(error: 'Error al guardar el carrito: $e');
    }
  }

  /// Añade un producto al carrito
  Future<void> addItem(Product product, {int quantity = 1}) async {
    try {
      final currentItems = List<CartItem>.from(state.items);
      final existingIndex = currentItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex >= 0) {
        // Si el producto ya existe, incrementa la cantidad
        currentItems[existingIndex].quantity += quantity;
      } else {
        // Si no existe, añádelo
        currentItems.add(CartItem(product: product, quantity: quantity));
      }

      state = state.copyWith(items: currentItems, error: null);
      await _saveCart();
    } catch (e) {
      state = state.copyWith(error: 'Error al añadir producto: $e');
    }
  }

  /// Actualiza la cantidad de un producto
  Future<void> updateQuantity(int productId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await removeItem(productId);
        return;
      }

      final currentItems = List<CartItem>.from(state.items);
      final index = currentItems.indexWhere(
        (item) => item.product.id == productId,
      );

      if (index >= 0) {
        currentItems[index].quantity = newQuantity;
        state = state.copyWith(items: currentItems, error: null);
        await _saveCart();
      }
    } catch (e) {
      state = state.copyWith(error: 'Error al actualizar cantidad: $e');
    }
  }

  /// Incrementa la cantidad de un producto
  Future<void> incrementQuantity(int productId) async {
    final itemIndex = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (itemIndex >= 0) {
      await updateQuantity(productId, state.items[itemIndex].quantity + 1);
    }
  }

  /// Decrementa la cantidad de un producto
  Future<void> decrementQuantity(int productId) async {
    final itemIndex = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (itemIndex >= 0) {
      final currentQuantity = state.items[itemIndex].quantity;
      if (currentQuantity > 1) {
        await updateQuantity(productId, currentQuantity - 1);
      } else if (currentQuantity == 1) {
        await removeItem(productId);
      }
    }
  }

  /// Elimina un producto del carrito
  Future<void> removeItem(int productId) async {
    try {
      final currentItems = List<CartItem>.from(state.items);
      currentItems.removeWhere((item) => item.product.id == productId);

      state = state.copyWith(items: currentItems, error: null);
      await _saveCart();
    } catch (e) {
      state = state.copyWith(error: 'Error al eliminar producto: $e');
    }
  }

  /// Limpia todo el carrito
  Future<void> clearCart() async {
    try {
      state = state.copyWith(items: [], error: null);
      await _saveCart();
    } catch (e) {
      state = state.copyWith(error: 'Error al limpiar el carrito: $e');
    }
  }

  /// Verifica si un producto está en el carrito
  bool isInCart(int productId) {
    return state.items.any((item) => item.product.id == productId);
  }

  /// Obtiene la cantidad de un producto en el carrito
  int getQuantity(int productId) {
    final itemIndex = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    return itemIndex >= 0 ? state.items[itemIndex].quantity : 0;
  }
}

/// Provider del carrito
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

/// Provider del contador de items (para el badge)
final cartItemCountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.itemCount;
});

/// Provider del total del carrito
final cartTotalProvider = Provider<double>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.total;
});
