import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final Map<String, dynamic> product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Map<String, dynamic> product, {int qty = 1}) {
    final existingIndex = state.indexWhere((item) => item.product['id'] == product['id']);
    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state);
      updatedList[existingIndex].quantity += qty;
      state = updatedList;
    } else {
      state = [...state, CartItem(product: product, quantity: qty)];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product['id'] != productId).toList();
  }

  void decreaseQuantity(String productId) {
    final index = state.indexWhere((item) => item.product['id'] == productId);
    if (index >= 0) {
      final updatedList = List<CartItem>.from(state);
      if (updatedList[index].quantity > 1) {
        updatedList[index].quantity -= 1;
        state = updatedList;
      } else {
        removeFromCart(productId);
      }
    }
  }

  void increaseQuantity(String productId) {
    final index = state.indexWhere((item) => item.product['id'] == productId);
    if (index >= 0) {
      final updatedList = List<CartItem>.from(state);
      updatedList[index].quantity += 1;
      state = updatedList;
    }
  }

  void clearCart() {
    state = [];
  }

  double getCartTotal() {
    double total = 0.0;
    for (var item in state) {
      total += (item.product['price'] as num).toDouble() * item.quantity;
    }
    return total;
  }

  int getCartCount() {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
