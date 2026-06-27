class CreditNote {
  final String? id;
  final String noteNumber;
  final String? originalInvoiceId;
  final String? originalInvoiceNumber;
  final DateTime date;
  final String customerName;
  final String? gstin;
  final String supplyType;
  final String? reason;
  final List<CreditNoteItem> items;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double totalTax;
  final double totalAmount;
  final DateTime? createdAt;
  final String? warehouseId;

  CreditNote({
    this.id,
    required this.noteNumber,
    this.originalInvoiceId,
    this.originalInvoiceNumber,
    required this.date,
    required this.customerName,
    this.gstin,
    this.supplyType = 'INTRA_STATE',
    this.reason,
    required this.items,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
    required this.totalTax,
    required this.totalAmount,
    this.createdAt,
    this.warehouseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'note_number': noteNumber,
      'original_invoice_id': originalInvoiceId,
      'original_invoice_number': originalInvoiceNumber,
      'date': date.toIso8601String(),
      'customer_name': customerName,
      'gstin': gstin,
      'supply_type': supplyType,
      'reason': reason,
      'subtotal': subtotal,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'cess': cess,
      'total_tax': totalTax,
      'total_amount': totalAmount,
      'warehouse_id': warehouseId,
    };
  }

  factory CreditNote.fromJson(
    Map<String, dynamic> json,
    List<CreditNoteItem> items,
  ) {
    return CreditNote(
      id: json['id']?.toString(),
      noteNumber: json['note_number'],
      originalInvoiceId: json['original_invoice_id'],
      originalInvoiceNumber: json['original_invoice_number'],
      date: DateTime.parse(json['date']),
      customerName: json['customer_name'],
      gstin: json['gstin'],
      supplyType: json['supply_type'] ?? 'INTRA_STATE',
      reason: json['reason'],
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      cgst: (json['cgst'] as num).toDouble(),
      sgst: (json['sgst'] as num).toDouble(),
      igst: (json['igst'] as num).toDouble(),
      cess: (json['cess'] as num).toDouble(),
      totalTax: (json['total_tax'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      warehouseId: json['warehouse_id']?.toString(),
    );
  }
}

class CreditNoteItem {
  String productName;
  String? hsnSacCode;
  double qty;
  double rate;
  double gstRate;
  double taxableValue;
  double cgstAmount;
  double sgstAmount;
  double igstAmount;
  double cessAmount;

  CreditNoteItem({
    required this.productName,
    this.hsnSacCode,
    required this.qty,
    required this.rate,
    required this.gstRate,
    this.taxableValue = 0.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.cessAmount = 0.0,
  });

  Map<String, dynamic> toJson(String creditNoteId) {
    return {
      'credit_note_id': creditNoteId,
      'product_name': productName,
      'hsn_sac_code': hsnSacCode,
      'qty': qty,
      'rate': rate,
      'gst_rate': gstRate,
      'taxable_value': taxableValue,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'cess_amount': cessAmount,
    };
  }

  factory CreditNoteItem.fromJson(Map<String, dynamic> json) {
    return CreditNoteItem(
      productName: json['product_name'],
      hsnSacCode: json['hsn_sac_code'],
      qty: (json['qty'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      gstRate: (json['gst_rate'] as num).toDouble(),
      taxableValue: (json['taxable_value'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0.0,
      cessAmount: (json['cess_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
