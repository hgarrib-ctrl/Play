# QuickBill — Premium Glassmorphism Mobile Shop Billing Application

> **Built for Rush-Hour Retail Billing** (Dhanteras, Diwali, Festival Sales)  
> Offline-First • Zero Login Friction • High-Precision Calculations • Dual-Mode Calculator • Native Exchange Engine

---

## 🌟 Overview & Core Philosophies

QuickBill is a personal shop billing application built with Flutter and Material 3, wrapped in a **premium midnight glassmorphism design system**. It is designed specifically for single-shop owners and counter staff who need to calculate, adjust, and finish bills in seconds without being slowed down by enterprise POS bloat.

### Priorities:
1. **Billing Speed:** Direct launch to billing (no login, no wizard, 1-tap item addition).
2. **Accurate Calculations:** Real-time formula `(Subtotal + Charges - Discounts) ± Exchange Valuation` with Indian numbering currency formatting (`₹1,25,500.00`).
3. **Built-in Dual-Mode Calculator:** Operable directly on-screen with zero app switching (Mode A: Independent; Mode B: Bill Adjustment).
4. **Exchange Mode:** Dedicated trade-in system calculating net customer payable or store refundable amounts.
5. **Speed-First Skip System:** Every optional step (bill name, customer info, notes) has an instant SKIP option.
6. **100% Offline-First:** Fully persistent SQLite storage, local image caching, JSON backup and restore.

---

## 📁 Project Architecture & Folder Structure

```
quickbill/
├── android/                   # Native Android host configuration (minSdk 21+, permissions)
├── assets/                    # Product imagery and iconography assets
├── build/                     # Compiled outputs (Web & Android)
├── lib/
│   ├── main.dart              # Application bootstrap & theme setup
│   ├── constants/             # Design Tokens & Theming
│   │   ├── app_colors.dart    # Midnight Navy (#080D19), Electric Blue (#638BFF), Soft Cyan, Emerald Green
│   │   ├── app_constants.dart # Defaults & SharedPreferences keys
│   │   └── app_styles.dart    # Radii, blur sigmas, glass shadows, typography
│   ├── controllers/           # Business Logic & State Controllers (ChangeNotifier)
│   │   ├── billing_controller.dart     # Cart state, quantities, price overrides, exchange calculation, undo
│   │   ├── calculator_controller.dart  # Dual-mode arithmetic parser & expression evaluator
│   │   ├── product_controller.dart     # Real-time search, category filters, product CRUD
│   │   ├── history_controller.dart     # Past bills, search, date filtering, sales statistics
│   │   └── settings_controller.dart    # Shop profile, theme mode, screen wake-lock, backup/restore
│   ├── database/              # SQLite Storage Layer
│   │   ├── database_helper.dart        # ACID transactions, schema migration, seed data
│   │   ├── product_dao.dart            # Fast indexed product queries & soft-deletion
│   │   ├── bill_dao.dart               # Bill & bill_items transactions, bill number sequencing
│   │   └── category_dao.dart           # Custom category management
│   ├── models/                # Data Entities
│   │   ├── product.dart       # Product item model
│   │   ├── bill.dart          # Master bill entity (regular & exchange)
│   │   ├── bill_item.dart     # Bill item snapshot with custom price override support
│   │   └── shop_settings.dart # Shop metadata (name, address, phone, GSTIN, receipt notes)
│   ├── services/              # Core Services
│   │   ├── currency_service.dart       # Indian numbering system formatter (Lakh, Crore, ₹)
│   │   ├── receipt_service.dart        # High-res PDF invoice generation, print & share
│   │   ├── backup_service.dart         # Full JSON database backup & restore
│   │   └── image_service.dart          # Local persistent camera & gallery photo storage
│   ├── widgets/               # Reusable Glassmorphism UI Components
│   │   ├── glass_container.dart        # Backdrop blur, translucent gradients, specular border
│   │   ├── glass_button.dart           # Tactile press-scale micro-animations & variants
│   │   ├── glass_text_field.dart       # High-contrast glass inputs
│   │   ├── category_chips.dart         # Horizontal chips with glow indicator
│   │   ├── product_grid_card.dart      # Product visual card with instant count badge
│   │   ├── cart_bottom_sheet.dart      # Sliding current bill panel with instant quantity updates
│   │   ├── calculator_panel.dart       # Glass touch-friendly calculator
│   │   └── exchange_panel.dart         # Exchange valuation & payable/refundable breakdown
│   └── screens/               # Application Views
│       ├── main_navigation_screen.dart # 4-tab bottom navigation (BILL, PRODUCTS, HISTORY, SETTINGS)
│       ├── billing_screen.dart         # Main POS counter
│       ├── products_screen.dart        # Product catalog & photo manager
│       ├── history_screen.dart         # Past transactions & 1-tap re-order
│       ├── receipt_preview_screen.dart # PDF preview, print, share dialog
│       └── settings_screen.dart        # Shop info, appearance, data reset
└── test/
    ├── quickbill_full_test.dart        # 24 comprehensive unit & integration tests
    └── widget_test.dart                # Smoke test verifying UI direct boot to billing
```

