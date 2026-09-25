import '../models/dice_pool.dart';
import '../models/formulas/formula_context.dart';

class FormulaDiceExtraction {
  final List<DicePool> dicePools;
  final String cleanedExpression;

  FormulaDiceExtraction({
    required this.dicePools,
    required this.cleanedExpression,
  });

  static FormulaDiceExtraction extract(
    String expression, {
    FormulaContext? context,
  }) {
    final dicePools = <DicePool>[];


    final regex = RegExp(
      r'([+-]?)\s*(?:([a-zA-Z_]\w*|\d+)\s*\*\s*)?(\d*)\s*d\s*(\d+)',
      caseSensitive: false,
    );

    for (var match in regex.allMatches(expression)) {
      final multiplierVarOrNum = match.group(2); // Ej: "level" o "2"
      final countStr = match.group(3) ?? '';
      final sidesStr = match.group(4) ?? '6';

      int baseCount = countStr.isEmpty ? 1 : (int.tryParse(countStr) ?? 1);

      if (multiplierVarOrNum != null && multiplierVarOrNum.isNotEmpty) {
        int multiplierVal = int.tryParse(multiplierVarOrNum) ?? 0;
        if (multiplierVal == 0 && context != null) {
          multiplierVal =
              context.get(multiplierVarOrNum.toLowerCase())?.round() ?? 1;
        } else if (multiplierVal == 0) {
          multiplierVal =
              1;
        }
        baseCount *= multiplierVal;
      }

      final sides = int.tryParse(sidesStr) ?? 6;

      if (baseCount > 0 && sides > 0) {
        dicePools.add(DicePool(count: baseCount, sides: sides));
      }
    }

    String cleaned = expression.replaceAllMapped(regex, (match) {
      final sign = match.group(1) ?? '+';
      return sign == '-' ? '- 0' : '+ 0';
    });

    return FormulaDiceExtraction(
      dicePools: dicePools,
      cleanedExpression: cleaned.trim().isEmpty ? '0' : cleaned,
    );
  }
}
