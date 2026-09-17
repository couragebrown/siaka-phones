import 'package:flutter/foundation.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/models/order.dart';

class OrdersViewModel extends ChangeNotifier {
  final OrderRepository _orderRepository;

  OrdersViewModel({required OrderRepository orderRepository})
      : _orderRepository = orderRepository {
    _orderRepository.addListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    _orderRepository.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    notifyListeners();
  }

  List<OrderModel> get orders => _orderRepository.orders;

  OrderModel? getOrderById(String orderId) => _orderRepository.getOrderById(orderId);

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    _orderRepository.updateOrderStatus(orderId, newStatus);
  }

  void advanceOrderStatus(String orderId) {
    _orderRepository.advanceOrderStatus(orderId);
  }
}
