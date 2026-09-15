import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/canteen_item.dart';
import '../../../domain/entities/tab_order_item.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/repositories/i_canteen_repository.dart';
import '../../../domain/repositories/i_shift_repository.dart';

class CartEntry extends Equatable {
  final CanteenItem item;
  final int quantity;

  const CartEntry({required this.item, required this.quantity});

  double get subtotal => item.unitPrice * quantity;

  CartEntry copyWith({CanteenItem? item, int? quantity}) {
    return CartEntry(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [item, quantity];
}

// Events
abstract class CanteenPosEvent extends Equatable {
  const CanteenPosEvent();
  @override
  List<Object?> get props => [];
}

class LoadCanteenCatalogEvent extends CanteenPosEvent {
  final String branchId;
  const LoadCanteenCatalogEvent(this.branchId);
  @override
  List<Object?> get props => [branchId];
}

class _CanteenItemsUpdatedEvent extends CanteenPosEvent {
  final List<CanteenItem> items;
  const _CanteenItemsUpdatedEvent(this.items);
  @override
  List<Object?> get props => [items];
}

class SelectCanteenCategoryEvent extends CanteenPosEvent {
  final CanteenCategory? category;
  const SelectCanteenCategoryEvent(this.category);
  @override
  List<Object?> get props => [category];
}

class SearchQueryChangedEvent extends CanteenPosEvent {
  final String query;
  const SearchQueryChangedEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class AddItemToCartEvent extends CanteenPosEvent {
  final CanteenItem item;
  const AddItemToCartEvent(this.item);
  @override
  List<Object?> get props => [item];
}

class RemoveItemFromCartEvent extends CanteenPosEvent {
  final String itemId;
  const RemoveItemFromCartEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class UpdateCartQuantityEvent extends CanteenPosEvent {
  final String itemId;
  final int delta;
  const UpdateCartQuantityEvent(this.itemId, this.delta);
  @override
  List<Object?> get props => [itemId, delta];
}

class ClearCartEvent extends CanteenPosEvent {}

class SaveCanteenItemEvent extends CanteenPosEvent {
  final CanteenItem item;
  const SaveCanteenItemEvent(this.item);
  @override
  List<Object?> get props => [item];
}

class SetTargetSessionEvent extends CanteenPosEvent {
  final String? sessionId; // null for counter direct sale
  const SetTargetSessionEvent(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class CheckoutCartEvent extends CanteenPosEvent {
  final String branchId;
  final String operatorId;
  final String operatorName;
  final PaymentMethod paymentMethod; // used if walk-in direct sale
  final String? targetSessionId;

  const CheckoutCartEvent({
    required this.branchId,
    required this.operatorId,
    required this.operatorName,
    required this.paymentMethod,
    this.targetSessionId,
  });

  @override
  List<Object?> get props => [
    branchId,
    operatorId,
    operatorName,
    paymentMethod,
    targetSessionId,
  ];
}

// State
class CanteenPosState extends Equatable {
  final List<CanteenItem> items;
  final List<CartEntry> cart;
  final CanteenCategory? selectedCategory;
  final String searchQuery;
  final String? targetSessionId;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  const CanteenPosState({
    this.items = const [],
    this.cart = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.targetSessionId,
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
  });

  double get cartTotal => cart.fold(0.0, (acc, entry) => acc + entry.subtotal);
  int get cartTotalQuantity =>
      cart.fold(0, (acc, entry) => acc + entry.quantity);

  List<CanteenItem> get filteredItems {
    return items.where((item) {
      if (selectedCategory != null && item.category != selectedCategory) {
        return false;
      }
      if (searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  CanteenPosState copyWith({
    List<CanteenItem>? items,
    List<CartEntry>? cart,
    CanteenCategory? selectedCategory,
    String? searchQuery,
    String? targetSessionId,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
    bool clearCategory = false,
    bool clearTargetSession = false,
  }) {
    return CanteenPosState(
      items: items ?? this.items,
      cart: cart ?? this.cart,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      targetSessionId: clearTargetSession
          ? null
          : (targetSessionId ?? this.targetSessionId),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    items,
    cart,
    selectedCategory,
    searchQuery,
    targetSessionId,
    isSubmitting,
    successMessage,
    errorMessage,
  ];
}

// BLoC
class CanteenPosBloc extends Bloc<CanteenPosEvent, CanteenPosState> {
  final ICanteenRepository _canteenRepo;
  final IShiftRepository _shiftRepo;
  StreamSubscription<List<CanteenItem>>? _canteenSub;
  final _uuid = const Uuid();

  CanteenPosBloc({
    required ICanteenRepository canteenRepo,
    required IShiftRepository shiftRepo,
  }) : _canteenRepo = canteenRepo,
       _shiftRepo = shiftRepo,
       super(const CanteenPosState()) {
    on<LoadCanteenCatalogEvent>(_onLoadCatalog);
    on<_CanteenItemsUpdatedEvent>(_onItemsUpdated);
    on<SelectCanteenCategoryEvent>(_onSelectCategory);
    on<SearchQueryChangedEvent>(_onSearchQueryChanged);
    on<AddItemToCartEvent>(_onAddItemToCart);
    on<RemoveItemFromCartEvent>(_onRemoveItemFromCart);
    on<UpdateCartQuantityEvent>(_onUpdateCartQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<SaveCanteenItemEvent>(_onSaveItem);
    on<SetTargetSessionEvent>(_onSetTargetSession);
    on<CheckoutCartEvent>(_onCheckoutCart);
  }

  Future<void> _onLoadCatalog(
    LoadCanteenCatalogEvent event,
    Emitter<CanteenPosState> emit,
  ) async {
    await _canteenSub?.cancel();
    _canteenSub = _canteenRepo.watchCanteenItems(event.branchId).listen((
      items,
    ) {
      add(_CanteenItemsUpdatedEvent(items));
    });
    final items = await _canteenRepo.getCanteenItems(event.branchId);
    emit(state.copyWith(items: items));
  }

  void _onItemsUpdated(
    _CanteenItemsUpdatedEvent event,
    Emitter<CanteenPosState> emit,
  ) {
    emit(state.copyWith(items: event.items));
  }

  void _onSelectCategory(
    SelectCanteenCategoryEvent event,
    Emitter<CanteenPosState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategory: event.category,
        clearCategory: event.category == null,
      ),
    );
  }

  void _onSearchQueryChanged(
    SearchQueryChangedEvent event,
    Emitter<CanteenPosState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onAddItemToCart(
    AddItemToCartEvent event,
    Emitter<CanteenPosState> emit,
  ) {
    final existingIdx = state.cart.indexWhere(
      (entry) => entry.item.id == event.item.id,
    );
    final updatedCart = List<CartEntry>.from(state.cart);

    if (existingIdx != -1) {
      final current = updatedCart[existingIdx];
      if (current.quantity < event.item.stockQuantity) {
        updatedCart[existingIdx] = current.copyWith(
          quantity: current.quantity + 1,
        );
      }
    } else {
      if (event.item.stockQuantity > 0) {
        updatedCart.add(CartEntry(item: event.item, quantity: 1));
      }
    }

    emit(state.copyWith(cart: updatedCart));
  }

  void _onRemoveItemFromCart(
    RemoveItemFromCartEvent event,
    Emitter<CanteenPosState> emit,
  ) {
    final updatedCart = state.cart
        .where((entry) => entry.item.id != event.itemId)
        .toList();
    emit(state.copyWith(cart: updatedCart));
  }

  void _onUpdateCartQuantity(
    UpdateCartQuantityEvent event,
    Emitter<CanteenPosState> emit,
  ) {
    final idx = state.cart.indexWhere((entry) => entry.item.id == event.itemId);
    if (idx != -1) {
      final current = state.cart[idx];
      final newQty = current.quantity + event.delta;
      final updatedCart = List<CartEntry>.from(state.cart);

      if (newQty <= 0) {
        updatedCart.removeAt(idx);
      } else if (newQty <= current.item.stockQuantity) {
        updatedCart[idx] = current.copyWith(quantity: newQty);
      }
      emit(state.copyWith(cart: updatedCart));
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<CanteenPosState> emit) {
    emit(state.copyWith(cart: []));
  }

  Future<void> _onSaveItem(
    SaveCanteenItemEvent event,
    Emitter<CanteenPosState> emit,
  ) => _canteenRepo.saveItem(event.item);

  void _onSetTargetSession(
    SetTargetSessionEvent event,
    Emitter<CanteenPosState> emit,
  ) {
    emit(
      state.copyWith(
        targetSessionId: event.sessionId,
        clearTargetSession: event.sessionId == null,
      ),
    );
  }

  Future<void> _onCheckoutCart(
    CheckoutCartEvent event,
    Emitter<CanteenPosState> emit,
  ) async {
    if (state.cart.isEmpty) return;

    emit(state.copyWith(isSubmitting: true));

    final now = DateTime.now();
    for (final entry in state.cart) {
      final orderItem = TabOrderItem(
        id: _uuid.v4(),
        sessionId: event.targetSessionId,
        branchId: event.branchId,
        itemId: entry.item.id,
        itemName: entry.item.name,
        quantity: entry.quantity,
        unitPrice: entry.item.unitPrice,
        totalAmount: entry.subtotal,
        timestamp: now,
        operatorId: event.operatorId,
        operatorName: event.operatorName,
      );
      await _canteenRepo.addTabOrderItem(orderItem);
    }

    final isTableTab = event.targetSessionId != null;
    if (!isTableTab) {
      final total = state.cart.fold<double>(
        0,
        (sum, entry) => sum + entry.subtotal,
      );
      await _shiftRepo.recordCashTransaction(
        event.branchId,
        fnbCash: event.paymentMethod == PaymentMethod.cash ? total : 0,
        upi: event.paymentMethod == PaymentMethod.upi ? total : 0,
        card: event.paymentMethod == PaymentMethod.card ? total : 0,
      );
    }
    emit(
      state.copyWith(
        cart: [],
        isSubmitting: false,
        successMessage: isTableTab
            ? 'Items added to Table Tab successfully!'
            : 'Counter POS sale completed!',
      ),
    );
  }

  @override
  Future<void> close() {
    _canteenSub?.cancel();
    return super.close();
  }
}
