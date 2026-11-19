import 'bill_item.dart';

enum BillType {
  regular,
  exchange,
}

class Bill {
  final int? id;
  final String billNumber;
  final String? billName; // Optional e.g. "Rahul", "Customer 01"
  final String? customerPhone; // Optional e.g. "9876543210"
  final BillType billType;
  final double subtotal;
  final double discountAmount;
  final double additionalCharge;
  final double returnedItemValue; // Valuation of returned product in Exchange mode
  final String? returnedItemNotes;
  final double finalTotal; // Absolute net amount
  final bool isRefundable; // true if shop owes customer, false if customer pays
  final String paymentMethod;
  final DateTime createdAt;
  final List<BillItem> items;

  Bill({
    this.id,
    required this.billNumber,
    this.billName,
    this.customerPhone,
    this.billType = BillType.regular,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.additionalCharge = 0.0,
    this.returnedItemValue = 0.0,
    this.returnedItemNotes,
    required this.finalTotal,
    this.isRefundable = false,
    this.paymentMethod = 'CASH',
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExchange => billType == BillType.exchange;
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Bill copyWith({
    int? id,
    String? billNumber,
    String? billName,
    String? customerPhone,
    BillType? billType,
    double? subtotal,
    double? discountAmount,
    double? additionalCharge,
    double? returnedItemValue,
    String? returnedItemNotes,
    double? finalTotal,
    bool? isRefundable,
    String? paymentMethod,
    DateTime? createdAt,
    List<BillItem>? items,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      billName: billName ?? this.billName,
      customerPhone: customerPhone ?? this.customerPhone,
      billType: billType ?? this.billType,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      additionalCharge: additionalCharge ?? this.additionalCharge,
      returnedItemValue: returnedItemValue ?? this.returnedItemValue,
      returnedItemNotes: returnedItemNotes ?? this.returnedItemNotes,
      finalTotal: finalTotal ?? this.finalTotal,
      isRefundable: isRefundable ?? this.isRefundable,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bill_number': billNumber,
      'bill_name': billName,
      'customer_phone': customerPhone,
      'bill_type': billType == BillType.exchange ? 'EXCHANGE' : 'REGULAR',
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'additional_charge': additionalCharge,
      'returned_item_value': returnedItemValue,
      'returned_item_notes': returnedItemNotes,
      'final_total': finalTotal,
      'is_refundable': isRefundable ? 1 : 0,
      'payment_method': paymentMethod,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map, {List<BillItem> items = const []}) {
    return Bill(
      id: map['id'] as int?,
      billNumber: map['bill_number'] as String? ?? '',
      billName: map['bill_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      billType: (map['bill_type'] as String? ?? 'REGULAR') == 'EXCHANGE'
          ? BillType.exchange
          : BillType.regular,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      additionalCharge: (map['additional_charge'] as num?)?.toDouble() ?? 0.0,
      returnedItemValue: (map['returned_item_value'] as num?)?.toDouble() ?? 0.0,
      returnedItemNotes: map['returned_item_notes'] as String?,
      finalTotal: (map['final_total'] as num?)?.toDouble() ?? 0.0,
      isRefundable: (map['is_refundable'] as int? ?? 0) == 1,
      paymentMethod: map['payment_method'] as String? ?? 'CASH',
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      items: items,
    );
  }
}
