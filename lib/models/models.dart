// ─── Data Models ──────────────────────────────────────────────────────────────
// JSON keys match Supabase column names exactly (snake_case for most tables;
// camelCase-quoted for the settings table).

// ─── App Settings ─────────────────────────────────────────────────────────────

class AppSettings {
  String companyName;
  String address;
  String phone;
  String email;
  double brickPriceDefault;
  int carCapacity;
  String currency;
  String currencySymbol;
  int nextInvoiceNum;

  AppSettings({
    this.companyName = 'Panha Brick Factory',
    this.address = 'Phnom Penh, Cambodia',
    this.phone = '',
    this.email = '',
    this.brickPriceDefault = 0.10,
    this.carCapacity = 30000,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.nextInvoiceNum = 1,
  });

  // Settings table uses quoted camelCase columns — match them exactly.
  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'address': address,
        'phone': phone,
        'email': email,
        'brickPriceDefault': brickPriceDefault,
        'carCapacity': carCapacity,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'nextInvoiceNum': nextInvoiceNum,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        companyName: j['companyName'] ?? 'Panha Brick Factory',
        address: j['address'] ?? '',
        phone: j['phone'] ?? '',
        email: j['email'] ?? '',
        brickPriceDefault: ((j['brickPriceDefault']) ?? 0.10).toDouble(),
        carCapacity: j['carCapacity'] ?? 30000,
        currency: j['currency'] ?? 'USD',
        currencySymbol: j['currencySymbol'] ?? '\$',
        nextInvoiceNum: j['nextInvoiceNum'] ?? 1,
      );
}

// ─── Client ────────────────────────────────────────────────────────────────────

class Client {
  final String id;
  String name;
  String address;
  String phone;
  String notes;
  final String createdAt;
  double? latitude;
  double? longitude;
  String? googleMapsUrl;

