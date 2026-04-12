// ─── Data Models ──────────────────────────────────────────────────────────────
// All JSON-serializable models for the brick factory invoice app.

class AppSettings {
  String companyName;
  String companyNameKh;
  String address;
  String addressKh;
  String phone;
  String email;
  double brickPriceDefault;
  int carCapacity;
  String currency;
  String currencySymbol;
  int nextInvoiceNum;

  AppSettings({
    this.companyName = 'Panha Brick Factory',
    this.companyNameKh = 'រោងចក្រឥដ្ឋផ្នហា',
    this.address = 'Phnom Penh, Cambodia',
    this.addressKh = 'ភ្នំពេញ, កម្ពុជា',
    this.phone = '',
    this.email = '',
    this.brickPriceDefault = 0.10,
    this.carCapacity = 30000,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.nextInvoiceNum = 1,
  });

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'companyNameKh': companyNameKh,
        'address': address,
        'addressKh': addressKh,
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
        companyNameKh: j['companyNameKh'] ?? 'រោងចក្រឥដ្ឋផ្នហា',
        address: j['address'] ?? '',
        addressKh: j['addressKh'] ?? '',
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
  String nameKh;
  String address;
  String addressKh;
  String phone;
  String notes;
  final String createdAt;

  Client({
    required this.id,
    required this.name,
    this.nameKh = '',
    this.address = '',
    this.addressKh = '',
    this.phone = '',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameKh': nameKh,
        'address': address,
        'addressKh': addressKh,
        'phone': phone,
        'notes': notes,
        'createdAt': createdAt,
      };

  factory Client.fromJson(Map<String, dynamic> j) => Client(
        id: j['id'],
        name: j['name'],
        nameKh: j['nameKh'] ?? '',
        address: j['address'] ?? '',
        addressKh: j['addressKh'] ?? '',
        phone: j['phone'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: j['createdAt'],
      );

  Client copyWith({
    String? name,
    String? nameKh,
    String? address,
    String? addressKh,
    String? phone,
    String? notes,
  }) =>
      Client(
        id: id,
        name: name ?? this.name,
        nameKh: nameKh ?? this.nameKh,
        address: address ?? this.address,
        addressKh: addressKh ?? this.addressKh,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}

// ─── Worker ────────────────────────────────────────────────────────────────────

enum WorkerRole { driver, loader, supervisor, other }

extension WorkerRoleLabel on WorkerRole {
  String get label {
    switch (this) {
      case WorkerRole.driver:
        return 'Driver';
      case WorkerRole.loader:
        return 'Loader';
      case WorkerRole.supervisor:
        return 'Supervisor';
      case WorkerRole.other:
        return 'Other';
    }
  }

  String get labelKh {
    switch (this) {
      case WorkerRole.driver:
        return 'អ្នកបើកបរ';
      case WorkerRole.loader:
        return 'អ្នកដំណើរ';
      case WorkerRole.supervisor:
        return 'អ្នកត្រួតពិនិត្យ';
      case WorkerRole.other:
        return 'ផ្សេងទៀត';
    }
  }
}

class Worker {
  final String id;
  String name;
  String nameKh;
  String phone;
  WorkerRole role;
  String idCard;
  String notes;
  final String createdAt;

  Worker({
    required this.id,
    required this.name,
    this.nameKh = '',
    this.phone = '',
    this.role = WorkerRole.loader,
    this.idCard = '',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameKh': nameKh,
        'phone': phone,
        'role': role.name,
        'idCard': idCard,
        'notes': notes,
        'createdAt': createdAt,
      };

  factory Worker.fromJson(Map<String, dynamic> j) => Worker(
        id: j['id'],
        name: j['name'],
        nameKh: j['nameKh'] ?? '',
        phone: j['phone'] ?? '',
        role: WorkerRole.values.firstWhere(
          (e) => e.name == j['role'],
          orElse: () => WorkerRole.loader,
        ),
        idCard: j['idCard'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: j['createdAt'],
      );
}

// ─── Car ───────────────────────────────────────────────────────────────────────

class Car {
  final String id;
  String plateNumber;
  int capacity;
  String description;
  String notes;

  Car({
    required this.id,
    required this.plateNumber,
    this.capacity = 30000,
    this.description = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plateNumber': plateNumber,
        'capacity': capacity,
        'description': description,
        'notes': notes,
      };

  factory Car.fromJson(Map<String, dynamic> j) => Car(
        id: j['id'],
        plateNumber: j['plateNumber'],
        capacity: j['capacity'] ?? 30000,
        description: j['description'] ?? '',
        notes: j['notes'] ?? '',
      );
}

// ─── Vendor (Neighbor Vendor) ──────────────────────────────────────────────────

class Vendor {
  final String id;
  String name;
  String nameKh;
  String address;
  String phone;
  String notes;
  final String createdAt;

  Vendor({
    required this.id,
    required this.name,
    this.nameKh = '',
    this.address = '',
    this.phone = '',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameKh': nameKh,
        'address': address,
        'phone': phone,
        'notes': notes,
        'createdAt': createdAt,
      };

  factory Vendor.fromJson(Map<String, dynamic> j) => Vendor(
        id: j['id'],
        name: j['name'],
        nameKh: j['nameKh'] ?? '',
        address: j['address'] ?? '',
        phone: j['phone'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: j['createdAt'],
      );
}

// ─── Borrow (Borrowed bricks from neighbor vendor) ────────────────────────────

enum BorrowStatus { owed, paid }

class Borrow {
  final String id;
  String vendorId;
  String? invoiceId;
  String date;
  int quantity;
  double unitPrice;
  double totalAmount;
  BorrowStatus status;
  String? paymentDate;
  String notes;
  final String createdAt;

  Borrow({
    required this.id,
    required this.vendorId,
    this.invoiceId,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.status = BorrowStatus.owed,
    this.paymentDate,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendorId': vendorId,
        'invoiceId': invoiceId,
        'date': date,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': totalAmount,
        'status': status.name,
        'paymentDate': paymentDate,
        'notes': notes,
        'createdAt': createdAt,
      };

  factory Borrow.fromJson(Map<String, dynamic> j) => Borrow(
        id: j['id'],
        vendorId: j['vendorId'],
        invoiceId: j['invoiceId'],
        date: j['date'],
        quantity: j['quantity'],
        unitPrice: ((j['unitPrice']) ?? 0).toDouble(),
        totalAmount: ((j['totalAmount']) ?? 0).toDouble(),
        status: BorrowStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => BorrowStatus.owed,
        ),
        paymentDate: j['paymentDate'],
        notes: j['notes'] ?? '',
        createdAt: j['createdAt'],
      );
}

// ─── Invoice ───────────────────────────────────────────────────────────────────

class InvoiceItem {
  String description;
  String descriptionKh;
  double quantity;
  String unit;
  double unitPrice;
  double total;

  InvoiceItem({
    required this.description,
    this.descriptionKh = '',
    required this.quantity,
    this.unit = 'pcs',
    required this.unitPrice,
    required this.total,
  });

  void recalculate() {
    total = quantity * unitPrice;
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'descriptionKh': descriptionKh,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'total': total,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        description: j['description'],
        descriptionKh: j['descriptionKh'] ?? '',
        quantity: ((j['quantity']) ?? 0).toDouble(),
        unit: j['unit'] ?? 'pcs',
        unitPrice: ((j['unitPrice']) ?? 0).toDouble(),
        total: ((j['total']) ?? 0).toDouble(),
      );

  InvoiceItem clone() => InvoiceItem(
        description: description,
        descriptionKh: descriptionKh,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        total: total,
      );
}

enum InvoiceStatus { draft, pending, paid }

extension InvoiceStatusLabel on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.paid:
        return 'Paid';
    }
  }

  String get labelKh {
    switch (this) {
      case InvoiceStatus.draft:
        return 'ព្រាង';
      case InvoiceStatus.pending:
        return 'រង់ចាំ';
      case InvoiceStatus.paid:
        return 'បានបង់';
    }
  }
}

class Invoice {
  final String id;
  String number;
  String date;
  String? clientId;
  String? carId;
  List<String> workerIds;
  List<InvoiceItem> items;
  double subtotal;
  double total;
  String? borrowId;
  String notes;
  InvoiceStatus status;
  final String createdAt;
  String? updatedAt;

  Invoice({
    required this.id,
    required this.number,
    required this.date,
    this.clientId,
    this.carId,
    List<String>? workerIds,
    List<InvoiceItem>? items,
    this.subtotal = 0,
    this.total = 0,
    this.borrowId,
    this.notes = '',
    this.status = InvoiceStatus.draft,
    required this.createdAt,
    this.updatedAt,
  })  : workerIds = workerIds ?? [],
        items = items ?? [];

  void recalculate() {
    for (final item in items) {
      item.recalculate();
    }
    subtotal = items.fold(0, (sum, item) => sum + item.total);
    total = subtotal;
  }

  int get totalBricks =>
      items.fold(0, (sum, item) => sum + item.quantity.toInt());

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'date': date,
        'clientId': clientId,
        'carId': carId,
        'workerIds': workerIds,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'total': total,
        'borrowId': borrowId,
        'notes': notes,
        'status': status.name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id'],
        number: j['number'],
        date: j['date'],
        clientId: j['clientId'],
        carId: j['carId'],
        workerIds: List<String>.from(j['workerIds'] ?? []),
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: ((j['subtotal']) ?? 0).toDouble(),
        total: ((j['total']) ?? 0).toDouble(),
        borrowId: j['borrowId'],
        notes: j['notes'] ?? '',
        status: InvoiceStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => InvoiceStatus.draft,
        ),
        createdAt: j['createdAt'],
        updatedAt: j['updatedAt'],
      );
}
