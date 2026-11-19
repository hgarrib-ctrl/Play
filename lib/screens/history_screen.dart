import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../controllers/billing_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/bill.dart';
import '../services/currency_service.dart';
import '../widgets/glass_text_field.dart';
import 'receipt_preview_screen.dart';
import 'digital_bill_screen.dart';

class HistoryScreen extends StatefulWidget {
  final HistoryController historyController;
  final BillingController billingController;
  final SettingsController settingsController;
  final VoidCallback onNavigateToBilling;

  const HistoryScreen({
    super.key,
    required this.historyController,
    required this.billingController,
    required this.settingsController,
    required this.onNavigateToBilling,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.historyController.loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(Bill bill) {
    final controller = TextEditingController(text: bill.billName ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Rename Bill',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: GlassTextField(
            controller: controller,
            hintText: 'e.g. Exchange Rahul',
            labelText: 'Bill Name / Reference',
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
              ),
              onPressed: () async {
                final nav = Navigator.of(ctx);
                await widget.historyController.renameBill(bill.id!, controller.text);
                nav.pop();
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Bill bill) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Delete ${bill.billNumber}?',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this historical bill record? This cannot be undone.',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coralRed,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
              ),
              onPressed: () {
                widget.historyController.deleteBill(bill.id!);
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _reuseBill(Bill bill) {
    widget.billingController.loadFromPreviousBill(bill);
    widget.onNavigateToBilling();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Items from ${bill.billNumber} loaded into current bill!'),
        backgroundColor: AppColors.electricBlue,
      ),
    );
  }

  void _viewBillDetails(Bill bill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DigitalBillScreen(
          savedBill: bill,
          settingsController: widget.settingsController,
        ),
      ),
    );
    return;
    // ignore: dead_code
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billNumber,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    if (bill.billName != null)
                      Text(
                        'Ref: ${bill.billName}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.softCyan),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bill.isExchange
                        ? AppColors.amberOrange.withValues(alpha: 0.2)
                        : AppColors.electricBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bill.isExchange ? 'EXCHANGE' : 'REGULAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: bill.isExchange ? AppColors.amberOrange : AppColors.electricBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            const Text('Purchased Items:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: bill.items.length,
                itemBuilder: (context, idx) {
                  final it = bill.items[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${it.productName} (${it.quantity}x @ ${CurrencyService.format(it.unitPrice)})',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        Text(
                          CurrencyService.format(it.itemTotal),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white12),
            if (bill.isExchange && bill.returnedItemValue > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Returned Item Valuation:', style: TextStyle(color: AppColors.amberOrange, fontSize: 13)),
                  Text(CurrencyService.format(bill.returnedItemValue), style: const TextStyle(color: AppColors.amberOrange, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bill.isRefundable ? 'AMOUNT OWED TO CUSTOMER:' : 'TOTAL PAYABLE:',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  CurrencyService.format(bill.finalTotal),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: bill.isRefundable ? AppColors.amberOrange : AppColors.emeraldGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                    ),
                    icon: const Icon(Icons.receipt, color: Colors.white, size: 18),
                    label: const Text('View Receipt / PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiptPreviewScreen(
                            bill: bill,
                            settings: widget.settingsController.settings,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                  ),
                  icon: const Icon(Icons.replay, color: Color(0xFF042F1A), size: 18),
                  label: const Text('Re-Order', style: TextStyle(color: Color(0xFF042F1A), fontWeight: FontWeight.w800)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _reuseBill(bill);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM • hh:mm a');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Bill History', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.historyController.loadHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sales Stats Summary Card
          ListenableBuilder(
            listenable: widget.historyController,
            builder: (context, _) {
              final stats = widget.historyController.stats;
              final todaySales = stats['todaySales'] as double? ?? 0.0;
              final todayBills = stats['todayBills'] as int? ?? 0;
              final todayExchanges = stats['todayExchanges'] as int? ?? 0;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppStyles.borderRadiusMedium,
                  boxShadow: AppStyles.glowShadowBlue,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('TODAY SALES', CurrencyService.format(todaySales, showDecimals: false)),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _statItem('BILLS TODAY', '$todayBills'),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _statItem('EXCHANGES', '$todayExchanges'),
                  ],
                ),
              );
            },
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: GlassTextField(
                    controller: _searchController,
                    hintText: 'Search by bill # or name...',
                    prefixIcon: Icons.search,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              widget.historyController.setSearchQuery('');
                              setState(() {});
                            },
                          )
                        : null,
                    onChanged: (val) {
                      widget.historyController.setSearchQuery(val);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Type (All / Regular / Exchange)
                ListenableBuilder(
                  listenable: widget.historyController,
                  builder: (context, _) {
                    final current = widget.historyController.filterType;
                    return PopupMenuButton<BillType?>(
                      icon: Icon(
                        Icons.filter_list,
                        color: current != null ? AppColors.electricBlue : AppColors.textSecondaryDark,
                      ),
                      onSelected: (type) => widget.historyController.setFilterType(type),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: null, child: Text('All Bills')),
                        PopupMenuItem(value: BillType.regular, child: Text('Regular Bills')),
                        PopupMenuItem(value: BillType.exchange, child: Text('Exchange Bills')),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Bills List
          Expanded(
            child: ListenableBuilder(
              listenable: widget.historyController,
              builder: (context, _) {
                final bills = widget.historyController.bills;

                if (widget.historyController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (bills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 52,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(height: 12),
                        const Text('No bill records found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: bills.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final bill = bills[index];

                    return GestureDetector(
                      onTap: () => _viewBillDetails(bill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                          borderRadius: AppStyles.borderRadiusMedium,
                          border: Border.all(
                            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon indicator
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: bill.isExchange
                                    ? AppColors.amberOrange.withValues(alpha: 0.15)
                                    : AppColors.electricBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                bill.isExchange ? Icons.swap_horiz : Icons.receipt,
                                color: bill.isExchange ? AppColors.amberOrange : AppColors.electricBlue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Bill Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bill.billNumber,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ),
                                      if (bill.isExchange) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.amberOrange.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'EXCH',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.amberOrange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  if (bill.billName != null) ...[
                                    Text(
                                      bill.billName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.softCyan,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    '${dateFormat.format(bill.createdAt)} • ${bill.totalItemCount} items',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Total Amount
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyService.format(bill.finalTotal),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: bill.isRefundable
                                        ? AppColors.amberOrange
                                        : (isDark ? AppColors.emeraldGreen : const Color(0xFF0F9D58)),
                                  ),
                                ),
                                if (bill.isRefundable)
                                  const Text(
                                    'REFUNDABLE',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.amberOrange),
                                  ),
                              ],
                            ),

                            // More Options Menu
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 18,
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (val) {
                                if (val == 'pdf') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReceiptPreviewScreen(
                                        bill: bill,
                                        settings: widget.settingsController.settings,
                                      ),
                                    ),
                                  );
                                } else if (val == 'reorder') {
                                  _reuseBill(bill);
                                } else if (val == 'rename') {
                                  _showRenameDialog(bill);
                                } else if (val == 'delete') {
                                  _confirmDelete(bill);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf, size: 18, color: AppColors.softCyan),
                                      SizedBox(width: 8),
                                      Text('View Receipt'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'reorder',
                                  child: Row(
                                    children: [
                                      Icon(Icons.replay, size: 18, color: AppColors.emeraldGreen),
                                      SizedBox(width: 8),
                                      Text('Re-order as New Bill'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18, color: AppColors.electricBlue),
                                      SizedBox(width: 8),
                                      Text('Rename Bill'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: AppColors.coralRed),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
