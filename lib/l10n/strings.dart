// ─── Bilingual Strings (English + Khmer) ──────────────────────────────────────

class S {
  final bool isKh;
  const S(this.isKh);

  String get(String en, String kh) => isKh ? kh : en;

  // ── App ────────────────────────────────────────────────────────────────
  String get appTitle => get('Panha Brick Factory', 'រោងចក្រឥដ្ឋផ្នហា');
  String get dashboard => get('Dashboard', 'ផ្ទាំងគ្រប់គ្រង');
  String get invoices => get('Invoices', 'វិក្កយបត្រ');
  String get clients => get('Clients', 'អតិថិជន');
  String get workers => get('Workers', 'កម្មករ');
  String get cars => get('Cars / Trucks', 'រថយន្ត');
  String get vendors => get('Neighbor Vendors', 'អ្នកលក់ជិតខាង');
  String get borrows => get('Borrowed Bricks', 'ឥដ្ឋខ្ចី');
  String get settings => get('Settings', 'ការកំណត់');

  // ── Actions ────────────────────────────────────────────────────────────
  String get add => get('Add', 'បន្ថែម');
  String get save => get('Save', 'រក្សាទុក');
  String get cancel => get('Cancel', 'បោះបង់');
  String get delete => get('Delete', 'លុប');
  String get edit => get('Edit', 'កែប្រែ');
  String get search => get('Search', 'ស្វែងរក');
  String get export => get('Export PDF', 'នាំចេញ PDF');
  String get print => get('Print', 'បោះពុម្ព');
  String get close => get('Close', 'បិទ');
  String get confirm => get('Confirm', 'បញ្ជាក់');
  String get markPaid => get('Mark as Paid', 'សម្គាល់ថាបានបង់');
  String get newInvoice => get('New Invoice', 'វិក្កយបត្រថ្មី');

  // ── Common Fields ──────────────────────────────────────────────────────
  String get name => get('Name', 'ឈ្មោះ');
  String get nameKh => get('Name (Khmer)', 'ឈ្មោះ (ខ្មែរ)');
  String get address => get('Address', 'អាសយដ្ឋាន');
  String get addressKh => get('Address (Khmer)', 'អាសយដ្ឋាន (ខ្មែរ)');
  String get phone => get('Phone', 'លេខទូរស័ព្ទ');
  String get email => get('Email', 'អ៊ីម៉ែល');
  String get notes => get('Notes', 'កំណត់ចំណាំ');
  String get date => get('Date', 'កាលបរិច្ឆេទ');
  String get status => get('Status', 'ស្ថានភាព');
  String get total => get('Total', 'សរុប');
  String get subtotal => get('Subtotal', 'សរុបរង');
  String get quantity => get('Quantity', 'បរិមាណ');
  String get unit => get('Unit', 'ឯកតា');
  String get unitPrice => get('Unit Price', 'តម្លៃឯកតា');
  String get description => get('Description', 'ការពិពណ៌នា');

  // ── Invoice ────────────────────────────────────────────────────────────
  String get invoiceNumber => get('Invoice #', 'លេខវិក្កយបត្រ');
  String get invoiceDate => get('Invoice Date', 'កាលបរិច្ឆេទ');
  String get deliveryDate => get('Delivery Date', 'កាលបរិច្ឆេទដឹក');
  String get billTo => get('Bill To', 'ជូនដល់');
  String get delivery => get('Delivery Info', 'ព័ត៌មានដឹក');
  String get items => get('Items', 'មុខទំនិញ');
  String get addItem => get('Add Item', 'បន្ថែមមុខទំនិញ');
  String get removeItem => get('Remove', 'យកចេញ');
  String get carLoad => get('Car Load', 'ការផ្ទុករថយន្ត');
  String get bricksDelivered => get('Bricks Delivered', 'ឥដ្ឋដែលបានដឹក');
  String get borrowedBricks => get('Borrowed Bricks', 'ឥដ្ឋខ្ចី');
  String get selectClient => get('Select Client', 'ជ្រើសអតិថិជន');
  String get selectCar => get('Select Car', 'ជ្រើសរថយន្ត');
  String get selectWorkers => get('Select Workers', 'ជ្រើសកម្មករ');
  String get monthlyExport => get('Monthly Export', 'នាំចេញប្រចាំខែ');

