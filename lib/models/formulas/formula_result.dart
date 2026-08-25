class FormulaResult {
  final double value;

  final bool valid;

  final String? error;

  const FormulaResult({required this.value, required this.valid, this.error});

  factory FormulaResult.success(double value) {
    return FormulaResult(value: value, valid: true);
  }

  factory FormulaResult.failure(String message) {
    return FormulaResult(value: 0, valid: false, error: message);
  }

  int get intValue {
    return value.toInt();
  }

  bool get isWholeNumber {
    return value == value.roundToDouble();
  }

  String get displayValue {
    if (isWholeNumber) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }
}
