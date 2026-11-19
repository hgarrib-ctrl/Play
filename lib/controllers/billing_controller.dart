import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/product.dart';
import '../database/bill_dao.dart';

class BillingSnapshot {
  final List<BillItem> items;
  final double discountAmount;
  final double additionalCharge;
  final bool isExchangeMode;
  final double returnedItemValue;
  final String? returnedItemNotes;

  BillingSnapshot({
    required this.items,
    required this.discountAmount,
    required this.additionalCharge,
    required this.isExchangeMode,
    required this.returnedItemValue,
    this.returnedItemNotes,
  });
}

class BillingController extends ChangeNotifier {
  final BillDao _billDao = BillDao();

  List<BillItem> _items = [];
  double _discountAmount = 0.0;
  double _additionalCharge = 0.0;
  
  // Exchange Mode
  bool _isExchangeMode = false;
  double _returnedItemValue = 0.0;
  String? _returnedItemNotes;

  // Optional Bill Metadata
  String? _billName;
  String? _customerPhone;
  String _paymentMethod = 'CASH';

  // Undo History Stack
  final List<BillingSnapshot> _undoStack = [];

  // Getters
  List<BillItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get uniqueItemCount => _items.length;
  double get discountAmount => _discountAmount;
  double get additionalCharge => _additionalCharge;
  bool get isExchangeMode => _isExchangeMode;
  double get returnedItemValue => _returnedItemValue;
  String? get returnedItemNotes => _returnedItemNotes;
  String? get billName => _billName;
  String? get customerPhone => _customerPhone;
  String get paymentMethod => _paymentMethod;
  bool get canUndo => _undoStack.isNotEmpty;

