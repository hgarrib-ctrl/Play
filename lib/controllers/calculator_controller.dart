import 'package:flutter/foundation.dart';

enum CalculatorMode {
  independent, // Mode A: Pure calculations, does not touch bill
  billAdjustment, // Mode B: Allows applying result to current bill
}

class CalculatorController extends ChangeNotifier {
  CalculatorMode _mode = CalculatorMode.independent;
  String _expression = '';
  String _result = '0';
  bool _hasCalculated = false;

  CalculatorMode get mode => _mode;
  String get expression => _expression.isEmpty ? '0' : _expression;
  String get result => _result;
  double get numericResult => double.tryParse(_result.replaceAll(',', '')) ?? 0.0;

  void setMode(CalculatorMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  void input(String val) {
    if (_hasCalculated && !_isOperator(val)) {
      _expression = '';
      _hasCalculated = false;
    } else {
      _hasCalculated = false;
    }

    if (val == '.') {
      // Prevent multiple decimals in current number token
      final tokens = _expression.split(RegExp(r'[\+\−\×\÷\-\*\/\s]'));
      final lastToken = tokens.isNotEmpty ? tokens.last : '';
      if (lastToken.contains('.')) return;
      if (lastToken.isEmpty) {
        _expression += '0.';
        _updateLiveResult();
        notifyListeners();
        return;
      }
    }

    if (_isOperator(val)) {
      if (_expression.isEmpty) {
        if (val == '−' || val == '-') {
          _expression = '-';
          notifyListeners();
          return;
        }
        return;
      }
      final lastChar = _expression[_expression.length - 1];
      if (_isOperator(lastChar)) {
        _expression = _expression.substring(0, _expression.length - 1) + val;
        notifyListeners();
        return;
      }
    }

    _expression += val;
    _updateLiveResult();
    notifyListeners();
  }

  void backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _hasCalculated = false;
      _updateLiveResult();
      notifyListeners();
    }
  }

  void clear() {
    _expression = '';
    _result = '0';
    _hasCalculated = false;
    notifyListeners();
  }

  void calculate() {
    if (_expression.isEmpty) return;
    try {
      final res = _evaluateExpression(_expression);
      if (res.isInfinite || res.isNaN) {
        _result = 'Error';
      } else {
        _result = _formatResult(res);
        _expression = _result;
        _hasCalculated = true;
      }
    } catch (_) {
      _result = 'Error';
    }
    notifyListeners();
  }

  void _updateLiveResult() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }
    try {
      final res = _evaluateExpression(_expression);
      if (!res.isInfinite && !res.isNaN) {
        _result = _formatResult(res);
      }
    } catch (_) {
      // Keep previous valid result during typing
    }
  }

  bool _isOperator(String c) {
    return c == '+' || c == '−' || c == '-' || c == '×' || c == '*' || c == '÷' || c == '/';
  }

  String _formatResult(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  double _evaluateExpression(String exp) {
    String sanitized = exp
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(' ', '');

    if (sanitized.isEmpty) return 0.0;
    if (_isOperator(sanitized[sanitized.length - 1])) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    if (sanitized.isEmpty) return 0.0;

    // Tokenize
    final List<String> tokens = [];
    String currentNum = '';

    for (int i = 0; i < sanitized.length; i++) {
      final ch = sanitized[i];
      if ('0123456789'.contains(ch) || ch == '.') {
        currentNum += ch;
      } else if (ch == '-' && (i == 0 || _isOperator(sanitized[i - 1]))) {
        currentNum += ch;
      } else if (_isOperator(ch)) {
        if (currentNum.isNotEmpty) {
          tokens.add(currentNum);
          currentNum = '';
        }
        tokens.add(ch);
      }
    }
    if (currentNum.isNotEmpty) tokens.add(currentNum);

    if (tokens.isEmpty) return 0.0;

    // Process * and /
    final List<String> step1 = [];
    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (token == '*' || token == '/') {
        if (step1.isEmpty || i + 1 >= tokens.length) return 0.0;
        final prev = double.tryParse(step1.removeLast()) ?? 0.0;
        final next = double.tryParse(tokens[i + 1]) ?? 1.0;
        if (token == '/' && next == 0) return double.nan;
        final res = token == '*' ? prev * next : prev / next;
        step1.add(res.toString());
        i += 2;
      } else {
        step1.add(token);
        i++;
      }
    }

    // Process + and -
    if (step1.isEmpty) return 0.0;
    double total = double.tryParse(step1[0]) ?? 0.0;
    int j = 1;
    while (j < step1.length) {
      final op = step1[j];
      final val = j + 1 < step1.length ? (double.tryParse(step1[j + 1]) ?? 0.0) : 0.0;
      if (op == '+') {
        total += val;
      } else if (op == '-') {
        total -= val;
      }
      j += 2;
    }

    return total;
  }
}
