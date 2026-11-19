import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../database/bill_dao.dart';

class HistoryController extends ChangeNotifier {
  final BillDao _billDao = BillDao();

  List<Bill> _bills = [];
  String _searchQuery = '';
  BillType? _filterType;
  bool _isLoading = false;
  Map<String, dynamic> _stats = {
    'todayBills': 0,
    'todaySales': 0.0,
    'todayExchanges': 0,
    'allTimeBills': 0,
    'allTimeSales': 0.0,
  };

  List<Bill> get bills => _bills;
  String get searchQuery => _searchQuery;
  BillType? get filterType => _filterType;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get stats => _stats;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    _bills = await _billDao.getAllBills(
      query: _searchQuery,
      billType: _filterType,
    );
    _stats = await _billDao.getStats();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadHistory();
  }

  void setFilterType(BillType? type) {
    _filterType = type;
    loadHistory();
  }

  Future<bool> renameBill(int billId, String? newName) async {
    final updated = await _billDao.updateBillName(billId, newName);
    if (updated > 0) {
      await loadHistory();
      return true;
    }
    return false;
  }

  Future<bool> deleteBill(int billId) async {
    final deleted = await _billDao.deleteBill(billId);
    if (deleted > 0) {
      await loadHistory();
      return true;
    }
    return false;
  }
}