  // Calculations
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.itemTotal);

  /// Net amount before exchange deduction: Subtotal + Charges - Discounts
  double get grossPayable => (subtotal + _additionalCharge - _discountAmount).clamp(0.0, double.infinity);

  /// Final net amount
  double get finalTotal {
    if (!_isExchangeMode) {
      return grossPayable;
    } else {
      final diff = grossPayable - _returnedItemValue;
      return diff.abs();
    }
  }

  /// True if shop owes money to customer in exchange mode
  bool get isRefundable {
    if (!_isExchangeMode) return false;
    return grossPayable < _returnedItemValue;
  }

  void _saveSnapshot() {
    _undoStack.add(
      BillingSnapshot(
        items: _items.map((i) => i.copyWith()).toList(),
        discountAmount: _discountAmount,
        additionalCharge: _additionalCharge,
        isExchangeMode: _isExchangeMode,
        returnedItemValue: _returnedItemValue,
        returnedItemNotes: _returnedItemNotes,
      ),
    );
    // Keep max 20 undo steps
    if (_undoStack.length > 20) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final last = _undoStack.removeLast();
    _items = last.items;
    _discountAmount = last.discountAmount;
    _additionalCharge = last.additionalCharge;
    _isExchangeMode = last.isExchangeMode;
    _returnedItemValue = last.returnedItemValue;
    _returnedItemNotes = last.returnedItemNotes;
    notifyListeners();
  }

  // Add Product (Fast 1-tap addition)
  void addProduct(Product product) {
    _saveSnapshot();
    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id && !item.hasPriceOverride,
    );

    if (existingIndex >= 0) {
      final current = _items[existingIndex];
      _items[existingIndex] = current.copyWith(quantity: current.quantity + 1);
    } else {
      _items.add(
        BillItem(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          originalPrice: product.price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  // Increment item quantity
  void incrementQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    _saveSnapshot();
    final item = _items[index];
    _items[index] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
  }

  // Decrement item quantity (removes if 1)
  void decrementQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    _saveSnapshot();
    final item = _items[index];
    if (item.quantity > 1) {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  // Remove item completely
  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _saveSnapshot();
    _items.removeAt(index);
    notifyListeners();
  }

  // Override individual item unit price on this bill
  void overrideItemPrice(int index, double newUnitPrice) {
    if (index < 0 || index >= _items.length) return;
    if (newUnitPrice < 0) return;
    _saveSnapshot();
    _items[index] = _items[index].copyWith(unitPrice: newUnitPrice);
    notifyListeners();
  }

  // Adjustments (Discounts & Additional Charges)
  void applyDiscount(double amount) {
    _saveSnapshot();
    _discountAmount = amount.clamp(0.0, subtotal + _additionalCharge);
    notifyListeners();
  }

  void removeDiscount() {
    _saveSnapshot();
    _discountAmount = 0.0;
    notifyListeners();
  }

  void applyAdditionalCharge(double amount) {
    _saveSnapshot();
    _additionalCharge = amount.clamp(0.0, double.infinity);
    notifyListeners();
  }

  void removeAdditionalCharge() {
    _saveSnapshot();
    _additionalCharge = 0.0;
    notifyListeners();
  }

  // Exchange Mode Controls
  void toggleExchangeMode(bool enabled) {
    _saveSnapshot();
    _isExchangeMode = enabled;
    if (!enabled) {
      _returnedItemValue = 0.0;
      _returnedItemNotes = null;
    }
    notifyListeners();
  }

  void setReturnedItemDetails({required double value, String? notes}) {
    _saveSnapshot();
    _returnedItemValue = value.clamp(0.0, double.infinity);
    _returnedItemNotes = notes;
    notifyListeners();
  }

  void setBillName(String? name) {
    _billName = name?.trim().isEmpty == true ? null : name?.trim();
    notifyListeners();
  }

  void setCustomerPhone(String? phone) {
    _customerPhone = phone?.trim().isEmpty == true ? null : phone?.trim();
    notifyListeners();
  }

  void setCustomerDetails({String? name, String? phone}) {
    _billName = name?.trim().isEmpty == true ? null : name?.trim();
    _customerPhone = phone?.trim().isEmpty == true ? null : phone?.trim();
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<String> previewNextBillNumber() async {
    return await _billDao.generateNextBillNumber();
  }

  // Clear current bill
  void clearBill() {
    _saveSnapshot();
    _items.clear();
    _discountAmount = 0.0;
    _additionalCharge = 0.0;
    _isExchangeMode = false;
    _returnedItemValue = 0.0;
    _returnedItemNotes = null;
    _billName = null;
    _customerPhone = null;
    _paymentMethod = 'CASH';
    notifyListeners();
  }

  // Complete and save bill to SQLite
  Future<Bill?> completeBill({String? paymentMethod}) async {
    if (_items.isEmpty && (!_isExchangeMode || _returnedItemValue <= 0)) {
      return null;
    }

    final billNumber = await _billDao.generateNextBillNumber();
    final itemsCopy = List<BillItem>.from(_items);
    final chosenPayment = paymentMethod ?? _paymentMethod;

    final bill = Bill(
      billNumber: billNumber,
      billName: _billName,
      customerPhone: _customerPhone,
      billType: _isExchangeMode ? BillType.exchange : BillType.regular,
      subtotal: subtotal,
      discountAmount: _discountAmount,
      additionalCharge: _additionalCharge,
      returnedItemValue: _returnedItemValue,
      returnedItemNotes: _returnedItemNotes,
      finalTotal: finalTotal,
      isRefundable: isRefundable,
      paymentMethod: chosenPayment,
      items: itemsCopy,
    );

    final billId = await _billDao.saveBill(bill, itemsCopy);
    final savedBill = bill.copyWith(id: billId);

    // Reset bill state for next customer
    clearBill();
    _undoStack.clear();

    return savedBill;
  }

  // Re-use an existing bill from history as current bill
  void loadFromPreviousBill(Bill bill) {
    _saveSnapshot();
    _items = bill.items.map((i) => i.copyWith(id: null, billId: null)).toList();
    _discountAmount = bill.discountAmount;
    _additionalCharge = bill.additionalCharge;
    _isExchangeMode = bill.isExchange;
    _returnedItemValue = bill.returnedItemValue;
    _returnedItemNotes = bill.returnedItemNotes;
    _billName = bill.billName != null ? 'Copy - ${bill.billName}' : null;
    notifyListeners();
  }
}
