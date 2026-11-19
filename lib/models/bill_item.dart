class BillItem {
  final int? id;
  final int? billId;
  final int? productId;
  final String productName;
  final double unitPrice;
  final double originalPrice;
  final int quantity;

  BillItem({
    this.id,
    this.billId,
    this.productId,
    required this.productName,
    required this.unitPrice,
    double? originalPrice,
    this.quantity = 1,
  }) : originalPrice = originalPrice ?? unitPrice;

  double get itemTotal => unitPrice * quantity;
  bool get hasPriceOverride => (unitPrice - originalPrice).abs() > 0.001;

  BillItem copyWith({
    int? id,
    int? billId,
    int? productId,
    String? productName,
    double? unitPrice,
    double? originalPrice,
    int? quantity,
  }) {
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'original_price': originalPrice,
      'quantity': quantity,
      'item_total': itemTotal,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as int?,
      billId: map['bill_id'] as int?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String? ?? '',
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['original_price'] as num?)?.toDouble() ??
          (map['unit_price'] as num?)?.toDouble() ??
          0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