  Client({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.notes = '',
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'notes': notes,
        'created_at': createdAt,
        'latitude': latitude,
        'longitude': longitude,
        'google_maps_url': googleMapsUrl,
      };

  factory Client.fromJson(Map<String, dynamic> j) => Client(
        id: j['id'],
        name: j['name'],
        address: j['address'] ?? '',
        phone: j['phone'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: j['created_at'] ?? j['createdAt'] ?? '',
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        googleMapsUrl: j['google_maps_url'],
      );
}

// ─── Worker ────────────────────────────────────────────────────────────────────

enum WorkerRole { driver, loader, supervisor, other }

extension WorkerRoleLabel on WorkerRole {
  String get label {
    switch (this) {
      case WorkerRole.driver:     return 'Driver';
      case WorkerRole.loader:     return 'Loader';
      case WorkerRole.supervisor: return 'Supervisor';
      case WorkerRole.other:      return 'Other';
    }
  }
}

class Worker {
  final String id;
  String name;
  WorkerRole role;
  String phone;
  String notes;
  final String createdAt;

  Worker({
    required this.id,
    required this.name,
    this.role = WorkerRole.loader,
    this.phone = '',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'phone': phone,
        'notes': notes,
        'created_at': createdAt,
      };

  factory Worker.fromJson(Map<String, dynamic> j) => Worker(
        id: j['id'],
        name: j['name'],
        role: WorkerRole.values.firstWhere(
          (e) => e.name == j['role'],
          orElse: () => WorkerRole.loader,
        ),
        phone: j['phone'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: j['created_at'] ?? j['createdAt'] ?? '',
      );
}

// ─── Car ───────────────────────────────────────────────────────────────────────

class Car {
  final String id;
  String plateNumber;
  int capacity;
  String description;
  final String createdAt;

  Car({
    required this.id,
    required this.plateNumber,
    this.capacity = 30000,
    this.description = '',
    this.createdAt = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plate_number': plateNumber,
        'capacity': capacity,
        'description': description,
        'created_at': createdAt,
      };

  factory Car.fromJson(Map<String, dynamic> j) => Car(
        id: j['id'],
        plateNumber: j['plate_number'] ?? j['plateNumber'] ?? '',
        capacity: j['capacity'] ?? 30000,
        description: j['description'] ?? '',
        createdAt: j['created_at'] ?? j['createdAt'] ?? '',
      );
}

// ─── Vendor ────────────────────────────────────────────────────────────────────

class Vendor {
  final String id;
  String name;
  String address;
  String phone;
  String notes;
  final String createdAt;
  double? latitude;
  double? longitude;
  String? googleMapsUrl;

  Vendor({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.notes = '',
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'notes': notes,
        'created_at': createdAt,
        'latitude': latitude,
        'longitude': longitude,
        'google_maps_url': googleMapsUrl,
      };

  factory Vendor.fromJson(Map<String, dynamic> j) => Vendor(
        id: j['id'],
        name: j['name'],
        address: j['address'] ?? '',
        phone: j['phone'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: j['created_at'] ?? j['createdAt'] ?? '',
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        googleMapsUrl: j['google_maps_url'],
      );
}

// ─── Brick Type ────────────────────────────────────────────────────────────────

class BrickType {
  final String id;
  String name;
  String description;
  final String createdAt;

  BrickType({
    required this.id,
    required this.name,
    this.description = '',
    this.createdAt = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'created_at': createdAt,
      };

  factory BrickType.fromJson(Map<String, dynamic> j) => BrickType(
        id: j['id'],
        name: j['name'],
        description: j['description'] ?? '',
        createdAt: j['created_at'] ?? '',
      );
}

// ─── Inventory ─────────────────────────────────────────────────────────────────

class Inventory {
  final String id;
  final String brickTypeId;
  int quantity;
  String updatedAt;

  Inventory({
    required this.id,
    required this.brickTypeId,
    this.quantity = 0,
    this.updatedAt = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brick_type_id': brickTypeId,
        'quantity': quantity,
        'updated_at': updatedAt,
      };

  factory Inventory.fromJson(Map<String, dynamic> j) => Inventory(
        id: j['id'],
        brickTypeId: j['brick_type_id'],
        quantity: j['quantity'] ?? 0,
        updatedAt: j['updated_at'] ?? '',
      );
}

// ─── Inventory Log ─────────────────────────────────────────────────────────────

class InventoryLog {
  final String id;
  final String brickTypeId;
  final int change;
  final String source;
  final String? referenceId;
  final String createdAt;

  InventoryLog({
    required this.id,
    required this.brickTypeId,
    required this.change,
    this.source = '',
    this.referenceId,
    this.createdAt = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brick_type_id': brickTypeId,
        'change': change,
        'source': source,
        'reference_id': referenceId,
        'created_at': createdAt,
      };

  factory InventoryLog.fromJson(Map<String, dynamic> j) => InventoryLog(
        id: j['id'],
        brickTypeId: j['brick_type_id'],
        change: j['change'] ?? 0,
        source: j['source'] ?? '',
        referenceId: j['reference_id'],
        createdAt: j['created_at'] ?? '',
      );
}

// ─── Invoice ───────────────────────────────────────────────────────────────────

class InvoiceItem {
  String id;
  String invoiceId;
  String? brickTypeId;
  int quantity;
  double unitPrice;
  double total;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
    this.brickTypeId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  void recalculate() => total = quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoice_id': invoiceId,
        'brick_type_id': brickTypeId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total': total,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        id: j['id'],
        invoiceId: j['invoice_id'] ?? '',
        brickTypeId: j['brick_type_id'],
        quantity: j['quantity'] ?? 0,
        unitPrice: ((j['unit_price'] ?? j['unitPrice']) ?? 0).toDouble(),
        total: ((j['total']) ?? 0).toDouble(),
      );

  InvoiceItem clone() => InvoiceItem(
        id: id,
        invoiceId: invoiceId,
        brickTypeId: brickTypeId,
        quantity: quantity,
        unitPrice: unitPrice,
        total: total,
      );
}

enum InvoiceStatus { draft, confirmed, partiallyDelivered, delivered, cancelled }

extension InvoiceStatusLabel on InvoiceStatus {
  String get name {
    switch (this) {
      case InvoiceStatus.draft:              return 'draft';
      case InvoiceStatus.confirmed:          return 'confirmed';
      case InvoiceStatus.partiallyDelivered: return 'partially_delivered';
      case InvoiceStatus.delivered:          return 'delivered';
      case InvoiceStatus.cancelled:          return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case InvoiceStatus.draft:              return 'Draft';
      case InvoiceStatus.confirmed:          return 'Confirmed';
      case InvoiceStatus.partiallyDelivered: return 'Partial';
      case InvoiceStatus.delivered:          return 'Delivered';
      case InvoiceStatus.cancelled:          return 'Cancelled';
    }
  }

  static InvoiceStatus fromString(String? s) {
    switch (s) {
      case 'confirmed':           return InvoiceStatus.confirmed;
      case 'partially_delivered': return InvoiceStatus.partiallyDelivered;
      case 'delivered':           return InvoiceStatus.delivered;
      case 'cancelled':           return InvoiceStatus.cancelled;
      default:                    return InvoiceStatus.draft;
    }
  }
}

enum PaymentStatus { unpaid, partial, paid }

extension PaymentStatusLabel on PaymentStatus {
  String get name {
    switch (this) {
      case PaymentStatus.unpaid:  return 'unpaid';
      case PaymentStatus.partial: return 'partial';
      case PaymentStatus.paid:    return 'paid';
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:  return 'Unpaid';
      case PaymentStatus.partial: return 'Partial';
      case PaymentStatus.paid:    return 'Paid';
    }
  }

  static PaymentStatus fromString(String? s) {
    switch (s) {
      case 'partial': return PaymentStatus.partial;
      case 'paid':    return PaymentStatus.paid;
      default:        return PaymentStatus.unpaid;
    }
  }
}

class Invoice {
  final String id;
  String number;
  String? clientId;
  String date;
  InvoiceStatus status;
  PaymentStatus paymentStatus;
  double subtotal;
  double tax;
  double total;
  String notes;
  final String createdAt;
  List<InvoiceItem> items; // embedded locally, synced to invoice_items table

  Invoice({
    required this.id,
    required this.number,
    this.clientId,
    required this.date,
    this.status = InvoiceStatus.draft,
    this.paymentStatus = PaymentStatus.unpaid,
    this.subtotal = 0,
    this.tax = 0,
    this.total = 0,
    this.notes = '',
    required this.createdAt,
    List<InvoiceItem>? items,
  }) : items = items ?? [];

  void recalculate() {
    for (final item in items) item.recalculate();
    subtotal = items.fold(0, (s, i) => s + i.total);
    total = subtotal + tax;
  }

  int get totalBricks => items.fold(0, (s, i) => s + i.quantity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'client_id': clientId,
        'date': date,
        'status': status.name,
        'payment_status': paymentStatus.name,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'notes': notes,
        'created_at': createdAt,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Invoice.fromJson(Map<String, dynamic> j) {
    final rawItems = j['invoice_items'] ?? j['items'];
    return Invoice(
      id: j['id'],
      number: j['number'],
      clientId: j['client_id'] ?? j['clientId'],
      date: j['date'] ?? '',
      status: InvoiceStatusLabel.fromString(j['status']),
      paymentStatus: PaymentStatusLabel.fromString(j['payment_status'] ?? j['paymentStatus']),
      subtotal: ((j['subtotal']) ?? 0).toDouble(),
      tax: ((j['tax']) ?? 0).toDouble(),
      total: ((j['total']) ?? 0).toDouble(),
      notes: j['notes'] ?? '',
      createdAt: j['created_at'] ?? j['createdAt'] ?? '',
      items: (rawItems as List<dynamic>? ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Delivery ──────────────────────────────────────────────────────────────────

enum DeliveryStatus { planned, loading, onRoute, delivered, cancelled }

extension DeliveryStatusLabel on DeliveryStatus {
  String get name {
    switch (this) {
      case DeliveryStatus.planned:   return 'planned';
      case DeliveryStatus.loading:   return 'loading';
      case DeliveryStatus.onRoute:   return 'on_route';
      case DeliveryStatus.delivered: return 'delivered';
      case DeliveryStatus.cancelled: return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case DeliveryStatus.planned:   return 'Planned';
      case DeliveryStatus.loading:   return 'Loading';
      case DeliveryStatus.onRoute:   return 'On Route';
      case DeliveryStatus.delivered: return 'Delivered';
      case DeliveryStatus.cancelled: return 'Cancelled';
    }
  }

  static DeliveryStatus fromString(String? s) {
    switch (s) {
      case 'loading':   return DeliveryStatus.loading;
      case 'on_route':  return DeliveryStatus.onRoute;
      case 'delivered': return DeliveryStatus.delivered;
      case 'cancelled': return DeliveryStatus.cancelled;
      default:          return DeliveryStatus.planned;
    }
  }
}

class DeliveryItem {
  final String id;
  String deliveryId;
  String invoiceId;
  int quantity;
  int deliveredQuantity;

  DeliveryItem({
    required this.id,
    required this.deliveryId,
    required this.invoiceId,
    required this.quantity,
    this.deliveredQuantity = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'delivery_id': deliveryId,
        'invoice_id': invoiceId,
        'quantity': quantity,
        'delivered_quantity': deliveredQuantity,
      };

  factory DeliveryItem.fromJson(Map<String, dynamic> j) => DeliveryItem(
        id: j['id'],
        deliveryId: j['delivery_id'] ?? '',
        invoiceId: j['invoice_id'],
        quantity: j['quantity'] ?? 0,
        deliveredQuantity: j['delivered_quantity'] ?? 0,
      );
}

class Delivery {
  final String id;
  String carId;
  String? driverId;
  String? deliveryDate;
  String notes;
  double? latitude;
  double? longitude;
  DeliveryStatus status;
  String? startedAt;
  String? completedAt;
  List<DeliveryItem> items;

  Delivery({
    required this.id,
    required this.carId,
    this.driverId,
    this.deliveryDate,
    this.notes = '',
    this.latitude,
    this.longitude,
    this.status = DeliveryStatus.planned,
    this.startedAt,
    this.completedAt,
    List<DeliveryItem>? items,
  }) : items = items ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'car_id': carId,
        'driver_id': driverId,
        'delivery_date': deliveryDate,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'started_at': startedAt,
        'completed_at': completedAt,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Delivery.fromJson(Map<String, dynamic> j) {
    final rawItems = j['delivery_items'] ?? j['items'];
    return Delivery(
      id: j['id'],
      carId: j['car_id'],
      driverId: j['driver_id'],
      deliveryDate: j['delivery_date'],
      notes: j['notes'] ?? '',
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      status: DeliveryStatusLabel.fromString(j['status']),
      startedAt: j['started_at'],
      completedAt: j['completed_at'],
      items: (rawItems as List<dynamic>? ?? [])
          .map((e) => DeliveryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Delivery Proof ────────────────────────────────────────────────────────────

class DeliveryProof {
  final String id;
  final String deliveryId;
  final String? invoiceId;
  final String imageUrl;
  final String type; // 'freight' | 'invoice'
  final String? uploadedBy;
  final String createdAt;

  DeliveryProof({
    required this.id,
    required this.deliveryId,
    this.invoiceId,
    required this.imageUrl,
    required this.type,
    this.uploadedBy,
    this.createdAt = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'delivery_id': deliveryId,
        'invoice_id': invoiceId,
        'image_url': imageUrl,
        'type': type,
        'uploaded_by': uploadedBy,
        'created_at': createdAt,
      };

  factory DeliveryProof.fromJson(Map<String, dynamic> j) => DeliveryProof(
        id: j['id'],
        deliveryId: j['delivery_id'],
        invoiceId: j['invoice_id'],
        imageUrl: j['image_url'],
        type: j['type'] ?? 'freight',
        uploadedBy: j['uploaded_by'],
        createdAt: j['created_at'] ?? '',
      );
}

// ─── Borrow Transaction ────────────────────────────────────────────────────────

enum BorrowType { borrowIn, borrowOut, lendOut, lendReturn }

extension BorrowTypeLabel on BorrowType {
  String get name {
    switch (this) {
      case BorrowType.borrowIn:   return 'borrow_in';
      case BorrowType.borrowOut:  return 'borrow_out';
      case BorrowType.lendOut:    return 'lend_out';
      case BorrowType.lendReturn: return 'lend_return';
    }
  }

  String get label {
    switch (this) {
      case BorrowType.borrowIn:   return 'We Borrowed';
      case BorrowType.borrowOut:  return 'We Returned';
      case BorrowType.lendOut:    return 'We Lent';
      case BorrowType.lendReturn: return 'They Returned';
    }
  }

  static BorrowType fromString(String? s) {
    switch (s) {
      case 'borrow_out':  return BorrowType.borrowOut;
      case 'lend_out':    return BorrowType.lendOut;
      case 'lend_return': return BorrowType.lendReturn;
      default:            return BorrowType.borrowIn;
    }
  }
}

class BorrowTransaction {
  final String id;
  String vendorId;
  String? brickTypeId;
  int quantity;
  double unitPrice;
  double total;
  BorrowType type;
  String? relatedInvoiceId;
  final String createdAt;

  BorrowTransaction({
    required this.id,
    required this.vendorId,
    this.brickTypeId,
    required this.quantity,
    this.unitPrice = 0,
    this.total = 0,
    this.type = BorrowType.borrowIn,
    this.relatedInvoiceId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': vendorId,
        'brick_type_id': brickTypeId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total': total,
        'type': type.name,
        'related_invoice_id': relatedInvoiceId,
        'created_at': createdAt,
      };

  factory BorrowTransaction.fromJson(Map<String, dynamic> j) => BorrowTransaction(
        id: j['id'],
        vendorId: j['vendor_id'] ?? j['vendorId'] ?? '',
        brickTypeId: j['brick_type_id'] ?? j['brickTypeId'],
        quantity: j['quantity'] ?? 0,
        unitPrice: ((j['unit_price'] ?? j['unitPrice']) ?? 0).toDouble(),
        total: ((j['total']) ?? 0).toDouble(),
        type: BorrowTypeLabel.fromString(j['type']),
        relatedInvoiceId: j['related_invoice_id'] ?? j['relatedInvoiceId'],
        createdAt: j['created_at'] ?? j['createdAt'] ?? '',
      );
}

// ─── Worker Transaction ────────────────────────────────────────────────────────

enum WorkerTransactionType { salary, borrow, repayment }

extension WorkerTransactionTypeLabel on WorkerTransactionType {
  String get name {
    switch (this) {
      case WorkerTransactionType.salary:    return 'salary';
      case WorkerTransactionType.borrow:    return 'borrow';
      case WorkerTransactionType.repayment: return 'repayment';
    }
  }

  String get label {
    switch (this) {
      case WorkerTransactionType.salary:    return 'Salary';
      case WorkerTransactionType.borrow:    return 'Borrow';
      case WorkerTransactionType.repayment: return 'Repayment';
    }
  }

  static WorkerTransactionType fromString(String? s) {
    switch (s) {
      case 'borrow':    return WorkerTransactionType.borrow;
      case 'repayment': return WorkerTransactionType.repayment;
      default:          return WorkerTransactionType.salary;
    }
  }
}

class WorkerTransaction {
  final String id;
  final String workerId;
  WorkerTransactionType type;
  double amount;
  String notes;
  final String createdAt;

  WorkerTransaction({
    required this.id,
    required this.workerId,
    required this.type,
    required this.amount,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'type': type.name,
        'amount': amount,
        'notes': notes,
        'created_at': createdAt,
      };

  factory WorkerTransaction.fromJson(Map<String, dynamic> j) => WorkerTransaction(
        id: j['id'],
        workerId: j['worker_id'] ?? j['workerId'] ?? '',
        type: WorkerTransactionTypeLabel.fromString(j['type']),
        amount: ((j['amount']) ?? 0).toDouble(),
        notes: j['notes'] ?? '',
        createdAt: j['created_at'] ?? j['createdAt'] ?? '',
      );
}
