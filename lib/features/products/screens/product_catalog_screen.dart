import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/voice_command_processor.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/product.dart';
import '../../../core/models/category.dart';
import '../../../core/widgets/voice_button.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Provider para la lista de productos
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  // Mantener el provider vivo mientras el widget esté montado
  ref.keepAlive();

  final productService = ProductService();
  return await productService.getProducts();
});

/// Provider para categorías
final categoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) async {
  // Mantener el provider vivo mientras el widget esté montado
  ref.keepAlive();

  final productService = ProductService();
  return await productService.getCategories();
});

/// Pantalla de Catálogo de Productos
/// Equivalente a ProductCatalog.jsx del proyecto React
class ProductCatalogScreen extends ConsumerStatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  ConsumerState<ProductCatalogScreen> createState() =>
      _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends ConsumerState<ProductCatalogScreen> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  late VoiceCommandProcessor _voiceCommandProcessor;

  @override
  void initState() {
    super.initState();
    _voiceCommandProcessor = VoiceCommandProcessor(ApiService());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/auth/login');
    }
  }

  void _handleVoiceCommand(VoiceCommandResult result) {
    if (!result.success) {
      _showMessage(result.message, isError: true);
      return;
    }

    switch (result.action) {
      case VoiceAction.addToCart:
        _addToCartFromVoice(result.product!, result.quantity!);
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

  void _addToCartFromVoice(Product product, int quantity) {
    if (product.isOutOfStock) {
      _showMessage('Producto agotado', isError: true);
      return;
    }

    ref.read(cartProvider.notifier).addItem(product, quantity: quantity);

    _showMessage(
      '✅ ${product.name} añadido al carrito (x$quantity)',
      isError: false,
    );
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Sales'),
        actions: [
          // Ícono del carrito con badge
          const _CartIconButton(),
          const SizedBox(width: 8),

          // Usuario y logout
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                authState.user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            onSelected: (value) {
              if (value == 'my-orders') {
                context.push('/my-orders');
              } else if (value == 'my-returns') {
                context.push('/my-returns');
              } else if (value == 'my-wallet') {
                context.push('/my-wallet');
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.user?.fullName ?? 'Usuario',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      authState.user?.email ?? '',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'my-orders',
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag, size: 20),
                    SizedBox(width: 8),
                    Text('Mis Pedidos'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'my-returns',
                child: Row(
                  children: [
                    Icon(Icons.assignment_return, size: 20),
                    SizedBox(width: 8),
                    Text('Mis Devoluciones'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'my-wallet',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 20),
                    SizedBox(width: 8),
                    Text('Mi Billetera'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMD),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filtro de categorías
          categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingMD,
                ),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Todos'),
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    );
                  }

                  final category = categories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: _selectedCategoryId == category.id,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? category.id : null;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          const Divider(),

          // Banner de instrucciones de voz
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.mic, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Di: "Añadir laptop al carrito" o "Buscar mouse"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: productsAsync.when(
              data: (products) {
                // Filtrar productos
                var filteredProducts = products;

                // Filtrar por categoría
                if (_selectedCategoryId != null) {
                  filteredProducts = filteredProducts
                      .where((p) => p.categoryId == _selectedCategoryId)
                      .toList();
                }

                // Filtrar por búsqueda
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  filteredProducts = filteredProducts
                      .where(
                        (p) =>
                            p.name.toLowerCase().contains(query) ||
                            (p.description?.toLowerCase().contains(query) ??
                                false),
                      )
                      .toList();
                }

                if (filteredProducts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No se encontraron productos',
                    message: 'Intenta ajustar los filtros de búsqueda',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppTheme.paddingMD),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppTheme.paddingMD,
                    mainAxisSpacing: AppTheme.paddingMD,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _ProductCard(product: product);
                  },
                );
              },
              loading: () =>
                  const LoadingIndicator(message: 'Cargando productos...'),
              error: (error, stack) => ErrorDisplay(
                message: error.toString(),
                onRetry: () => ref.refresh(productsProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: VoiceButton(
        commandProcessor: _voiceCommandProcessor,
        onCommandProcessed: _handleVoiceCommand,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Widget de tarjeta de producto
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/products/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.shopping_bag),
                    ),
            ),

            // Información del producto
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingSM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.priceFormatted,
                    style: AppTheme.heading3.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.rating != null) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          product.rating!.toStringAsFixed(1),
                          style: AppTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        product.isLowStock
                            ? '¡Pocas unidades!'
                            : product.isOutOfStock
                            ? 'Agotado'
                            : 'Disponible',
                        style: AppTheme.caption.copyWith(
                          color: product.isOutOfStock
                              ? AppTheme.errorColor
                              : product.isLowStock
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget del ícono del carrito con badge
class _CartIconButton extends ConsumerWidget {
  const _CartIconButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => context.push('/cart'),
        ),
        if (cartItemCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                cartItemCount > 99 ? '99+' : '$cartItemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