---

## 🗄️ Database Structure (SQLite)

### Table: `products`
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `name` (TEXT NOT NULL, Indexed)
- `price` (REAL NOT NULL)
- `category` (TEXT DEFAULT 'Other', Indexed)
- `image_path` (TEXT NULL)
- `is_active` (INTEGER DEFAULT 1, Soft-delete flag)
- `created_at` (INTEGER NOT NULL)
- `updated_at` (INTEGER NOT NULL)

### Table: `bills`
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `bill_number` (TEXT UNIQUE NOT NULL, e.g. `QB-20261106-001`)
- `bill_name` (TEXT NULL, e.g. "Exchange Rahul")
- `bill_type` (TEXT NOT NULL, 'REGULAR' | 'EXCHANGE')
- `subtotal` (REAL NOT NULL)
- `discount_amount` (REAL DEFAULT 0.0)
- `additional_charge` (REAL DEFAULT 0.0)
- `returned_item_value` (REAL DEFAULT 0.0)
- `returned_item_notes` (TEXT NULL)
- `final_total` (REAL NOT NULL)
- `is_refundable` (INTEGER DEFAULT 0)
- `payment_method` (TEXT DEFAULT 'CASH')
- `created_at` (INTEGER NOT NULL, Indexed)

### Table: `bill_items`
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `bill_id` (INTEGER NOT NULL, FOREIGN KEY -> `bills(id)`)
- `product_id` (INTEGER NULL)
- `product_name` (TEXT NOT NULL - snapshot preserved even if product is deleted)
- `unit_price` (REAL NOT NULL - supports on-the-fly override)
- `original_price` (REAL NOT NULL - catalog reference)
- `quantity` (INTEGER NOT NULL)
- `item_total` (REAL NOT NULL - `unit_price * quantity`)

### Table: `categories`
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `name` (TEXT UNIQUE NOT NULL)
- `icon_name` (TEXT NULL)
- `created_at` (INTEGER NOT NULL)

---

## 🧪 Testing Results (100% Pass)

All 20 test scenarios specified in PART 16 have been implemented and verified:

| # | Test Scenario | Status | Result |
|---|---|---|---|
| 1 | Add a product and save it | ✅ PASS | Inserted into SQLite via `ProductDao` |
| 2 | Restart app and verify persistence | ✅ PASS | Product retrieved from SQLite |
| 3 | Add multiple products to a bill | ✅ PASS | Subtotal & item counts calculated accurately |
| 4 | Add the same product repeatedly | ✅ PASS | Quantity increments instantly, single line item |
| 5 | Increase and decrease quantities | ✅ PASS | Item removed when decremented below 1 |
| 6 | Remove products directly | ✅ PASS | Remaining items intact, subtotal updated |
| 7 | Custom price override on bill | ✅ PASS | Overrides bill price without altering product catalog |
| 8 | Apply discount | ✅ PASS | Correctly subtracted from subtotal |
| 9 | Add additional charge | ✅ PASS | Correctly added to subtotal |
| 10 | Independent calculator (Mode A) | ✅ PASS | Evaluates expressions without touching bill |
| 11 | Apply calculator results to bill (Mode B) | ✅ PASS | Result applied as discount/charge |
| 12 | Undo adjustments & actions | ✅ PASS | History snapshot restored cleanly |
| 13 | Create bill without a name (Speed Skip) | ✅ PASS | Saved with `bill_name: null`, zero delay |
| 14 | Create named exchange bill | ✅ PASS | Saved with custom reference e.g. "Exchange Rahul" |
| 15 | Exchange where customer pays extra | ✅ PASS | New: ₹2,000, Return: ₹700 → Pays: ₹1,300 |
| 16 | Exchange where store owes customer | ✅ PASS | New: ₹1,000, Return: ₹1,500 → Owed: ₹500 (Refundable) |
| 17 | Save and reopen bill (Re-order) | ✅ PASS | Historical bill reloaded into active cart |
| 18 | Generate optional PDF receipt | ✅ PASS | Valid PDF document rendered with table & totals |
| 19 | Offline-first architecture verification | ✅ PASS | Operates 100% locally with zero internet dependency |
| 20 | JSON backup & restore | ✅ PASS | Full database exported and restored with verification |

---

## 🚀 Instructions to Run the Application

### Option A: Run on Connected Device / Browser
```powershell
# In PowerShell:
flutter run -d chrome
```

### Option B: Run on Android Phone (via USB / ADB)
1. Connect your Android phone via USB and enable **USB Debugging** in Developer Options.
2. Verify device connection:
   ```powershell
   adb devices
   ```
3. Launch QuickBill:
   ```powershell
   flutter run
   ```

---

## 📦 Instructions to Build and Install the APK

### 1. Build the APK
To produce a standalone Android APK:
```powershell
flutter build apk --release
```
*(Or for a quick debug build: `flutter build apk --debug`)*

The generated APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk` (or `app-debug.apk`)

### 2. Install on Android Phone
Run:
```powershell
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
Or transfer the `.apk` file directly to your phone via WhatsApp, Google Drive, or USB file transfer and tap to install.