  // ── Status Labels ──────────────────────────────────────────────────────
  String get draft => get('Draft', 'ព្រាង');
  String get pending => get('Pending', 'រង់ចាំ');
  String get paid => get('Paid', 'បានបង់');

  // ── Worker ────────────────────────────────────────────────────────────
  String get role => get('Role', 'តួនាទី');
  String get idCard => get('ID Card', 'អត្តសញ្ញាណបណ្ណ');
  String get driver => get('Driver', 'អ្នកបើកបរ');
  String get loader => get('Loader', 'អ្នកដំណើរ');
  String get supervisor => get('Supervisor', 'អ្នកត្រួតពិនិត្យ');
  String get other => get('Other', 'ផ្សេងទៀត');

  // ── Car ────────────────────────────────────────────────────────────────
  String get plateNumber => get('Plate Number', 'លេខស្ទីក');
  String get capacity => get('Capacity (bricks)', 'សមត្ថភាព (ឥដ្ឋ)');

  // ── Borrow ────────────────────────────────────────────────────────────
  String get vendor => get('Vendor', 'អ្នកលក់');
  String get borrowDate => get('Borrow Date', 'កាលបរិច្ឆេទខ្ចី');
  String get amountOwed => get('Amount Owed', 'ចំនួនជំពាក់');
  String get paymentDate => get('Payment Date', 'កាលបរិច្ឆេទបង់');
  String get owed => get('Owed', 'ជំពាក់');
  String get selectVendor => get('Select Vendor', 'ជ្រើសអ្នកលក់');

  // ── Dashboard Stats ───────────────────────────────────────────────────
  String get totalInvoices => get('Total Invoices', 'ចំនួនវិក្កយបត្រ');
  String get totalRevenue => get('Total Revenue', 'ចំណូលសរុប');
  String get pendingAmount => get('Pending', 'ចំនួនរង់ចាំ');
  String get debtToVendors => get('Debt to Vendors', '빚ស់អ្នកលក់');
  String get recentInvoices => get('Recent Invoices', 'វិក្កយបត្រថ្មីៗ');
  String get thisMonth => get('This Month', 'ខែនេះ');
  String get noInvoices => get('No invoices yet', 'មិនទាន់មានវិក្កយបត្រ');
  String get noClients => get('No clients yet', 'មិនទាន់មានអតិថិជន');
  String get noWorkers => get('No workers yet', 'មិនទាន់មានកម្មករ');
  String get noCars => get('No cars yet', 'មិនទាន់មានរថយន្ត');
  String get noVendors => get('No vendors yet', 'មិនទាន់មានអ្នកលក់');
  String get noBorrows => get('No borrowed bricks', 'មិនទាន់មានឥដ្ឋខ្ចី');

  // ── Settings ──────────────────────────────────────────────────────────
  String get companyInfo => get('Company Information', 'ព័ត៌មានក្រុមហ៊ុន');
  String get companyName => get('Company Name', 'ឈ្មោះក្រុមហ៊ុន');
  String get companyNameKh => get('Company Name (Khmer)', 'ឈ្មោះក្រុមហ៊ុន (ខ្មែរ)');
  String get defaultBrickPrice => get('Default Brick Price', 'តម្លៃឥដ្ឋលំនាំដើម');
  String get carCapacity => get('Default Car Capacity', 'សមត្ថភាពរថយន្តលំនាំដើម');
  String get language => get('Language', 'ភាសា');
  String get english => get('English', 'ភាសាអង់គ្លេស');
  String get khmer => get('Khmer', 'ភាសាខ្មែរ');
  String get currency => get('Currency', 'រូបិយប័ណ្ណ');

  // ── Confirmations ─────────────────────────────────────────────────────
  String deleteConfirm(String item) =>
      get('Delete this $item?', 'លុប$item នេះ?');
  String get cannotUndo =>
      get('This action cannot be undone.', 'សកម្មភាពនេះមិនអាចត្រឡប់វិញបាន។');
}
