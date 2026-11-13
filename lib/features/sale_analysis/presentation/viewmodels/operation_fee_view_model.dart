import 'dart:typed_data';

import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/sale_analysis/data/repositories/operation_fee_repository.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/operation_fee_models.dart';

class OperationFeeViewModel extends BaseViewModel {
  final OperationFeeRepository _repository;

  OperationFeeViewModel({OperationFeeRepository? repository})
      : _repository = repository ?? OperationFeeRepository();

  List<OperationFee> _fees = [];
  List<OperationFee> get fees => _fees;

  String _allocationMethod = 'revenue';
  String get allocationMethod => _allocationMethod;

  bool _saved = false;
  bool get saved => _saved;

  Future<void> load() async {
    await runAsync((token) async {
      final data = await _repository.list();
      final feeList = data['fees'] as List<dynamic>? ?? [];
      _fees = feeList.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      _allocationMethod = settings['allocationMethod'] as String? ?? 'revenue';
    }, errorPrefix: 'Failed to load operation fees');
  }

  Future<OperationFee?> addFee(OperationFee fee) async {
    return runAsync((token) async {
      final data = await _repository.create({
        'name': fee.name,
        'category': fee.category.name,
        'calculation': fee.calculation.name,
        'rate': fee.rate,
        'isActive': fee.isActive,
        'icon': fee.icon.name,
        'tint': fee.tint.name,
      });
      final created = _fromApi(data);
      _fees = [..._fees, created];
      return created;
    }, errorPrefix: 'Failed to add fee');
  }

  Future<void> updateFee(OperationFee fee) async {
    await runAsync((token) async {
      final data = await _repository.update(int.parse(fee.id.split('-').last), {
        'name': fee.name,
        'category': fee.category.name,
        'calculation': fee.calculation.name,
        'rate': fee.rate,
        'isActive': fee.isActive,
        'icon': fee.icon.name,
        'tint': fee.tint.name,
      });
      final updated = _fromApi(data);
      final index = _fees.indexWhere((f) => f.id == fee.id);
      if (index != -1) {
        _fees = [..._fees]..[index] = updated;
      }
    }, errorPrefix: 'Failed to update fee');
  }

  Future<void> deleteFee(String id) async {
    await runAsync((token) async {
      await _repository.delete(int.parse(id.split('-').last));
      _fees = _fees.where((f) => f.id != id).toList();
    }, errorPrefix: 'Failed to delete fee');
  }

  Future<void> saveSettings(String method) async {
    await runAsync((token) async {
      await _repository.updateSettings(method);
      _allocationMethod = method;
    }, errorPrefix: 'Failed to save settings');
  }

  /// Fetches the one-month operation-fee report as CSV bytes.
  Future<Uint8List?> downloadReport({
    required int year,
    required int month,
  }) {
    return runAsync(
      (token) => _repository.downloadReport(year: year, month: month),
      errorPrefix: 'Failed to download operation fee report',
    );
  }

  void setSaved(bool value) {
    _saved = value;
    notifyListeners();
  }

  OperationFee _fromApi(Map<String, dynamic> json) {
    return OperationFee(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: _parseCategory(json['category']?.toString()),
      calculation: _parseCalculation(json['calculation']?.toString()),
      rate: double.tryParse(json['rate']?.toString() ?? '') ?? 0,
      isActive: json['is_active'] == true || json['isActive'] == true,
      icon: _parseIcon(json['icon']?.toString()),
      tint: _parseTint(json['tint']?.toString()),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  FeeCategory _parseCategory(String? v) {
    return FeeCategory.values.firstWhere(
      (e) => e.name == v,
      orElse: () => FeeCategory.other,
    );
  }

  FeeCalculation _parseCalculation(String? v) {
    return FeeCalculation.values.firstWhere(
      (e) => e.name == v,
      orElse: () => FeeCalculation.fixedPerMonth,
    );
  }

  FeeIcon _parseIcon(String? v) {
    return FeeIcon.values.firstWhere(
      (e) => e.name == v,
      orElse: () => FeeIcon.other,
    );
  }

  FeeTint _parseTint(String? v) {
    return FeeTint.values.firstWhere(
      (e) => e.name == v,
      orElse: () => FeeTint.gray,
    );
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
